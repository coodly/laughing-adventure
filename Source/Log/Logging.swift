/*
* Copyright 2015 Coodly LLC
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

class Logging {
    class func log<T>(object: T, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        var cleanedFile = "-"
        let fileURL = NSURL(fileURLWithPath: file, isDirectory: false)
        if let cleaned = fileURL.lastPathComponent {
            cleanedFile = cleaned
        }
        let message = "\(cleanedFile).\(function):\(line) - \(object)"
        print(message)
    }
}