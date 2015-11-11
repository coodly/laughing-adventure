/*
* Copyright 2015 Coodly LLC
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

import Foundation
import CoreData

public extension ObjectModel {
    public func hasEntity<T: NSManagedObject>(type: T.Type, attribute: String, hasValue: AnyObject) -> Bool {
        let predicate = predicateForAttribute(attribute, withValue: hasValue)
        return count(type, predicate: predicate) == 1
    }
    
    public func count<T: NSManagedObject>(type: T.Type, predicate: NSPredicate) -> Int {
        let request = fetchedRequestForEntity(type, predicate: predicate)
        
        var error: NSError?
        let count = managedObjectContext.countForFetchRequest(request, error: &error)
        
        if error != nil {
            fatalError("Count failed: \(error)")
        }
        
        return count
    }
    
    public func fetchEntity<T: NSManagedObject>(type: T.Type, whereAttribute: String, hasValue: AnyObject) -> T? {
        let predicate = predicateForAttribute(whereAttribute, withValue: hasValue)
        let request = fetchedRequestForEntity(type, predicate: predicate)
        
        do {
            let result = try managedObjectContext.executeFetchRequest(request)
            return result.first as? T
        } catch {
            Logging.log(error)
            return nil
        }
    }
    
    public func predicateForAttribute(attributeName: String, withValue: AnyObject) -> NSPredicate {
        let predicate: NSPredicate
        
        switch(withValue) {
        case is String:
            predicate = NSPredicate(format: "%K CONTAINS[c] %@", argumentArray: [attributeName, withValue])
        default:
            predicate = NSPredicate(format: "%K = %@", argumentArray: [attributeName, withValue])
        }
        
        return predicate
    }
    
}