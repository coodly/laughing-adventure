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

public protocol RemoteRecord {
    var recordName: String? { get set }
    var recordData: NSData? { get set }
    var recordType: String { get }

    init()
    
    mutating func load(record: CKRecord) -> Bool
    mutating func loadFields(record: CKRecord) -> Bool
}

public extension RemoteRecord {
    final mutating func load(record: CKRecord) -> Bool {
        recordData = archiveRecord(record)
        recordName = record.recordID.recordName
        return loadFields(record)
    }
    
    private func archiveRecord(record: CKRecord) -> NSMutableData {
        let archivedData = NSMutableData()
        timeMeasured("Record encode") {
            var archiver = NSKeyedArchiver(forWritingWithMutableData: archivedData)
            archiver.requiresSecureCoding = true
            record.encodeSystemFieldsWithCoder(archiver)
            archiver.finishEncoding()
        }
        return archivedData
    }
    
    private func unargchiveRecord() -> CKRecord? {
        guard let data = recordData else {
            return nil
        }
        
        let coder = NSKeyedUnarchiver(forReadingWithData: data)
        coder.requiresSecureCoding = true
        return CKRecord(coder: coder)
    }
}
