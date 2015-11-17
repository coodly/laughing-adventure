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

public class MultiSelectionViewController: SelectionViewController {
    public var selectionHandler: ((selected: [AnyObject]) -> Void)!
    var selectedElements: [AnyObject]!
 
    public override func viewWillDisappear(animated: Bool) {
        selectionHandler(selected: selectedElements)
    }

    override func isSelected(object: AnyObject) -> Bool {
        return selectedElements.contains( { $0.isEqual(object)} )
    }
    
    public func markSelectedElements(selected: [AnyObject]) {
        selectedElements = selected
        tableView.reloadData()
    }
    
    public override func tappedCell(atIndexPath: NSIndexPath, object: AnyObject) {
        if isSelected(object), let index = selectedElements.indexOf({ $0.isEqual(object) }) {
            selectedElements.removeAtIndex(index)
        } else {
            selectedElements.append(object)
        }
        
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([atIndexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    public func addToSelected(object: AnyObject) {
        selectedElements.append(object)
        tableView.reloadData()
    }
}
