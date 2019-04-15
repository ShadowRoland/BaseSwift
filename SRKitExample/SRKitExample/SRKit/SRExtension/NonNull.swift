//
//  NonNull.swift
//  BaseSwift
//
//  Created by Gary on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

//返回各种对象的非空数据
public struct NonNull {
    public static func check(_ param: Any?) -> Bool {
        return !(param == nil || param is NSNull)
    }
    
    public static func number(_ value: Any?) -> NSNumber {
        if let number = value as? NSNumber {
            return number
        } else if let string = value as? String, string.isNumberValue {
            return NSDecimalNumber(string: string)
        }
        
        return NSNumber()
    }
    
    public static func string(_ string: Any?) -> String {
        guard let string = string as? String else {
            return ""
        }
        return string
    }
    
    public static func array(_ array: Any?) -> [Any] {
        guard let array = array as? [Any] else {
            return []
        }
        return array
    }
    
    public static func dictionary(_ dictionary: Any?) -> [AnyHashable : Any] {
        guard let dictionary = dictionary as? [AnyHashable : Any] else {
            return [:]
        }
        return dictionary
    }
}
