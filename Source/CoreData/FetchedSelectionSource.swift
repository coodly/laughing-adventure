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

public class FetchedSelectionSource: NSObject, SelectionSource, NSFetchedResultsControllerDelegate {
    private var fetchedController: NSFetchedResultsController!
    public var tableView: UITableView!
    
    override init() {

    }
    
    public convenience init(fetchedController: NSFetchedResultsController) {
        self.init()
        
        self.fetchedController = fetchedController
        self.fetchedController.delegate = self
    }
    
    public func numberOfSections() -> Int {
        guard let sections = fetchedController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    public func numberOfRowsInSection(section: Int) -> Int {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController.sections! as [NSFetchedResultsSectionInfo]
        return sections[section].numberOfObjects
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject {
        return fetchedController.objectAtIndexPath(indexPath)
    }
    
    public func indexPathForObject(object: AnyObject) -> NSIndexPath? {
        #if swift(>=2.3)
            guard let fetched = object as? NSFetchRequestResult else {
                return nil
            }
            
            return fetchedController.indexPathForObject(fetched)
        #else
            return fetchedController.indexPathForObject(object)
        #endif
    }
    
    //TODO jaanus: copy/paste....
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch(type) {
        case NSFetchedResultsChangeType.Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}
