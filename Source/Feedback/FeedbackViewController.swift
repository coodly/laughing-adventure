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
import CloudKit
import CoreData

private extension Selector {
    static let donePressed = #selector(FeedbackViewController.donePressed)
    static let addPressed = #selector(FeedbackViewController.addPressed)
    static let refreshConversations = #selector(FeedbackViewController.refresh)
}

public class FeedbackViewController: FetchedTableViewController<Conversation, ConversationCell> {
    private lazy var feedbackContainer: CKContainer = {
        return CKContainer(identifier: "iCloud.com.coodly.feedback")
    }()
    private var refreshControl: UIRefreshControl!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("coodly.feedback.controller.title", comment: "")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: .donePressed)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: .addPressed)
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: .refreshConversations, for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    public override func createFetchedController() -> NSFetchedResultsController<Conversation> {
        return NSFetchedResultsController<Conversation>()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshControl.beginRefreshingManually()
    }
    
    @objc fileprivate func donePressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func addPressed() {
        
    }
    
    @objc fileprivate func refresh() {
        Logging.log("Refresh conversations")
    }
}
