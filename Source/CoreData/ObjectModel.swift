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
    private var modelName: String!
    private var storeType: String!
    private var writingContext: NSManagedObjectContext?
    
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
    
    lazy public var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        var isPrivateInstance = false
        
        if let writing = self.writingContext {
            isPrivateInstance = true
        } else {
            let saving = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            saving.persistentStoreCoordinator = coordinator
            self.writingContext = saving
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: (isPrivateInstance ? .PrivateQueueConcurrencyType : .MainQueueConcurrencyType))
        managedObjectContext.parentContext = self.writingContext
        
        return managedObjectContext
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
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    public func saveContext () {
        saveContext { () -> Void in
            
        }
    }
    
    public func saveContext(completion: () -> Void) {
        saveContext(managedObjectContext, completion: completion)
    }
    
    private func saveContext(context: NSManagedObjectContext, completion: () -> Void) {
        context.performBlock { () -> Void in
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                }
            }
            
            if let parent = context.parentContext {
                self.saveContext(parent, completion: { () -> Void in
                    
                })
            }
            
            dispatch_async(dispatch_get_main_queue(), completion)
        }
    }
}