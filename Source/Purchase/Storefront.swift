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
import StoreKit

public typealias ProductsResponse = ([SKProduct], [String]) -> ()

public class Storefront: NSObject, SKProductsRequestDelegate {
    private var requests = [SKProductsRequest: ProductsResponse]()

    public func retrieve(products: [String], completion: @escaping ProductsResponse) {
        Logging.log("Retrieve products: \(products)")
        let request = SKProductsRequest(productIdentifiers: Set(products))
        request.delegate = self
        requests[request] = completion
        request.start()
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        Logging.log("Retrieved: \(response.products.count). Invalid \(response.invalidProductIdentifiers)")
        guard let completion = requests.removeValue(forKey: request) else {
            return
        }
        
        completion(response.products, response.invalidProductIdentifiers)
    }
}
