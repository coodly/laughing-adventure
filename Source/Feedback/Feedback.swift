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

public let CoodlyFeedbackNewMessagesNotifiction = Notification.Name(rawValue: "CoodlyFeedbackNewMessagesNotifiction")

#if os(iOS)
public class Feedback: InjectionHandler {
    public static func enable() {
        // Touch it to start initialization
        _ = Injector.sharedInstance
    }
    
    public static func mainController() -> FeedbackViewController {
        let controller = FeedbackViewController()
        Feedback.inject(into: controller)
        return controller
    }
}
#endif
