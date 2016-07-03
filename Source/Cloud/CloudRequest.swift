/*
 * Copyright 2016 Coodly LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CloudKit

public struct Cloud {
    public static var container: CKContainer = CKContainer.defaultContainer()
}

public enum CloudResult<T: LocalRecord> {
    case Success([T])
    case Failure
}

public class CloudRequest<T: LocalRecord>: ConcurrentOperation {
    private var records = [T]()
    
    public override init() {
        
    }
    
    public final func cloud(fetch recordName: String, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE")) {
        let query = CKQuery(recordType: recordName, predicate: predicate)
        perform(query)
    }
    
    public final func cloud(fetchFirst recordName: String, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE"), sort: [NSSortDescriptor] = []) {
        Logging.log("Fetch first \(recordName). Predicate: \(predicate)")
        let query = CKQuery(recordType: recordName, predicate: predicate)
        query.sortDescriptors = sort
        perform(query, limit: 1)
    }
    
    private final func perform(query: CKQuery, limit: Int? = nil) {
        Logging.log("Fetch \(query.recordType)")

        let fetchOperation = CKQueryOperation(query: query)
        if let limit = limit {
            fetchOperation.resultsLimit = limit
        }
        
        fetchOperation.recordFetchedBlock = {
            record in
            
            var local = T()
            if local.load(record) {
                self.records.append(local)
            }
        }
        
        fetchOperation.queryCompletionBlock = {
            cursor, error in
            
            if self.cancelled {
                self.finish()
                return
            }
            
            Logging.log("Completion: \(cursor) - \(error)")
            Logging.log("Have \(self.records.count) records")
            
            let finalizer = {
                self.finish()
            }
            
            if let error = error, retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSTimeInterval {
                Logging.log("Error: \(error)")
                Logging.log("Will retry after \(retryAfter) seconds")
                runAfter(retryAfter) {
                    Logging.log("Try again")
                    self.perform(query, limit: limit)
                }
            } else if let error = error {
                Logging.log("Error: \(error)")
                self.handleResult(.Failure, completion: finalizer)
            } else {
                self.handleResult(.Success(self.records), completion: finalizer)
            }
            
            self.finish()
        }
        
        Cloud.container.publicCloudDatabase.addOperation(fetchOperation)
    }
    
    public override func main() {
        Logging.log("Start \(T.self)")
        performRequest()
    }
    
    public func performRequest() {
        Logging.log("Override: \(#function)")
    }
    
    public func handleResult(result: CloudResult<T>, completion: () -> ()) {
        Logging.log("Handle result \(result)")
        completion()
    }
}
