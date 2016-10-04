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

class PullConversationsOperation: CloudKitRequest<CloudConversation> {
    var persistence: CorePersistence!
    
    override func performRequest() {
        fetch()
    }
    
    override func handle(result: CloudResult<CloudConversation>, completion: @escaping () -> ()) {
        switch result {
        case .failure:
            completion()
        case .success(let conversations, _):
            let save: ContextClosure = {
                context in
                
                var existing = Set(context.namesForExistingConversations() ?? [])
                
                for c in conversations {
                    existing.remove(c.recordName!)
                    
                    context.update(c)
                }
                
                if existing.count > 0 {
                    context.removeConversations(withNames: Array(existing))
                }
            }
            
            persistence.performInBackground(task: save, completion: completion)
        }
    }
}
