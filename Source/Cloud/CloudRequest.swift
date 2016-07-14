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

public enum UsedDatabase {
    case Public
    case Private
}

public struct Cloud {
    public static var container: CKContainer = CKContainer.defaultContainer()
}

public enum CloudResult<T: FromRemoteRecord> {
    case Success([T], [CKRecordID])
    case Failure
}

public class CloudRequest<T: FromRemoteRecord, O: ToRemoteRecord>: ConcurrentOperation {
    private var records = [T]()
    private var deleted = [CKRecordID]()
    
    public override init() {
        
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
    
    private func database(type: UsedDatabase) -> CKDatabase {
        switch type {
        case .Public:
            return Cloud.container.publicCloudDatabase
        case .Private:
            return Cloud.container.privateCloudDatabase
        }
    }
    
    private func handleResultWithError(error: NSError?, retryClosure: () -> ()) {
        let finalizer = {
            self.finish()
        }
        
        if let error = error, retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSTimeInterval {
            Logging.log("Error: \(error)")
            Logging.log("Will retry after \(retryAfter) seconds")
            runAfter(retryAfter) {
                Logging.log("Try again")
                retryClosure()
            }
        } else if let error = error {
            Logging.log("Error: \(error)")
            self.handleResult(.Failure, completion: finalizer)
        } else {
            self.handleResult(.Success(self.records, self.deleted), completion: finalizer)
        }
    }
}

public extension CloudRequest {
    public final func delete(record record: O, inDatabase db: UsedDatabase = .Private) {
        Logging.log("Delete \(record)")
        let deleted = CKRecordID(recordName: record.recordName!)
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [deleted])
        operation.modifyRecordsCompletionBlock = {
            saved, deleted, error in
            
            Logging.log("Saved: \(saved)")
            Logging.log("Deleted: \(deleted)")
            if let deleted = deleted {
                self.deleted.appendContentsOf(deleted)
            }

            self.handleResultWithError(error) {
                self.delete(record: record, inDatabase: db)
            }
        }
        
        database(db).addOperation(operation)
    }
}

public extension CloudRequest {
    public final func save(record record: O, inDatabase db: UsedDatabase = .Private) {
        let modified: CKRecord
        if let existing = record.recordName {
            modified = CKRecord(recordType: record.recordType, recordID: CKRecordID(recordName: existing))
        } else {
            modified = CKRecord(recordType: record.recordType)
        }
        
        let mirror = Mirror(reflecting: record)
        for child in mirror.children {
            guard let label = child.label where label != "recordName" else {
                continue
            }
            
            if let value = child.value as? NSString {
                modified[label] = value
            } else if let value = child.value as? NSNumber {
                modified[label] = value
            } else if let value = child.value as? NSDate {
                modified[label] = value
            } else if let value = child.value as? CLLocation {
                modified[label] = value
            } else {
                Logging.log("Could not cast \(child) value")
            }
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: [modified], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = {
            saved, deleted, error in
            
            Logging.log("Saved: \(saved)")
            Logging.log("Deleted: \(deleted)")
            
            if let saved = saved {
                for s in saved {
                    var local = T()
                    if local.load(s) {
                        self.records.append(local)
                    }
                }
            }
            
            self.handleResultWithError(error) {
                self.save(record: record, inDatabase: db)
            }
        }
        
        database(db).addOperation(operation)
    }
}

public extension CloudRequest {
    public final func cloud(fetch recordName: String, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE"), inDatabase db: UsedDatabase = .Private) {
        let query = CKQuery(recordType: recordName, predicate: predicate)
        perform(query, inDatabase: db)
    }
    
    public final func cloud(fetchFirst recordName: String, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE"), sort: [NSSortDescriptor] = [], inDatabase db: UsedDatabase = .Private) {
        Logging.log("Fetch first \(recordName). Predicate: \(predicate)")
        let query = CKQuery(recordType: recordName, predicate: predicate)
        query.sortDescriptors = sort
        perform(query, limit: 1, inDatabase: db)
    }
    
    private final func perform(query: CKQuery, limit: Int? = nil, inDatabase db: UsedDatabase) {
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
            
            self.handleResultWithError(error) {
                self.perform(query, limit: limit, inDatabase: db)
            }
        }
        
        database(db).addOperation(fetchOperation)
    }
}