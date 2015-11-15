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

import CoreData

public class ObjectModel {
    struct StackConfig {
        var storeType: String!
        var storeURL: NSURL!
        var options: [NSObject: AnyObject]?
    }

    private var modelName: String!
    private var storeType: String!
    private var writingContext: NSManagedObjectContext?
    public var wipeDatabaseOnConflict = false
    
    public init() {
        fatalError("Use some other init method instead")
    }
    
    public convenience init(modelName: String) {
        self.init(modelName: modelName, storeType: NSSQLiteStoreType)
    }
    
    public init(modelName: String, storeType: String) {
        self.modelName = modelName
        self.storeType = storeType
    }
    
    public init(parentContext: NSManagedObjectContext) {
        writingContext = parentContext
    }
    
    public func spawnBackgroundInstance() -> ObjectModel {
        fatalError("Please overwrite this method and instantiate your subclass \(__FUNCTION__)")
    }
    
    lazy public var managedObjectContext: NSManagedObjectContext = {
        var isPrivateInstance = false
        
        if let _ = self.writingContext {
            isPrivateInstance = true
        } else {
            let saving = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            saving.persistentStoreCoordinator = self.persistentStoreCoordinator
            self.writingContext = saving
        }
        
        var managedContext = NSManagedObjectContext(concurrencyType: (isPrivateInstance ? .PrivateQueueConcurrencyType : .MainQueueConcurrencyType))
        managedContext.parentContext = self.writingContext
        
        return managedContext
    }()

    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.modelName).sqlite")

        Logging.log("Using DB file at \(url)")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        let config = StackConfig(storeType: NSSQLiteStoreType, storeURL: url, options: options)
        
        if !self.addPersistentStore(coordinator, config: config, abortOnFailure: !self.wipeDatabaseOnConflict) && self.wipeDatabaseOnConflict {
            Logging.log("Will delete DB")
            try! NSFileManager.defaultManager().removeItemAtURL(url)
            self.addPersistentStore(coordinator, config: config, abortOnFailure: true)
        }
        
        return coordinator
    }()
    
    private func addPersistentStore(coordinator: NSPersistentStoreCoordinator, config: StackConfig, abortOnFailure: Bool) -> Bool {
        do {
            try coordinator.addPersistentStoreWithType(config.storeType, configuration: nil, URL: config.storeURL, options: config.options)
            return true
        } catch {
            // Report any error we got.
            let failureReason = "There was an error creating or loading the application's saved data."
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            Logging.log("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        
        if abortOnFailure {
            abort()
        }
        
        return false
    }
    
    public func saveContext () {
        saveContext(nil)
    }
    
    public func saveContext(completion: (() -> Void)?) {
        saveContext(managedObjectContext, completion: completion)
    }
    
    public func saveInBlock(handler:((model: ObjectModel) -> Void)) {
        saveInBlock(handler, completion: nil)
    }

    public func saveInBlock(handler:((model: ObjectModel) -> Void), completion: (() -> ())?) {
        let spawned = spawnBackgroundInstance()
        spawned.performBlock { () -> () in
            handler(model: spawned)
            spawned.saveContext(completion)
        }
    }

    public func performBlock(block: (() -> ())) {
        managedObjectContext.performBlock(block)
    }
    
    private func saveContext(context: NSManagedObjectContext, completion: (() -> Void)?) {
        context.performBlock { () -> Void in
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    Logging.log("Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                }
            }
            
            if let parent = context.parentContext {
                self.saveContext(parent, completion: nil)
            }
            
            guard let action = completion else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), action)
        }
    }
}

public extension ObjectModel /* Fetched controller */ {
    public func fetchedControllerForEntity<T: NSManagedObject>(type: T.Type, sortDescriptors: [NSSortDescriptor]) -> NSFetchedResultsController {
        return fetchedControllerForEntity(type, predicate: nil, sortDescriptors: sortDescriptors)
    }
    
    public func fetchedControllerForEntity<T: NSManagedObject>(type: T.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) -> NSFetchedResultsController {
        let fetchRequest = fetchedRequestForEntity(type, predicate: predicate, sortDescriptors: sortDescriptors)
        let fetchedController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedController.performFetch()
        } catch {
            Logging.log("Fetch error: \(error)")
        }
        
        return fetchedController
    }
}

public extension ObjectModel /* Fetch request */ {
    
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

public extension ObjectModel /* Delete */ {
    public func deleteObject(object: NSManagedObject, saveAfter: Bool = true) {
        managedObjectContext.deleteObject(object)
        
        if saveAfter {
            saveContext()
        }
    }
}

public extension ObjectModel /* Querys */ {
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
        return fetchFirstEntity(type, predicate: predicate)
    }
    
    public func fetchFirstEntity<T: NSManagedObject>(type: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor] = []) -> T? {
        let request = fetchedRequestForEntity(type, predicate: predicate, sortDescriptors: sortDescriptors)
        
        do {
            let result = try managedObjectContext.executeFetchRequest(request)
            return result.first as? T
        } catch {
            Logging.log(error)
            return nil
        }
    }
}

public extension ObjectModel /* Predicates */ {
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
