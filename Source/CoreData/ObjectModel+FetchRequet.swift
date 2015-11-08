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

    public func fetchedRequestForEntity<T: NSManagedObject>(type: T.Type) -> NSFetchRequest {
        return fetchedRequestForEntity(type, predicate: nil, sortDescriptors: [])
    }

    public func fetchedRequestForEntity<T: NSManagedObject>(type: T.Type, predicate: NSPredicate) -> NSFetchRequest {
        return fetchedRequestForEntity(type, predicate: predicate, sortDescriptors: [])
    }
    
    public func fetchedRequestForEntity<T: NSManagedObject>(type: T.Type, sortDescriptors: [NSSortDescriptor]) -> NSFetchRequest {
        return fetchedRequestForEntity(type, predicate: nil, sortDescriptors: sortDescriptors)
    }
    
    public func fetchedRequestForEntity<T: NSManagedObject>(type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) -> NSFetchRequest {
        let request = NSFetchRequest(entityName: type.entityName())
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
}
