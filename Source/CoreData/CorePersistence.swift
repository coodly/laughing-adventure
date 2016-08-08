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

import Foundation
import CoreData

private extension NSPredicate {
    static let truePredicate = NSPredicate(format: "TRUEPREDICATE")
}

public class CorePersistence {
    private let stack: CoreStack!
    public lazy var mainContext: NSManagedObjectContext = {
        let context = self.stack.mainContext!
        context.name = "Main"
        return context
    }()
    
    public init(modelName: String) {
        if #available(iOS 10, *) {
            stack = CoreDataStack(modelName: modelName)
        } else {
            stack = LegacyCoreStack()
        }
    }
    
    public func perform(wait: Bool = true, block: ((NSManagedObjectContext) -> ())) {
        let context = stack.mainContext!
        
        if wait {
            context.performAndWait {
                block(context)
            }
        } else {
            context.perform {
                block(context)
            }
        }
    }
    
    public func performBackgroundTask(closure: ((NSManagedObjectContext) -> ()), completion: () -> ()) {
        stack.performBackgroundTask() {
            context in

            closure(context)
            self.save(context: context, completion: completion)
        }
    }
    
    public func save(completion: (() -> ())? = nil) {
        guard let context = stack.mainContext else {
            return
        }
        
        save(context: context, completion: completion)
    }
    
    private func save(context: NSManagedObjectContext, completion: (() -> ())? = nil) {
        context.perform {
            Logging.log("Save \(context.name)")
            
            if context.hasChanges {
                try! context.save()
            }
            
            if let parent = context.parent {
                self.save(context: parent)
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
}

public extension NSManagedObjectContext {
    public func fetch<T: NSManagedObject>(predicate: NSPredicate = .truePredicate) -> [T] {
        let request: NSFetchRequest<T> = NSFetchRequest(entityName: T.entityName())
        request.predicate = predicate
        
        do {
            return try fetch(request)
        } catch {
            Logging.log("Fetch \(T.entityName()) failure. Error \(error)")
            return []
        }
    }
    
    public func fetchFirst<T: NSManagedObject>(predicate: NSPredicate = .truePredicate) -> T? {
        let request: NSFetchRequest<T> = NSFetchRequest(entityName: T.entityName())
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            let result = try fetch(request)
            return result.first
        } catch {
            Logging.log("Fetch \(T.entityName()) failure. Error \(error)")
            return nil
        }
    }
    
    public func fetchEntity<T: NSManagedObject>(where name: String, hasValue: AnyObject) -> T? {
        let attributePredicate = predicate(for: name, withValue: hasValue)
        return fetchFirst(predicate: attributePredicate)
    }
    
    public func predicate(for attribute: String, withValue: AnyObject) -> NSPredicate {
        let predicate: NSPredicate
        
        switch(withValue) {
        case is String:
            predicate = NSPredicate(format: "%K ==[c] %@", argumentArray: [attribute, withValue])
        default:
            predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, withValue])
        }
        
        return predicate
    }
}

private protocol CoreStack {
    var mainContext: NSManagedObjectContext! { get }
    func performBackgroundTask(closure: ((NSManagedObjectContext) -> ()))
}

@available(iOS 10, *)
private class CoreDataStack: CoreStack {
    private let modelName: String!
    private lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores {
            storeDescription, error in
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

        }
        return container
    }()
    private var mainContext: NSManagedObjectContext! {
        return container.viewContext
    }
    
    init(modelName: String) {
        self.modelName = modelName
    }

    private func performBackgroundTask(closure: ((NSManagedObjectContext) -> ())) {
        container.performBackgroundTask() {
            context in
            
            closure(context)
        }
    }
}

private class LegacyCoreStack: CoreStack {
    private var mainContext: NSManagedObjectContext!
    
    private func performBackgroundTask(closure: ((NSManagedObjectContext) -> ())) {
        
    }
}

