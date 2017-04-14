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

import CoreData

open class FetchedCollectionSection: CollectionSection {
    public let cellIdentifier = UUID().uuidString
    private let controller: NSFetchedResultsController<NSManagedObject>
    public var itemsCount: Int {
        return controller.fetchedObjects?.count ?? 0
    }
    public let cellNib: UINib
    public let id: UUID
    internal var cellConfigure: ((UICollectionViewCell, IndexPath) -> ())!
    internal lazy var measuringCell: UICollectionViewCell = {
        return self.cellNib.loadInstance() as! UICollectionViewCell
    }()
    
    
    public init<Model: NSManagedObject, Cell: UICollectionViewCell>(id: UUID = UUID(), cell: Cell.Type, fetchedController: NSFetchedResultsController<Model>, configure: @escaping ((Cell, Model) -> ())) {
        self.id = id
        self.cellNib = cell.viewNib()
        controller = fetchedController as! NSFetchedResultsController<NSManagedObject>
        
        cellConfigure = {
            cell, indexPath in
            
            let model = fetchedController.object(at: indexPath)
            configure(cell as! Cell, model)
        }
    }
    
    open func size(in view: UICollectionView) -> CGSize {
        return measuringCell.frame.size
    }
}
