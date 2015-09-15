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

let FetchedCollectionCellIdentifier = "FetchedCollectionCellIdentifier"

public class FetchedCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    @IBOutlet public var collectionView:UICollectionView!
    private var fetchedController:NSFetchedResultsController!
    private var measuringCell: UICollectionViewCell?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentSizeChanged", name: UIContentSizeCategoryDidChangeNotification, object: nil)
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
        configureCell(cell, atIndexPath:indexPath, object:object)
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let object = fetchedController.objectAtIndexPath(indexPath)
        configureCell(measuringCell!, atIndexPath: indexPath, object: object)
        let height = calculateHeightForConfiguredSizingCell(measuringCell!)
        return CGSizeMake(CGRectGetWidth(collectionView.frame), height)
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        let object = fetchedController.objectAtIndexPath(indexPath)
        tappedCell(indexPath, object: object)
    }
        
    func contentSizeChanged() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.collectionView.reloadData()
        }
    }
    
    public func createFetchedController() -> NSFetchedResultsController {
        fatalError("Need to override \(__FUNCTION__)")
    }
    
    public func setPresentationCellNib(nib:UINib) {
        collectionView.registerNib(nib, forCellWithReuseIdentifier: FetchedCollectionCellIdentifier)
        measuringCell = nib.loadInstance() as? UICollectionViewCell
    }
    
    public func configureCell(cell:UICollectionViewCell, atIndexPath:NSIndexPath, object:AnyObject) {
        print("configureCell(atIndexPath:\(atIndexPath))")
    }
    
    public func tappedCell(atIndexPath: NSIndexPath, object: AnyObject) {
        print("tappedCell(indexPath:\(atIndexPath))")
    }
    
    func calculateHeightForConfiguredSizingCell(cell: UICollectionViewCell) -> CGFloat {
        var frame = cell.frame
        frame.size.width = CGRectGetWidth(collectionView.frame)
        cell.frame = frame
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height + 1.0
    }
}
