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
import CloudKit

public struct Config {
    public static var shared = Config()
    
    public var environment = "production"
    public var container = "Define the bucket"
    public var apiToken = "Define the token"
    public var userToken = ""
}

public enum CloudAPIResult<T: RemoteRecord> {
    case Success([T], [CKRecordID])
    case LoginNeeded(NSURL)
    case Failure
}


public class CloudAPIRequest<T: RemoteRecord>: ConcurrentOperation, CloudRequest {
    private let baseURL = NSURL(string: "https://api.apple-cloudkit.com")!
    
    public override init() {
        
    }
    
    public final override func main() {
        performRequest()
    }
    
    public func performRequest() {
        fatalError("Override \(#function)")
    }
    
    public func save(record record: T, inDatabase db: UsedDatabase) {
        
    }
    
    public func save(records records: [T], delete: [CKRecordID], inDatabase db: UsedDatabase) {
        
    }
    
    public func delete(record record: T, inDatabase db: UsedDatabase) {
        
    }
    
    public func fetch(predicate predicate: NSPredicate, limit: Int? = nil, pullAll: Bool = true, inDatabase db: UsedDatabase = .Private) {
        Logging.log("Fetch \(T.recordType)")
        
        POST(to: "/records/query", inDatabase: db)
    }
    
    public func fetchFirst(predicate predicate: NSPredicate, sort: [NSSortDescriptor], inDatabase db: UsedDatabase) {
        fetch(predicate: predicate, limit: 1, pullAll: false, inDatabase: db)
    }
    
    public func handleResult(result: CloudAPIResult<T>) {
        Logging.log("Handle result: \(result)")
    }
}

private extension CloudAPIRequest {
    private func POST(to path: String, inDatabase db: UsedDatabase) {
        let fullPath = "/database/1/\(Config.shared.container)/\(Config.shared.environment)/\(database(db))\(path)"
        
        var components = NSURLComponents(URL: baseURL, resolvingAgainstBaseURL: true)!
        components.path = components.path!.stringByAppendingString(fullPath)
        
        var queryItems = [NSURLQueryItem]()
        queryItems.append(NSURLQueryItem(name: "ckAPIToken", value: Config.shared.apiToken))
        components.queryItems = queryItems
        
        let requestURL: NSURL
        if Config.shared.userToken.hasValue() {
            var urlString = components.URL!.absoluteString
            
            var userToken = Config.shared.userToken
            userToken = userToken.stringByReplacingOccurrencesOfString("+", withString: "%2B")
            userToken = userToken.stringByReplacingOccurrencesOfString("/", withString: "%2F")
            userToken = userToken.stringByReplacingOccurrencesOfString("=", withString: "%3D")
            
            urlString = urlString.stringByAppendingString("&ckWebAuthToken=\(userToken)")
            requestURL = NSURL(string: urlString)!
        } else {
            requestURL = components.URL!
        }
        
        Logging.log("POST to \(requestURL)")
        
        let request = NSMutableURLRequest(URL: requestURL)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            Logging.log("Complete")
            
            var statusCode = 200
            if let httpResponse = response as? NSHTTPURLResponse {
                Logging.log("Response code \(httpResponse.statusCode)")
                Logging.log("Headers: \(httpResponse.allHeaderFields)")
                statusCode = httpResponse.statusCode
            }
            if let data = data, string = String(data: data, encoding: NSUTF8StringEncoding) {
                Logging.log("Response body\n\n \(string)")
            }
            
            guard let data = data else {
                Logging.log("No response data")
                self.handleResult(.Failure)
                return
            }
            
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
                Logging.log("Not json response")
                self.handleResult(.Failure)
                return
            }
            
            
            if statusCode != 200, let redirect = json!["redirectURL"] as? String, url = NSURL(string: redirect) {
                Logging.log("Have redirect")
                self.handleResult(.LoginNeeded(url))
                return
            }
            
            Logging.log("Success?")
        }
        
        task.resume()
    }
    
    private func database(db: UsedDatabase) -> String {
        if db == .Public {
            return "public"
        } else {
            return "private"
        }
    }
}