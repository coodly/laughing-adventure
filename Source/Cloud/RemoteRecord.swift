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
    static var recordType: String { get }

    init()
    
    mutating func load(record: CKRecord) -> Bool
    mutating func loadFields(record: CKRecord) -> Bool
    func referenceRepresentation() -> CKReference
}

public extension RemoteRecord {
    final mutating func load(record: CKRecord) -> Bool {
        recordData = archiveRecord(record)
        recordName = record.recordID.recordName
        return loadFields(record)
    }
    
    func referenceRepresentation() -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordName!), action: .DeleteSelf)
    }
    
    private func archiveRecord(record: CKRecord) -> NSMutableData {
        let archivedData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: archivedData)
        archiver.requiresSecureCoding = true
        record.encodeSystemFieldsWithCoder(archiver)
        archiver.finishEncoding()
        return archivedData
    }
    
    private func unarchiveRecord() -> CKRecord? {
        guard let data = recordData else {
            return nil
        }
        
        let coder = NSKeyedUnarchiver(forReadingWithData: data)
        coder.requiresSecureCoding = true
        return CKRecord(coder: coder)
    }
    
    internal func recordRepresentation() -> CKRecord {
        let modified: CKRecord
        if let existing = unarchiveRecord() {
            modified = existing
        } else if let name = recordName {
            modified = CKRecord(recordType: Self.recordType, recordID: CKRecordID(recordName: name))
        } else {
            modified = CKRecord(recordType: Self.recordType)
        }
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label where label != "recordName" && label != "recordData" else {
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
            } else if let value = child.value as? CKReference {
                modified[label] = value
            } else if let value = child.value as? [String] {
                modified[label] = value
            } else if let value = child.value as? [NSNumber] {
                modified[label] = value
            } else if let value = child.value as? [NSDate] {
                modified[label] = value
            } else if let value = child.value as? [CLLocation] {
                modified[label] = value
            } else if let value = child.value as? [CKReference] {
                modified[label] = value
            } else {
                Logging.log("Could not cast \(child) value")
            }
        }

        return modified
    }
}
