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

class FetchedCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    @IBOutlet var collectionView:UICollectionView!
    var fetchedController:NSFetchedResultsController?
    
    
    override func viewWillAppear(animated: Bool) {
        if let controller = fetchedController {
            
        } else {
            let fetchedController = createFetchedController()
            fetchedController.delegate = self
            self.fetchedController = fetchedController
            
            collectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections:[NSFetchedResultsSectionInfo] = fetchedController!.sections as! [NSFetchedResultsSectionInfo]
        return sections[section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("FetchedCellIdentifier", forIndexPath: indexPath) as! UICollectionViewCell
        let object:AnyObject = fetchedController!.objectAtIndexPath(indexPath)
        configureCell(cell, atIndexPath:indexPath, withObject:object)
        return cell
    }
    
    func createFetchedController() -> NSFetchedResultsController! {
        fatalError("Need to override \(__FUNCTION__)")
    }
    
    func setPresentationCellNib(nib:UINib) {
        collectionView.registerNib(nib, forCellWithReuseIdentifier: "FetchedCellIdentifier")
    }
    
    func configureCell(cell:UICollectionViewCell, atIndexPath:NSIndexPath, withObject:AnyObject) {
        println("configureCell:atIndexPath:\(atIndexPath)")
    }
}
