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
        let predicate: NSPredicate
        
        switch(hasValue) {
        case is String:
            predicate = NSPredicate(format: "%K CONTAINS[c] %@", argumentArray: [attribute, hasValue])
        default:
            predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, hasValue])
        }
        
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
}