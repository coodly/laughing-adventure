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

public class InputCellsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet public var tableView: UITableView!
    var sections:[InputCellsSection] = []
    private var activeCellInputValidation: InputValidation?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentSizeChanged", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionCells = sections[section]
        return sectionCells.numberOfCells()
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionCells = sections[indexPath.section]
        return sectionCells.cellAtRow(indexPath.row)
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let section = sections[indexPath.section]
        let cell = section.cellAtRow(indexPath.row)
        handleCellTap(cell, atIndexPath: indexPath)
    }

    private func handleCellTap(cell: UITableViewCell, atIndexPath:NSIndexPath) {
        if cell.isKindOfClass(TextEntryCell) {
            let entryCell = cell as! TextEntryCell
            entryCell.entryField.becomeFirstResponder()
        } else {
            tappedCell(cell, atIndexPath: atIndexPath)
        }
    }
    
    public func tappedCell(cell:UITableViewCell, atIndexPath:NSIndexPath) {
        Logging.log("tappedCell")
    }
    
    public func addSection(section: InputCellsSection) {
        sections.append(section)
        for cell in section.cells {
            guard let textCell = cell as? TextEntryCell else {
                continue
            }
            
            textCell.entryField.delegate = self
        }
    }
    
    public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if let cell = textField.findContainingCell() as? TextEntryCell, validation = cell.inputValidation {
            activeCellInputValidation = validation
        }
        
        return true
    }
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let validation = activeCellInputValidation else {
            return true
        }
        
        return validation.textField(textField, shouldChangeCharactersInRange: range, replacementString: string)
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        activeCellInputValidation = nil
    }
    
    @objc private func contentSizeChanged() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
}
