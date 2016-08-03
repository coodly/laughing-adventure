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
    private var fetchedController: NSFetchedResultsController<AnyObject>?
    private var measuringCell: UITableViewCell?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        fetchedController?.delegate = nil
    }
    
    public override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: .contentSizeChanged, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        
        checkTableView()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        smoothDeselectRows()
        
        if let _ = fetchedController {
            return
        }
        
        fetchedController = createFetchedController()
        fetchedController!.delegate = self
        tableView!.reloadData()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedController?.sections else {
            return 0
        }
        
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let controller = fetchedController, sections = controller.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FetchedTableCellIdentifier)!
        let object = fetchedController!.object(at: indexPath)
        configureCell(cell, atIndexPath: indexPath, object: object, forMeasuring:false)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = fetchedController!.object(at: indexPath)
        let detailsShown = tappedCell(indexPath, object: object)
        if detailsShown {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController!.sections! as [NSFetchedResultsSectionInfo]
        let dataSection = sections[section]
        return dataSection.name
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .update:
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .move:
            fatalError("Wut? \(sectionIndex)")
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case NSFetchedResultsChangeType.update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case NSFetchedResultsChangeType.insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case NSFetchedResultsChangeType.delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case NSFetchedResultsChangeType.move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        contentChanged()
    }
        
    public func setPresentationCellNib(_ nib:UINib) {
        tableView.register(nib, forCellReuseIdentifier: FetchedTableCellIdentifier)
        measuringCell = tableView.dequeueReusableCell(withIdentifier: FetchedTableCellIdentifier)
    }
    
    func contentSizeChanged() {
        DispatchQueue.main.async { () -> Void in
            self.tableView.reloadData()
        }
    }
    
    public func createFetchedController() -> NSFetchedResultsController<AnyObject> {
        fatalError("Need to override \(#function)")
    }
    
    public func tappedCell(_ atIndexPath: IndexPath, object: AnyObject) -> Bool {
        Logging.log("tappedCell(indexPath:\(atIndexPath))")
        return false
    }
    
    public func configureCell(_ cell: UITableViewCell, atIndexPath: IndexPath, object: AnyObject, forMeasuring:Bool) {
        Logging.log("configureCell(atIndexPath:\(atIndexPath))")
    }
    
    public func contentChanged() {
        Logging.log("Content changed")
    }
    
    public func objectAt(_ indexPath: IndexPath) -> AnyObject {
        return fetchedController!.object(at: indexPath)
    }
}
