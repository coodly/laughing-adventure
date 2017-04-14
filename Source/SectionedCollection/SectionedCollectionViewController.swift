/*
 * Copyright 2017 Coodly LLC
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

open class SectionedCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet public var collectionView: UICollectionView!
    
    private var sections = [CollectionSection]()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if collectionView == nil {
            //not loaded from xib
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = UIColor.clear
            view.addSubview(collectionView)
            
            let views: [String: AnyObject] = ["collection": collectionView]
            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collection]|", options: [], metrics: nil, views: views)
            let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collection]|", options: [], metrics: nil, views: views)
            
            view.addConstraints(vertical + horizontal)
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let dataSection = sections[section]
        return dataSection.itemsCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cellIdentifier, for: indexPath)
        if section is StaticCollectionSection {
            configure(cell: cell, in: section.id, at: indexPath)
        } else if let fetched = section as? FetchedCollectionSection {
            let path = IndexPath(row: indexPath.row, section: 0)
            fetched.cellConfigure(cell, path)
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = sections[indexPath.section]
        
        if var staticSection = section as? StaticCollectionSection {
            let measuringCell = staticSection.measuringCell
            let size = staticSection.itemSize
            
            if size.width == .undefined && size.height == .undefined {
                return measuringCell.frame.size
            }
            
            configure(cell: measuringCell, in: section.id, at: indexPath, forMeasuring: true)
            if size.width == .full && size.height == .compressed {
                measuringCell.frame.size.width = collectionView.frame.width
                measuringCell.setNeedsLayout()
                measuringCell.layoutIfNeeded()
                measuringCell.frame.size.height = measuringCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            }
            return measuringCell.frame.size
        } else if let fetched = section as? FetchedCollectionSection {
            return fetched.size(in: collectionView)
        }
        
        fatalError("Size not calculated")
    }        
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        tapped(cell: collectionView.cellForItem(at: indexPath), at: indexPath)
    }

    public func append(section: CollectionSection) {
        let collection = collectionView!
        let updates = {
            let insertAt = self.sections.count
            collection.register(section.cellNib, forCellWithReuseIdentifier: section.cellIdentifier)
            self.sections.append(section)
            collection.insertSections(IndexSet(integer: insertAt))
        }
        collection.performBatchUpdates(updates)
    }
    
    public func reload(_ sectionId: UUID) {
        guard let index = sections.index(where: { $0.id == sectionId }) else {
            return
        }
        
        let collection = collectionView!
        let updates = {
            collection.reloadSections(IndexSet(integer: index))
        }
        collection.performBatchUpdates(updates)
    }
    
    open func configure(cell: UICollectionViewCell, in section: UUID, at indexPath: IndexPath, forMeasuring: Bool = false) {
        
    }
    
    open func tapped(cell: UICollectionViewCell?, at indexPath: IndexPath) {
        Logging.log("tapped(at:\(indexPath))")
    }
}
