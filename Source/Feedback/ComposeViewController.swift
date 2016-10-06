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
    static let sendPressed = #selector(ComposeViewController.sendPressed)
    static let cancelPressed = #selector(ComposeViewController.cancelPressed)
}

internal class ComposeViewController: UIViewController {
    private var bottomSpacing: NSLayoutConstraint!
    
    override func viewDidLoad() {
        
        navigationItem.title = NSLocalizedString("coodly.feedback.message.compose.controller.title", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: .cancelPressed)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("coodly.feedback.message.compose.controller.send.button", comment: ""), style: .plain, target: self, action: .sendPressed)
        
        let textView = UITextView(frame: view.bounds)
        view.addSubview(textView)
        
        let views: [String: AnyObject] = ["text": textView]
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[text]-(123)-|", options: [], metrics: nil, views: views)
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[text]|", options: [], metrics: nil, views: views)
        
        view.addConstraints(vertical + horizontal)
        
        for c in view.constraints {
            if c.constant == 123 {
                bottomSpacing = c
                break
            }
        }
        
        bottomSpacing.constant = 0
    }
    
    @objc fileprivate func sendPressed() {
        
    }
    
    @objc fileprivate func cancelPressed() {
        dismiss(animated: true, completion: nil)
    }
}
