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

internal class MessageCell: UITableViewCell {
    private(set) var timeLabel: UILabel!
    private(set) var messageLabel: UILabel!
    private var stack: UIStackView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        timeLabel = UILabel()
        timeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timeLabel.numberOfLines = 1
        timeLabel.setContentCompressionResistancePriority(1000, for: .vertical)
        timeLabel.setContentHuggingPriority(1000, for: .vertical)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel = UILabel()
        messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
        messageLabel.numberOfLines = 0
        messageLabel.setContentCompressionResistancePriority(999, for: .vertical)
        messageLabel.setContentHuggingPriority(1000, for: .vertical)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stack = UIStackView(arrangedSubviews: [timeLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        let views: [String: AnyObject] = ["stack": stack, "time": timeLabel, "message": messageLabel]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(8)-[stack]-(8)-|", options: [], metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(16)-[stack]-(16)-|", options: [], metrics: nil, views: views))
        
        stack.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[time(>=0)]", options: [], metrics: nil, views: views))
        stack.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[message(>=0)]", options: [], metrics: nil, views: views))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
