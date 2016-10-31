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
import CloudKit

internal protocol InjectionHandler {
    func inject(into: AnyObject)
}

internal extension InjectionHandler {
    func inject(into: AnyObject) {
        Injector.sharedInstance.inject(into: into)
    }
}

private class Injector {
    fileprivate static let sharedInstance = Injector()
    
    private lazy var persistence: CorePersistence = {
        let persistence = CorePersistence(modelName: "Feedback", identifier: "com.coodly.feedback", in: .cachesDirectory, wipeOnConflict: true)
        persistence.managedObjectModel = NSManagedObjectModel.createFeedbackV1()
        return persistence
    }()
    private lazy var feedbackContainer: CKContainer = {
        return CKContainer(identifier: "iCloud.com.coodly.feedback")
    }()
    private lazy var platform: String = {
        let device = self.platformName() ?? "unknown"
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuild = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let systemVersion = UIDevice.current.systemVersion
        return "\(device)|\(systemVersion)|\(appVersion)(\(appBuild))"
    }()
    private let messagesPush: MessagesPush

    init() {
        messagesPush = MessagesPush()
        DispatchQueue.main.async {
            self.inject(into: self.messagesPush)
        }
    }

    
    fileprivate func inject(into: AnyObject) {
        if var consumer = into as? PersistenceConsumer {
            consumer.persistence = persistence
        }
        
        if var consumer = into as? FeedbackContainerConsumer {
            consumer.feedbackContainer = feedbackContainer
        }
        
        if var consumer = into as? PlatformConsumer {
            consumer.platform = platform
        }
    }
    
    //https://github.com/schickling/Device.swift/blob/master/Device/UIDeviceExtension.swift
    private func platformName() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        let mirror = Mirror(reflecting: machine)
        var identifier = ""
        
        for child in mirror.children {
            if let value = child.value as? Int8 , value != 0 {
                identifier.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        
        return identifier
    }
}

internal protocol PersistenceConsumer {
    var persistence: CorePersistence! { get set }
}

internal protocol FeedbackContainerConsumer {
    var feedbackContainer: CKContainer! { get set }
}

internal protocol PlatformConsumer {
    var platform: String! { get set }
}
