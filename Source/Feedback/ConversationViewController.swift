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

internal class ConversationViewController: FetchedTableViewController<Message, MessageCell>, PersistenceConsumer {
    var persistence: CorePersistence!
    var conversation: Conversation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: .addMessage)
    }
    
    override func createFetchedController() -> NSFetchedResultsController<Message> {
        let shown = conversation ?? persistence.mainContext.insertEntity()
        persistence.save()
        return persistence.mainContext.fetchedControllerForMessages(in: shown)
    }
    
    @objc fileprivate func addMessage() {
        let compose = ComposeViewController()
        let navigation = UINavigationController(rootViewController: compose)
        navigation.modalPresentationStyle = .formSheet
        present(navigation, animated: true, completion: nil)
    }
}
