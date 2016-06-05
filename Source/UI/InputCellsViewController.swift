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

private extension Selector {
    static let contentSizeChanged = #selector(InputCellsViewController.contentSizeChanged)
}

public class InputCellsSection {
    private let cells: [UITableViewCell]
    private var title: String?
    
    public init(title: String? = nil, cells: [UITableViewCell]) {
        self.title = title
        self.cells = cells
    }
    
    func numberOfCells() -> Int {
        return cells.count
    }
    
    func cellAtRow(row: Int) -> UITableViewCell {
        return cells[row]
    }
}

public class InputCellsViewController: UIViewController, FullScreenTableCreate, SmoothTableRowDeselection {
    @IBOutlet public var tableView: UITableView!
    private var sections:[InputCellsSection] = []
    private var activeCellInputValidation: InputValidation?
    public var preferredStyle: UITableViewStyle = .Plain
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidLoad() {
        checkTableView(preferredStyle)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .contentSizeChanged, name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        smoothDeselectRows()
        
        configureReturnButtons()
    }
    
    private func handleCellTap(cell: UITableViewCell, atIndexPath:NSIndexPath) -> Bool {
        if cell.isKindOfClass(TextEntryCell) {
            let entryCell = cell as! TextEntryCell
            entryCell.entryField.becomeFirstResponder()
            return false
        } else {
            return tappedCell(cell, atIndexPath: atIndexPath)
        }
    }
    
    public func tappedCell(cell:UITableViewCell, atIndexPath:NSIndexPath) -> Bool {
        Logging.log("tappedCell")
        return false
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
    
    private func indexPathForCell(cell: UITableViewCell) -> NSIndexPath? {
        for section in 0 ..< sections.count {
            let sec = sections[section]
            
            if let row = sec.cells.indexOf(cell) {
                return NSIndexPath(forRow: row, inSection: section)
            }
        }
        
        return nil
    }
    
    private func nextEntryCellAfterIndexPath(indexPath: NSIndexPath) -> TextEntryCell? {
        var section = indexPath.section
        var row = indexPath.row + 1
        
        for ; section < sections.count; section += 1 {
            let sec = sections[section]
            
            for ; row < sec.cells.count; row += 1 {
                if let cell = sec.cells[row] as? TextEntryCell {
                    return cell
                }
            }
            
            row = 0
        }
        
        return nil
    }
    
    @objc private func contentSizeChanged() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    private func configureReturnButtons() {
        var lastEntryCell: TextEntryCell?
        for section in sections {
            for cell in section.cells {
                guard let textEntry = cell as? TextEntryCell else {
                    continue
                }
                
                textEntry.setReturnKeyType(.Next)
                lastEntryCell = textEntry
            }
        }
        
        if let last = lastEntryCell {
            last.setReturnKeyType(.Done)
        }
    }
}

// MARK: - Sections / cells
public extension InputCellsViewController {
    func replaceCell(atIndexPath indexPath: NSIndexPath, withCell cell: UITableViewCell) {
        if let textEntryCell = cell as? TextEntryCell {
            textEntryCell.entryField.delegate = self
        }
        
        tableView.beginUpdates()
        
        let section = sections[indexPath.section]
        var cells = section.cells
        cells[indexPath.row] = cell
        sections[indexPath.section] = InputCellsSection(cells: cells)
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        tableView.endUpdates()

        configureReturnButtons()
    }
}

// MARK: - Table view delegates
extension InputCellsViewController: UITableViewDelegate, UITableViewDataSource {
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
        let section = sections[indexPath.section]
        let cell = section.cellAtRow(indexPath.row)
        let detailsShonw = handleCellTap(cell, atIndexPath: indexPath)
        
        if detailsShonw {
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - Text field delegate
extension InputCellsViewController: UITextFieldDelegate {
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
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let cell = textField.findContainingCell() as? TextEntryCell, indexPath = indexPathForCell(cell), nextCell = nextEntryCellAfterIndexPath(indexPath) {
            nextCell.entryField.becomeFirstResponder()
            activeCellInputValidation = nextCell.inputValidation
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}
