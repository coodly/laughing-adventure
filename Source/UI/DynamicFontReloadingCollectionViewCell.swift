/*
 * Copyright 2016 Coodly LLC
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
    static let contentSizeChanged = #selector(DynamicFontReloadingCollectionViewCell.contentSizeChanged)
}

public class DynamicFontReloadingCollectionViewCell: UICollectionViewCell {
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .contentSizeChanged, name: UIContentSizeCategoryDidChangeNotification, object: nil)
        setUIFont()
    }
    
    @objc private func contentSizeChanged() {
        setUIFont()
    }
    
    public func setUIFont() {
        Logging.log("Override \(#function) to set cell font")
    }
}
