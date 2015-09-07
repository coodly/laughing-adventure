//
//  NSManagedObject+EnityDefinition.swift
//  Pods
//
//  Created by Jaanus Siim on 06/09/15.
//
//

import Foundation
import CoreData

public extension NSManagedObject {
    public class func entityName() -> String {
        fatalError("Override entityName in your object")
    }
    
    public class func insertInManagedObjectContext(context: NSManagedObjectContext) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(self.entityName(), inManagedObjectContext: context)
    }
}
