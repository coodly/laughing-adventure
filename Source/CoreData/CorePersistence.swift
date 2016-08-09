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

public typealias TaskClosure = (NSManagedObjectContext) -> ()

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
        stack = LegacyCoreStack(modelName: modelName)
    }
    
    public func perform(wait: Bool = true, block: TaskClosure) {
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
    
    public func save(inClosure task: TaskClosure, completion: (() -> ())? = nil) {
        save(inClosures: [task], completion: completion)
    }

    public func save(inClosures tasks: [TaskClosure], completion: (() -> ())? = nil) {
        Logging.log("Perform \(tasks.count) tasks")
        if let task = tasks.first {
            stack.performUsingWorker() {
                context in
                
                task(context)
                self.save(context: context) {
                    var remaining = tasks
                    _ = remaining.removeFirst()
                    self.save(inClosures: remaining, completion: completion)
                }
            }
        } else if let completion = completion {
            Logging.log("All complete")
            completion()
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
    public func fetch<T: NSManagedObject>(predicate: NSPredicate = .truePredicate, limit: Int? = nil) -> [T] {
        let request: NSFetchRequest<T> = NSFetchRequest(entityName: T.entityName())
        request.predicate = predicate
        if let limit = limit {
            request.fetchLimit = limit
        }
        
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
    
    public func sumOfDecimalProperty<T: NSManagedObject>(onType type: T.Type, name: String, predicate: NSPredicate = .truePredicate) -> NSDecimalNumber {
        
        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: T.entityName())
        request.resultType = .dictionaryResultType
        request.predicate = predicate
        
        let sumKey = "sumOfProperty"
        
        let expression = NSExpressionDescription()
        expression.name = sumKey
        expression.expression = NSExpression(forKeyPath: "@sum.\(name)")
        expression.expressionResultType = .decimalAttributeType
        
        request.propertiesToFetch = [expression]
        
        do {
            let result = try fetch(request)
            if let first = result.first, let value = first[sumKey] as? NSDecimalNumber {
                return value
            }
            
            Logging.log("Will return zero for sum of \(name)")
            
            return NSDecimalNumber.zero
        } catch {
            Logging.log("addDecimalProperty error: \(error)")
            return NSDecimalNumber.notANumber
        }
    }
    
    public func count<T: NSManagedObject>(instancesOf entity: T.Type, predicate: NSPredicate = .truePredicate) -> Int {
        let request: NSFetchRequest<NSNumber> = NSFetchRequest(entityName: T.entityName())
        request.predicate = predicate

        do {
            return try count(for: request)
        } catch let error as NSError {
            fatalError("Count failed: \(error)")
        }
    }
}

private protocol CoreStack {
    var mainContext: NSManagedObjectContext! { get }
    func performUsingWorker(closure: ((NSManagedObjectContext) -> ()))
}

@available(iOS 10, *)
private class CoreDataStack: CoreStack {
    private let modelName: String!
    private lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores {
            storeDescription, error in
            
            print(">>>>>>>>> Store: \(storeDescription)")
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

        }
        return container
    }()
    private var mainContext: NSManagedObjectContext! {
        return container.viewContext
    }
    private var workerCount = 0
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    private func performUsingWorker(closure: ((NSManagedObjectContext) -> ())) {
        
    }

    private func performBackgroundTask(closure: ((NSManagedObjectContext) -> ())) {
        Logging.log("Main: \(container.viewContext) - \(container.viewContext.parent) - \(container.viewContext.persistentStoreCoordinator)")
        container.performBackgroundTask() {
            context in
            
            if context.name == nil {
                self.workerCount += 1
                context.name = "Worker \(self.workerCount)"
            }
            
            Logging.log(">>> \(context) - \(context.parent) - \(context.persistentStoreCoordinator)")
            
            closure(context)
        }
    }
}

private let SavingContextName = "Saving"
private let MainContextName = "Main"
private class LegacyCoreStack: CoreStack {
    struct StackConfig {
        var storeType: String!
        var storeURL: URL!
        var options: [NSObject: AnyObject]?
    }

    private var mainContext: NSManagedObjectContext! {
        return managedObjectContext
    }
    
    private let modelName: String
    private let storeType: String
    private let directory: FileManager.SearchPathDirectory
    private var writingContext: NSManagedObjectContext?
    private var wipeDatabaseOnConflict = false
    private var pathToSQLiteFile: URL?
    private let mergePolicy: NSMergePolicyType
    
    private static var spawnedBackgroundCount = 0
    
    init(modelName: String, type: String = NSSQLiteStoreType, in directory: FileManager.SearchPathDirectory = .documentDirectory, mergePolicy: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) {
        self.modelName = modelName
        self.storeType = type
        self.directory = directory
        self.mergePolicy = mergePolicy
    }
    
    private func performUsingWorker(closure: ((NSManagedObjectContext) -> ())) {
        var managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        LegacyCoreStack.spawnedBackgroundCount += 1
        managedContext.name = "Worker \(LegacyCoreStack.spawnedBackgroundCount)"
        managedContext.parent = managedObjectContext
        managedContext.mergePolicy = NSMergePolicy(merge: mergePolicy)
        
        closure(managedContext)
    }
    
    lazy public var managedObjectContext: NSManagedObjectContext = {
        var isPrivateInstance = false
        
        let mergePolicy = NSMergePolicy(merge: self.mergePolicy)
        
        let saving = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        saving.persistentStoreCoordinator = self.persistentStoreCoordinator
        saving.mergePolicy = mergePolicy
        self.writingContext = saving
        saving.name = SavingContextName
        
        var managedContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedContext.name = MainContextName
        managedContext.parent = self.writingContext
        managedContext.mergePolicy = mergePolicy
        
        return managedContext
    }()
    
    
    public lazy var workingFilesDirectory: URL = {
        let urls = FileManager.default.urls(for: self.directory, in: .userDomainMask)
        let last = urls.last!
        let identifier = Bundle.main.bundleIdentifier!
        let dbIdentifier = identifier + ".db"
        let dbFolder = last.appendingPathComponent(dbIdentifier)
        do {
            try FileManager.default.createDirectory(at: dbFolder, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Create db folder error \(error)")
        }
        return dbFolder
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.databaseFilePath()
        
        Logging.log("Using DB file at \(url)")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        let config = StackConfig(storeType: self.storeType, storeURL: url, options: options)
        
        if !self.addPersistentStore(coordinator, config: config, abortOnFailure: !self.wipeDatabaseOnConflict) && self.wipeDatabaseOnConflict {
            Logging.log("Will delete DB")
            try! FileManager.default.removeItem(at: url!)
            _ = self.addPersistentStore(coordinator, config: config, abortOnFailure: true)
        }
        
        return coordinator
    }()
    
    private func addPersistentStore(_ coordinator: NSPersistentStoreCoordinator, config: StackConfig, abortOnFailure: Bool) -> Bool {
        do {
            try coordinator.addPersistentStore(ofType: config.storeType, configurationName: nil, at: config.storeURL, options: config.options)
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
    
    private func databaseFilePath() -> URL? {
        if let existing = pathToSQLiteFile {
            return existing
        } else if self.storeType == NSSQLiteStoreType {
            //TODO jaanus: check this ! here
            return workingFilesDirectory.appendingPathComponent("\(self.modelName).sqlite")
        } else {
            return nil
        }
    }
}

