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

import Foundation

public class MoneyFormatter {
    private enum FormatterKey: String {
        case AmountOnlyFormatter
        
        func key() -> String {
            return String(reflecting: self)
        }
    }
    
    public class func formattedAmountOnly(number: NSDecimalNumber) -> String? {
        return amountOnlyFormatter().stringFromNumber(number)
    }

    private class func amountOnlyFormatter() -> NSNumberFormatter {
        if let fomatter = MoneyFormatter.formatterForKey(.AmountOnlyFormatter) {
            return fomatter
        }
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.currencySymbol = ""
        formatter.groupingSeparator = ""
        formatter.decimalSeparator = "."
        MoneyFormatter.setFormatterForKey(formatter, key: .AmountOnlyFormatter)
        
        return formatter
    }
    
    private class func setFormatterForKey(formatter: NSNumberFormatter, key: FormatterKey) {
        NSThread.currentThread().threadDictionary[key.key()] = formatter
    }
        
    private class func formatterForKey(key: FormatterKey) -> NSNumberFormatter? {
        return NSThread.currentThread().threadDictionary[key.key()] as? NSNumberFormatter
    }
}