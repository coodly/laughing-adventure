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

public enum CloudResult<T: CloudRecord> {
    case Success([T])
    case Failure
}

public class CloudRequest<T: CloudRecord>: ConcurrentOperation {
    private var records = [T]()
    
    public override init() {
        
    }
    
    public final func cloud(fetch recordName: String, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE")) {
        Logging.log("Fetch \(recordName)")
        
        let query = CKQuery(recordType: recordName, predicate: predicate)
        let fetchOperation = CKQueryOperation(query: query)
        
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
            
            if let error = error {
                self.handleResult(.Failure)
            } else {
                self.handleResult(.Success(self.records))
            }
            
            self.finish()
        }
        
        Cloud.container.publicCloudDatabase.addOperation(fetchOperation)
    }
    
    public final override func start() {
        if cancelled {
            self.finish()
            return
        }
        
        performRequest()
    }
    
    public func performRequest() {
        Logging.log("Override: \(#function)")
    }
    
    public func handleResult(result: CloudResult<T>) {
        Logging.log("Handle result \(result)")
    }
}
