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

private extension Selector {
    static let contentSizeChanged = #selector(FetchedTableViewController.contentSizeChanged)
}

let FetchedTableCellIdentifier = "FetchedTableCellIdentifier"

public class FetchedTableViewController: UIViewController, FullScreenTableCreate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, SmoothTableRowDeselection {
    @IBOutlet public var tableView: UITableView!
    private var fetchedController: NSFetchedResultsController?
    private var measuringCell: UITableViewCell?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        fetchedController?.delegate = nil
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .contentSizeChanged, name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        checkTableView()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        smoothDeselectRows()
        
        if let _ = fetchedController {
            return
        }
        
        fetchedController = createFetchedController()
        fetchedController!.delegate = self
        tableView!.reloadData()
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = fetchedController?.sections else {
            return 0
        }
        
        return sections.count
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let controller = fetchedController, sections = controller.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(FetchedTableCellIdentifier)!
        let object = fetchedController!.objectAtIndexPath(indexPath)
        configureCell(cell, atIndexPath: indexPath, object: object, forMeasuring:false)
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = fetchedController!.objectAtIndexPath(indexPath)
        let detailsShown = tappedCell(indexPath, object: object)
        if detailsShown {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController!.sections! as [NSFetchedResultsSectionInfo]
        let dataSection = sections[section]
        return dataSection.name
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Update:
            tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Move:
            fatalError("Wut? \(sectionIndex)")
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch(type) {
        case NSFetchedResultsChangeType.Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeType.Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        contentChanged()
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
        fatalError("Need to override \(#function)")
    }
    
    public func tappedCell(atIndexPath: NSIndexPath, object: AnyObject) -> Bool {
        Logging.log("tappedCell(indexPath:\(atIndexPath))")
        return false
    }
    
    public func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath, object: AnyObject, forMeasuring:Bool) {
        Logging.log("configureCell(atIndexPath:\(atIndexPath))")
    }
    
    public func contentChanged() {
        Logging.log("Content changed")
    }
    
    public func objectAt(indexPath: NSIndexPath) -> AnyObject {
        return fetchedController!.objectAtIndexPath(indexPath)
    }
}
