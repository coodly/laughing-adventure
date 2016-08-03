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

public extension String {
    public func hasValue() -> Bool {
        let stripped = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return !stripped.isEmpty
    }
    
    public mutating func appendIssue(_ issue: String) {
        self.append("• \(issue)\n")
    }
}

// http://stackoverflow.com/questions/25138339/nsrange-to-rangestring-index/30404532#30404532
extension String {
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
}
