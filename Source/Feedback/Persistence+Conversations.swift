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

import CoreData

internal extension NSManagedObjectContext {
    func fetchedControllerForConversations() -> NSFetchedResultsController<Conversation> {
        let sort = NSSortDescriptor(key: "createdAt", ascending: true)
        return fetchedController(sort: [sort])
    }
    
    func namesForExistingConversations() -> [String] {
        return fetchAttribute(named: "recordName", on: Conversation.self)
    }
    
    func update(_ conversation: CloudConversation) {
        let saved = existing(conversation) ?? insertEntity()
        
        saved.recordName = conversation.recordName
        saved.createdAt = conversation.createdAt
    }
    
    func removeConversations(withNames: [String]) {
        let predicate = NSPredicate(format: "recordName IN %@", withNames)
        let removed = fetch(predicate: predicate, limit: nil)
        Logging.log("Remove \(removed.count) conversations")
        for r in removed {
            delete(r)
        }
    }
    
    private func existing(_ conversation: CloudConversation) -> Conversation? {
        return fetchEntity(where: "recordName", hasValue: conversation.recordName!)
    }
}
