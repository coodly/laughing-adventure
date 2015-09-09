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

    override public func viewDidLoad() {
        super.viewDidLoad()

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
        return cell
    }
    
    public func setPresentationCellNib(nib:UINib) {
        tableView.registerNib(nib, forCellReuseIdentifier: FetchedTableCellIdentifier)
    }
    
    public func createFetchedController() -> NSFetchedResultsController {
        fatalError("Need to override \(__FUNCTION__)")
    }
}
