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

import Foundation
import CoreData

internal extension NSManagedObjectContext {
    func fetchedControllerForMessages(in conversation: Conversation) -> NSFetchedResultsController<Message> {
        let sort = NSSortDescriptor(key: "postedAt", ascending: true)
        let inConversation = NSPredicate(format: "conversation = %@", conversation)
        return fetchedController(predicate: inConversation, sort: [sort])
    }
    
    func addMessage(_ message: String, for conversation: Conversation) {
        let saved: Message = insertEntity()
        saved.body = message
        saved.conversation = conversation
        saved.postedAt = Date()
        conversation.lastMessageTime = Date()
        conversation.snippet = message.snippet()
    }
}

private extension String {
    func snippet() -> String {
        let snippetLength = min(100, characters.count)
        let endIndex = index(startIndex, offsetBy: snippetLength)
        return substring(to: endIndex)
    }
}
