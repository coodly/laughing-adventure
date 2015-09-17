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
    
    public var source: SelectionSource! {
        didSet {
            source.tableView = tableView
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
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
        configureCell(cell, withObject: object, selected:false)
        return cell
    }
    
    public func configureCell(cell: UITableViewCell, withObject: AnyObject, selected: Bool) {
        print("configureCell(selected:\(selected))")
    }
    
    public func setPresentationCellNib(nib:UINib) {
        tableView.registerNib(nib, forCellReuseIdentifier: SingleSelectionTableCellIdentifier)
    }
}