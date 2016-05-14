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
    var indexPath: NSIndexPath?
    var newIndexPath: NSIndexPath?
    var changeType = NSFetchedResultsChangeType.Update
    
    static func action(atIndexPath: NSIndexPath?, changeType: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) -> CollectionCoreDataChangeAction {
        let result = CollectionCoreDataChangeAction()
        result.indexPath = atIndexPath
        result.changeType = changeType
        result.newIndexPath = newIndexPath
        return result
    }
}

let FetchedCollectionCellIdentifier = "FetchedCollectionCellIdentifier"

public class FetchedCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    @IBOutlet public var collectionView: UICollectionView!
    private var fetchedController: NSFetchedResultsController!
    private var measuringCell: UICollectionViewCell?
    private var changeActions: [CollectionCoreDataChangeAction]!
    
    public var ignoreOffScreenUpdates = false
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .contentSizeChanged, name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    public override func viewWillAppear(animated: Bool) {
        if fetchedController != nil {
            return
        }
        
        fetchedController = createFetchedController()
        fetchedController.delegate = self
        
        collectionView.reloadData()
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController.sections! as [NSFetchedResultsSectionInfo]
        return sections[section].numberOfObjects
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(FetchedCollectionCellIdentifier, forIndexPath: indexPath)
        let object:AnyObject = fetchedController!.objectAtIndexPath(indexPath)
        configureCell(cell, atIndexPath:indexPath, object:object, forMeasuring:false)
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let object = fetchedController.objectAtIndexPath(indexPath)
        configureCell(measuringCell!, atIndexPath: indexPath, object: object, forMeasuring:true)
        let height = calculateHeightForConfiguredSizingCell(measuringCell!)
        return CGSizeMake(CGRectGetWidth(collectionView.frame), height)
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        let object = fetchedController.objectAtIndexPath(indexPath)
        tappedCell(indexPath, object: object)
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        Logging.log("controllerWillChangeContent")
        changeActions = [CollectionCoreDataChangeAction]()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        Logging.log("didChangeObject")
        changeActions.append(CollectionCoreDataChangeAction.action(indexPath, changeType: type, newIndexPath: newIndexPath))
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        Logging.log("controllerDidChangeContent")
        let visible = collectionView.indexPathsForVisibleItems()
        
        collectionView.performBatchUpdates({ () -> Void in
            for action in self.changeActions {
                let type = action.changeType
                switch(type) {
                case NSFetchedResultsChangeType.Update:
                    if (self.ignoreOffScreenUpdates && !visible.contains(action.indexPath!)) {
                        continue
                    }
                    self.collectionView.reloadItemsAtIndexPaths([action.indexPath!])
                case NSFetchedResultsChangeType.Insert:
                    self.collectionView.insertItemsAtIndexPaths([action.newIndexPath!])
                case NSFetchedResultsChangeType.Delete:
                    self.collectionView.deleteItemsAtIndexPaths([action.indexPath!])
                case NSFetchedResultsChangeType.Move:
                    self.collectionView.moveItemAtIndexPath(action.indexPath!, toIndexPath: action.newIndexPath!)
                }
            }
        }) { (finished) -> Void in
            self.contentChanged()
        }
    }
        
    func contentSizeChanged() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.collectionView.reloadData()
        }
    }
    
    public func isEmpty() -> Bool {
        return fetchedController.fetchedObjects?.count == 0
    }
    
    public func contentChanged() {
        Logging.log("\(#function)")
    }
    
    public func createFetchedController() -> NSFetchedResultsController {
        fatalError("Need to override \(#function)")
    }
    
    public func setPresentationCellNib(nib:UINib) {
        collectionView.registerNib(nib, forCellWithReuseIdentifier: FetchedCollectionCellIdentifier)
        measuringCell = nib.loadInstance() as? UICollectionViewCell
    }
    
    public func configureCell(cell:UICollectionViewCell, atIndexPath:NSIndexPath, object:AnyObject, forMeasuring:Bool) {
        Logging.log("configureCell(atIndexPath:\(atIndexPath))")
    }
    
    public func tappedCell(atIndexPath: NSIndexPath, object: AnyObject) {
        Logging.log("tappedCell(indexPath:\(atIndexPath))")
    }
    
    func calculateHeightForConfiguredSizingCell(cell: UICollectionViewCell) -> CGFloat {
        var frame = cell.frame
        frame.size.width = CGRectGetWidth(collectionView.frame)
        cell.frame = frame
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height
    }
    
    public func objectAt(indexPath: NSIndexPath) -> AnyObject {
        return fetchedController.objectAtIndexPath(indexPath)
    }
}
