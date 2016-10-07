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

private extension Selector {
    static let addMessage = #selector(ConversationViewController.addMessage)
}

internal class ConversationViewController: FetchedTableViewController<Message, MessageCell>, InjectionHandler, PersistenceConsumer {
    var persistence: CorePersistence!
    var conversation: Conversation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: .addMessage)
        
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier())
    }
    
    override func createFetchedController() -> NSFetchedResultsController<Message> {
        if conversation == nil {
            conversation = persistence.mainContext.insertEntity() as Conversation
        }
        return persistence.mainContext.fetchedControllerForMessages(in: conversation!)
    }
    
    override func configure(cell: MessageCell, at indexPath: IndexPath, with message: Message, forMeasuring: Bool) {
        cell.messageLabel.text = message.body
    }
    
    @objc fileprivate func addMessage() {
        let compose = ComposeViewController()
        compose.conversation = conversation!
        inject(into: compose)
        let navigation = UINavigationController(rootViewController: compose)
        navigation.modalPresentationStyle = .formSheet
        present(navigation, animated: true, completion: nil)
    }
}
