//
//  Numeric+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension Int {
    static func random(_ lower: Int = 0, _ upper: Int = Int.max) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
    }
    
    static func random(range: Range<Int>) -> Int {
        return random(range.lowerBound, range.upperBound)
    }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

public extension NSNumber {
    var isBool: Bool {
        let type = String(cString: objCType)
        if (compare(trueNumber) == .orderedSame && type == trueObjCType)
            || (compare(falseNumber) == .orderedSame && type == falseObjCType) {
            return true
        } else {
            return false
        }
    }
}

//返回各种类型的数值
public struct Number {
    public static func int(_ value: Any?) -> Int? {
        guard let value = value else { return nil }
        
        if let number = value as? Int {
            return number
        }
        
        if let number = value as? NSNumber  {
            return Int(truncating: number)
        }
        
        if let string = value as? String {
            return Int(string)
        }
        
        return nil
    }
    
    public static func long(_ value: Any?) -> CLong? {
        guard let value = value else { return nil }
        
        if let number = value as? CLong {
            return number
        }
        
        if let number = value as? NSNumber  {
            return CLong(truncating: number)
        }
        
        if let string = value as? String {
            return CLong(string)
        }
        
        return nil
    }
    
    public static func longLong(_ value: Any?) -> CLongLong? {
        guard let value = value else { return nil }
        
        if let number = value as? CLongLong {
            return number
        }
        
        if let number = value as? NSNumber  {
            return CLongLong(truncating: number)
        }
        
        if let string = value as? String {
            return CLongLong(string)
        }
        
        return nil
    }
    
    public static func float(_ value: Any?) -> Float? {
        guard let value = value else { return nil }
        
        if let number = value as? Float {
            return number
        }
        
        if let number = value as? NSNumber  {
            return Float(truncating: number)
        }
        
        if let string = value as? String {
            return Float(string)
        }
        
        return nil
    }
    
    public static func double(_ value: Any?) -> Double? {
        guard let value = value else { return nil }
        
        if let number = value as? Double {
            return number
        }
        
        if let number = value as? NSNumber  {
            return Double(truncating: number)
        }
        
        if let string = value as? String {
            return Double(string)
        }
        
        return nil
    }
    
    public static func decimal(_ value: Any?) -> Decimal? {
        guard let value = value else { return nil }
        
        if let number = value as? Decimal {
            return number
        }
        
        return Decimal(string: String(describing: value))
    }
}

public extension Int {
    func thousands(_ decimalPlaces: UInt = 0) -> String {
        let string = UInt(abs(self)).thousands(decimalPlaces)
        return self >= 0 ? string : "-" + string
    }
    
    func tenThousands(_ decimalPlaces: UInt = 0) -> String {
        let string = UInt(abs(self)).tenThousands(decimalPlaces)
        return self >= 0 ? string : "-" + string
    }
}

public extension UInt {
    //使用K(千)做单位，最多到B(十亿)，应该足够了……应该吧
    //decimalPlaces: 最多保留的位数
    func thousands(_ decimalPlaces: UInt = 0) -> String {
        guard self >= 1000 else {
            return String(uint: self)
        }
        
        let thousand = 1000 as CLong
        let million = 1000 * 1000 as CLongLong
        let billion = 1000 * 1000 * 10000 as CLongLong
        
        if self < million {
            let number = CLong(self)
            if 0 == number % thousand {
                return String(format: "%lldK", number / thousand)
            } else if 0 == number % 100 && decimalPlaces >= 1 {
                return String(format: "%.1fK", Float(number) / Float(thousand))
            } else if 0 == number % 10 && decimalPlaces >= 2 {
                return String(format: "%.2fK", Float(number) / Float(thousand))
            } else if decimalPlaces >= 3 {
                return String(format: "%.3fK", Float(number) / Float(thousand))
            } else {
                return String(format: "%.\(decimalPlaces)fK", Float(number) / Float(thousand))
            }
        } else if self < billion {
            let number = CLongLong(self)
            if 0 == number % million {
                return String(format: "%lldM", number / million)
            } else if 0 == number % CLongLong(100 * thousand) && decimalPlaces >= 1 {
                return String(format: "%.1fM", Float(number) / Float(million))
            } else if 0 == number % CLongLong(10 * thousand) && decimalPlaces >= 2 {
                return String(format: "%.2fM", Float(number) / Float(million))
            } else if decimalPlaces >= 3 {
                return String(format: "%.3fM", Float(number) / Float(million))
            } else {
                return String(format: "%.\(decimalPlaces)fM", Float(number) / Float(million))
            }
        } else {
            let number = CLongLong(self)
            if 0 == number % billion {
                return String(format: "%lldB", number / billion)
            } else if 0 == number % CLongLong(100 * million) && decimalPlaces >= 1 {
                return String(format: "%.1fB", Float(number) / Float(billion))
            } else if 0 == number % CLongLong(10 * million) && decimalPlaces >= 2 {
                return String(format: "%.2fB", Float(number) / Float(billion))
            } else if decimalPlaces >= 3 {
                return String(format: "%.3fB", Float(number) / Float(billion))
            } else {
                return String(format: "%.\(decimalPlaces)fB", Float(number) / Float(billion))
            }
        }
    }
    
    //使用万做单位，最多到亿
    func tenThousands(_ decimalPlaces: UInt = 0) -> String {
        guard self >= 10000 else {
            return String(uint: self)
        }
        
        let tenThousand = 10000 as CLong
        let hundredMillion = 10000 * 10000 as CLongLong
        
        if self < hundredMillion {
            let number = CLong(self)
            if 0 == number % tenThousand {
                return String(format: "%ld%@", number / tenThousand, "万")
            } else if 0 == number % 1000 && decimalPlaces >= 1 {
                return String(format: "%.1f%@", Float(number) / Float(tenThousand), "万")
            } else if 0 == number % 100 && decimalPlaces >= 2 {
                return String(format: "%.2f%@", Float(number) / Float(tenThousand), "万")
            } else if 0 == number % 10 && decimalPlaces >= 3 {
                return String(format: "%.3f%@", Float(number) / Float(tenThousand), "万")
            } else if decimalPlaces >= 4 {
                return String(format: "%.4f%@", Float(number) / Float(tenThousand), "万")
            } else {
                return String(format: "%.\(decimalPlaces)f%@", Float(number) / Float(tenThousand), "万")
            }
        } else {
            let number = CLongLong(self)
            if 0 == number % hundredMillion {
                return String(format: "%lld%@", number / hundredMillion, "万")
            } else if 0 == number % CLongLong(1000 * tenThousand) && decimalPlaces >= 1 {
                return String(format: "%.1f%@", Float(number) / Float(hundredMillion), "百万")
            } else if 0 == number % CLongLong(100 * tenThousand) && decimalPlaces >= 2 {
                return String(format: "%.2f%@", Float(number) / Float(hundredMillion), "百万")
            } else if 0 == number % CLongLong(10 * tenThousand) && decimalPlaces >= 3 {
                return String(format: "%.3f%@", Float(number) / Float(hundredMillion), "百万")
            } else if decimalPlaces >= 4 {
                return String(format: "%.4f%@", Float(number) / Float(hundredMillion), "百万")
            } else {
                return String(format: "%.\(decimalPlaces)f%@", Float(number) / Float(hundredMillion), "百万")
            }
        }
    }
}
