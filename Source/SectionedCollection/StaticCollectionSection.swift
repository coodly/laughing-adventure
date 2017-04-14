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

public enum Measure: Equatable {
    case exactly(CGFloat)
    case full
    case compressed
    case undefined
}

public func ==(lhs: Measure, rhs: Measure) -> Bool  {
    switch (lhs, rhs) {
    case (.full, .full):
        return true
    case (.compressed, .compressed):
        return true
    case (.undefined, .undefined):
        return true
    default:
        return false
    }
}

public struct Size {
    public static let cellDefined = Size(width: .undefined, height: .undefined)
    
    public let width: Measure
    public let height: Measure
    
    public init(width: Measure, height: Measure) {
        self.width = width
        self.height = height
    }
}

public struct StaticCollectionSection: CollectionSection {
    public let cellIdentifier = UUID().uuidString
    public let cellNib: UINib
    public let itemsCount: Int
    let itemSize: Size
    public let id: UUID
    internal lazy var measuringCell: UICollectionViewCell = {
        return self.cellNib.loadInstance() as! UICollectionViewCell
    }()
    
    public init(id: UUID = UUID(), cellNib: UINib, numberOfItems: Int, itemSize: Size) {
        self.id = id
        self.cellNib = cellNib
        self.itemsCount = numberOfItems
        self.itemSize = itemSize
    }
}
