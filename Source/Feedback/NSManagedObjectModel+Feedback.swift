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

internal extension NSManagedObjectModel {
    static func createFeedbackV1() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        //create entities
        let conversationDesc = NSEntityDescription()
        conversationDesc.name = "Conversation"
        conversationDesc.managedObjectClassName = "Conversation"
        
        let conversationCreateTime = NSAttributeDescription()
        conversationCreateTime.name = "createdAt"
        conversationCreateTime.attributeType = .dateAttributeType
        
        let recordName = NSAttributeDescription()
        recordName.name = "recordName"
        recordName.attributeType = .stringAttributeType
        
        let messageDesc = NSEntityDescription()
        messageDesc.name = "Message"
        messageDesc.managedObjectClassName = "Message"
        
        conversationDesc.properties = [conversationCreateTime, recordName]
        
        let entities = [conversationDesc, messageDesc]
        
        model.entities = entities
        
        return model
    }
}
