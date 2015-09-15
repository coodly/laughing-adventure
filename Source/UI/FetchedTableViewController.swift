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

import UIKit
import CoreData

let FetchedTableCellIdentifier = "FetchedTableCellIdentifier"

public class FetchedTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet public var tableView: UITableView!
    private var fetchedController:NSFetchedResultsController!
    private var measuringCell: UITableViewCell?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentSizeChanged", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func viewWillAppear(animated: Bool) {
        if fetchedController != nil {
            return
        }
        
        fetchedController = createFetchedController()
        fetchedController.delegate = self
        tableView.reloadData()
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = fetchedController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController.sections! as [NSFetchedResultsSectionInfo]
        return sections[section].numberOfObjects
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(FetchedTableCellIdentifier)!
        let object = fetchedController.objectAtIndexPath(indexPath)
        configureCell(cell, atIndexPath: indexPath, object: object)
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let object = fetchedController.objectAtIndexPath(indexPath)
        tappedCell(indexPath, object: object)
    }
    
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
        
    public func setPresentationCellNib(nib:UINib) {
        tableView.registerNib(nib, forCellReuseIdentifier: FetchedTableCellIdentifier)
        measuringCell = tableView.dequeueReusableCellWithIdentifier(FetchedTableCellIdentifier)
    }
    
    func contentSizeChanged() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.tableView.reloadData()
        }
    }
    
    public func createFetchedController() -> NSFetchedResultsController {
        fatalError("Need to override \(__FUNCTION__)")
    }
    
    public func tappedCell(atIndexPath: NSIndexPath, object: AnyObject) {
        print("tappedCell(indexPath:\(atIndexPath))")
    }
    
    public func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath, object: AnyObject) {
        print("configureCell(atIndexPath:\(atIndexPath))")
    }
}