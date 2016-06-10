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

public class ConcurrentOperation: NSOperation {
    override public var concurrent: Bool {
        return true
    }
    
    private var myExecuting: Bool = false
    override public var executing: Bool {
        get {
            return myExecuting
        }
        set {
            if myExecuting != newValue {
                willChangeValueForKey("isExecuting")
                myExecuting = newValue
                didChangeValueForKey("isExecuting")
            }
        }
    }
    
    private var myFinished: Bool = false;
    override public var finished: Bool {
        get {
            return myFinished
        }
        set {
            if myFinished != newValue {
                willChangeValueForKey("isFinished")
                myFinished = newValue
                didChangeValueForKey("isFinished")
            }
        }
    }
    
    override public func start() {
        if cancelled {
            finish()
            return
        }
        
        self.executing = true
        
        main()
    }
    
    override public func cancel() {
        super.cancel()
        finish()
    }
    
    public func finish() {
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        myExecuting = false
        myFinished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }
}