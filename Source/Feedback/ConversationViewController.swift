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
import CoreData

#if os(iOS)
private extension Selector {
    static let addMessage = #selector(ConversationViewController.addMessage)
}

internal class ConversationViewController: FetchedTableViewController<Message, MessageCell>, InjectionHandler, PersistenceConsumer {
    var persistence: CorePersistence!
    var conversation: Conversation?
    
    private var refreshControl: UIRefreshControl!
    private var refreshed = false
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMddHHmm")
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: .addMessage)
        
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier())
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !refreshed && conversation!.hasUpdate else {
            return
        }
        
        tableView.tableFooterView = FooterLoadingView()
        refreshMessages()
        refreshed = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let rows = tableView.numberOfRows(inSection: 0)
        tableView.scrollToRow(at: IndexPath(row: rows - 1, section: 0), at: .middle, animated: true)
    }
    
    override func createFetchedController() -> NSFetchedResultsController<Message> {
        if conversation == nil {
            conversation = persistence.mainContext.insertEntity() as Conversation
        }
        return persistence.mainContext.fetchedControllerForMessages(in: conversation!)
    }
    
    override func configure(cell: MessageCell, at indexPath: IndexPath, with message: Message, forMeasuring: Bool) {
        let timeString = dateFormatter.string(from: message.postedAt)
        let timeValue: String
        if let sentBy = message.sentBy {
            timeValue = "\(sentBy) - \(timeString)"
        } else {
            timeValue = timeString
        }
        cell.timeLabel.text = timeValue
        cell.messageLabel.text = message.body
        cell.alignment = message.sentBy == nil ? .right : .left
    }
    
    @objc fileprivate func addMessage() {
        let compose = ComposeViewController()
        compose.conversation = conversation!
        inject(into: compose)
        let navigation = UINavigationController(rootViewController: compose)
        navigation.modalPresentationStyle = .formSheet
        present(navigation, animated: true, completion: nil)
    }
    
    private func refreshMessages() {
        guard let c = conversation, c.recordData != nil else {
            refreshControl.endRefreshing()
            return
        }
        
        let request = PullMessagesOperation(for: c)
        request.completionHandler = {
            success, op in
            
            DispatchQueue.main.async {
                self.tableView.tableFooterView = UIView()
            }
        }
        inject(into: request)
        request.start()
    }
}
#endif
