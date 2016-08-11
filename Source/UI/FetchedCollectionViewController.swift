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

import Foundation
import UIKit
import CoreData

private extension Selector {
    static let contentSizeChanged = #selector(FetchedCollectionViewController.contentSizeChanged)
}

class CollectionCoreDataChangeAction {
    var indexPath: IndexPath?
    var newIndexPath: IndexPath?
    var changeType = NSFetchedResultsChangeType.update
    
    static func action(_ atIndexPath: IndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) -> CollectionCoreDataChangeAction {
        let result = CollectionCoreDataChangeAction()
        result.indexPath = atIndexPath
        result.changeType = changeType
        result.newIndexPath = newIndexPath
        return result
    }
}

let FetchedCollectionCellIdentifier = "FetchedCollectionCellIdentifier"

public class FetchedCollectionViewController<Model: NSManagedObject>: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    @IBOutlet public var collectionView: UICollectionView!
    private var fetchedController: NSFetchedResultsController<Model>?
    private var measuringCell: UICollectionViewCell?
    private var changeActions: [CollectionCoreDataChangeAction]!
    
    public var ignoreOffScreenUpdates = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: .contentSizeChanged, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        
        if collectionView != nil {
            return
        }
        
        //not loaded from xib
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        
        let views: [String: AnyObject] = ["collection": collectionView]
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collection]|", options: [], metrics: nil, views: views)
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collection]|", options: [], metrics: nil, views: views)
        
        view.addConstraints(vertical + horizontal)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        if fetchedController != nil {
            return
        }
        
        fetchedController = createFetchedController()
        fetchedController!.delegate = self
        
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let controller = fetchedController else {
            return 0
        }
        
        let sections:[NSFetchedResultsSectionInfo] = controller.sections! as [NSFetchedResultsSectionInfo]
        return sections[section].numberOfObjects
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: FetchedCollectionCellIdentifier, for: indexPath)
        let object:AnyObject = fetchedController!.object(at: indexPath)
        configureCell(cell, atIndexPath:indexPath, object:object, forMeasuring:false)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let object = fetchedController!.object(at: indexPath)
        configureCell(measuringCell!, atIndexPath: indexPath, object: object, forMeasuring:true)
        let height = calculateHeightForConfiguredSizingCell(measuringCell!)
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let object = fetchedController!.object(at: indexPath)
        tappedCell(indexPath, object: object)
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Logging.log("controllerWillChangeContent")
        changeActions = [CollectionCoreDataChangeAction]()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        changeActions.append(CollectionCoreDataChangeAction.action(indexPath, changeType: type, newIndexPath: newIndexPath))
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Logging.log("controllerDidChangeContent: \(changeActions.count) changes")
        let visible = collectionView.indexPathsForVisibleItems
        
        let updateClosure = {
            for action in self.changeActions {
                let type = action.changeType
                switch(type) {
                case NSFetchedResultsChangeType.update:
                    if (self.ignoreOffScreenUpdates && !visible.contains(action.indexPath!)) {
                        continue
                    }
                    self.collectionView.reloadItems(at: [action.indexPath!])
                case NSFetchedResultsChangeType.insert:
                    self.collectionView.insertItems(at: [action.newIndexPath!])
                case NSFetchedResultsChangeType.delete:
                    self.collectionView.deleteItems(at: [action.indexPath!])
                case NSFetchedResultsChangeType.move:
                    self.collectionView.moveItem(at: action.indexPath!, to: action.newIndexPath!)
                }
            }
        }
        
        let completion: (Bool) -> () = {
            finished in
            
            self.contentChanged()
        }
        
        collectionView.performBatchUpdates(updateClosure, completion: completion)
    }
        
    func contentSizeChanged() {
        DispatchQueue.main.async { () -> Void in
            self.collectionView.reloadData()
        }
    }
    
    public func isEmpty() -> Bool {
        return fetchedController?.fetchedObjects?.count == 0
    }
    
    public func contentChanged() {
        Logging.log("\(#function)")
    }
    
    public func createFetchedController() -> NSFetchedResultsController<Model> {
        fatalError("Need to override \(#function)")
    }
    
    public func setPresentationCellNib(_ nib:UINib) {
        collectionView.register(nib, forCellWithReuseIdentifier: FetchedCollectionCellIdentifier)
        measuringCell = nib.loadInstance() as? UICollectionViewCell
    }
    
    public func configureCell(_ cell:UICollectionViewCell, atIndexPath:IndexPath, object:AnyObject, forMeasuring:Bool) {
        Logging.log("configureCell(atIndexPath:\(atIndexPath))")
    }
    
    public func tappedCell(_ atIndexPath: IndexPath, object: AnyObject) {
        Logging.log("tappedCell(indexPath:\(atIndexPath))")
    }
    
    func calculateHeightForConfiguredSizingCell(_ cell: UICollectionViewCell) -> CGFloat {
        var frame = cell.frame
        frame.size.width = collectionView.frame.width
        cell.frame = frame
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        return size.height
    }
    
    public func hasObjectAtIndexPath(_ indexPath: IndexPath) -> Bool {
        guard let controller = fetchedController else {
            return false
        }
        
        guard let sections = controller.sections, sections.count > (indexPath as NSIndexPath).section else {
            return false
        }
        
        let section = sections[(indexPath as NSIndexPath).section]
        if section.numberOfObjects <= (indexPath as NSIndexPath).row {
            return false
        }
        
        return true
    }
    
    public func objectAt(_ indexPath: IndexPath) -> AnyObject {
        return fetchedController!.object(at: indexPath)
    }
}
