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

let SingleSelectionTableCellIdentifier = "SingleSelectionTableCellIdentifier"

public class SingleSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView: UITableView!
    public var selectionHandler: ((selected: AnyObject?) -> Void)!
    var selectedElement: AnyObject?
    
    public var source: SelectionSource!
    
    public override func viewWillAppear(animated: Bool) {
        source.tableView = tableView
        tableView.reloadData()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        selectionHandler(selected: selectedElement)
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return source.numberOfSections()
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.numberOfRowsInSection(section)
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SingleSelectionTableCellIdentifier)!
        let object = source.objectAtIndexPath(indexPath)
        configureCell(cell, withObject: object, selected:object.isEqual(selectedElement))
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selected = source.objectAtIndexPath(indexPath)
        moveSelectionToElement(selected)
    }
    
    public func configureCell(cell: UITableViewCell, withObject: AnyObject, selected: Bool) {
        Logging.log("configureCell(selected:\(selected))")
    }
    
    public func setPresentationCellNib(nib:UINib) {
        tableView.registerNib(nib, forCellReuseIdentifier: SingleSelectionTableCellIdentifier)
    }
    
    public func markSelected(element: AnyObject) {
        moveSelectionToElement(element)
    }
    
    func moveSelectionToElement(element: AnyObject) {
        tableView.beginUpdates()
        
        
        if let previous = selectedElement, let previousIndexPath = source.indexPathForObject(previous) {
            tableView.reloadRowsAtIndexPaths([previousIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        selectedElement = element
        if let selectedIndexPath = source.indexPathForObject(element) {
            tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        tableView.endUpdates()
    }
}
