//
//  Dictionary+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import SwiftyJSON

/*
 * addEntriesFromDictionary
 let addedDictionary = ["a":1,"b":2]
 var dictionary = ["c":3,"a":4]
 dictionary += addedDictionary //dictionary = ["a":4,"b":2, "c":3]
 */
public func += <KeyType, ValueType> ( left: inout Dictionary<KeyType, ValueType>,
                                      right: Dictionary<KeyType, ValueType>) {
    right.forEach { left.updateValue($1, forKey: $0)}
}

public extension Dictionary {
    func extend(_ dictionary: Dictionary) -> Dictionary {
        var mutabledictionary = self
        mutabledictionary += dictionary
        return mutabledictionary
    }
}

//MARK: Json Dictionary

public enum JsonValueType: Int {
    case string = 0, //字符串
    array, //数组
    dictionary, //对象
    number, //用于存放浮点数，大数
    enumInt, //整数类型的枚举
    bool //布尔值
}

public extension Dictionary where Key : Hashable {
    func jsonValue(_ key: Key,
                   type: JsonValueType,
                   outValue: UnsafeMutablePointer<Any?>) -> Bool {
        guard let value = self[key] else {
            return false
        }
        
        outValue.pointee = nil
        
        //value is null in dictionary
        if value is NSNull {
            return true
        }
        
        switch type {
        case .string:
            if let string = value as? String {
                outValue.pointee = string
            } else if let number = value as? NSNumber {
                outValue.pointee = String(object: number)
            } else {
                return false
            }
            
        case .array:
            if let array = value as? AnyArray {
                outValue.pointee = array
            } else {
                return false
            }
            
        case .dictionary:
            if let dictionary = value as? ParamDictionary{
                outValue.pointee = dictionary
            } else {
                return false
            }
            
        case .number:
            if let number = value as? NSNumber {
                outValue.pointee = number
            } else if let string = value as? String, string.trim.isNumberValue {
                outValue.pointee = NSDecimalNumber(string: string.trim)
            } else {
                return false
            }
            
        case .enumInt:
            if let number = value as? NSNumber {
                outValue.pointee = number.intValue
            } else if let string = value as? String, let intValue = Int(string) {
                outValue.pointee = intValue
            } else {
                return false
            }
            
        case .bool:
            if let boolValue = value as? Bool {
                outValue.pointee = boolValue
            } else if let string = value as? String, let boolValue = Bool(string) {
                outValue.pointee = boolValue
            } else {
                return false
            }
        }
        
        return true
    }
}

public extension Dictionary where Key == String {
    var urlQuery: String {
        return keys.sorted(by: <)
            .map { queryComponents(fromKey: $0, value: self[$0]!) }
            .flatMap { $0 }
            .map { "\($0)=\($1)" }
            .joined(separator: "&")
    }
    
    //Copy ParameterEncoding.swift
    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components = [] as [(String, String)]
        
        if let dictionary = value as? [String: Any] {
            dictionary.forEach {
                components += queryComponents(fromKey: "\(key)[\($0.key)]", value: $0.value)
            }
        } else if let array = value as? AnyArray {
            array.forEach { components += queryComponents(fromKey: "\(key)[]", value: $0) }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    private func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        var escaped = ""
        
        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================
        
        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex
                
                let substring = string.substring(with: range)
                
                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring
                
                index = endIndex
            }
        }
        
        return escaped
    }
}

extension Dictionary where Key == String {
    ///根据给定的位置做值的替换，如positions为：
    ///{
    ///    "body" :
    ///    {
    ///        "contact" :
    ///        [
    ///            {
    ///                "phone" : "***",
    ///                "idNo" : "3403*****"
    ///            }
    ///        ]
    ///    }
    ///}
    ///在self的三层位置上的phone和idNo将会被替换为"***"和"3403*****"
    ///无论self的同样位置同样key对应的值是什么类型（字符串，数值，对象），都会被替换为positions中同样位置同样key对应的value
    ///PS: 数组的成员只能是字典或者数组，而且只遍历第一个成员
    public func replacingOccurrences(positions: ParamDictionary) -> ParamDictionary {
        return replacingOccurrences(dictionary: self, postion: positions)
    }
    
    fileprivate func replacingOccurrences(dictionary target: ParamDictionary, postion: ParamDictionary) -> ParamDictionary {
        var dictionary = [:] as ParamDictionary
        target.forEach { (key, value) in
            let valueInPostion = postion[key]
            if let string = valueInPostion as? String {
                dictionary[key] = string
            } else if let dictionaryValue = value as? ParamDictionary,
                let postion = valueInPostion as? ParamDictionary {
                dictionary[key] = replacingOccurrences(dictionary: dictionaryValue, postion: postion)
            } else if let arrayValue = value as? AnyArray,
                let postion = valueInPostion as? [ParamDictionary] {
                dictionary[key] = replacingOccurrences(array: arrayValue, postion: postion)
            } else {
                dictionary[key] = valueInPostion
            }
        }
        return dictionary
    }
    
    fileprivate func replacingOccurrences(array target: AnyArray, postion: [ParamDictionary]) -> AnyArray {
        guard let postion = postion.first else {
            return target
        }
        
        return target.compactMap { (element) -> Any? in
            if let dictionaryValue = element as? ParamDictionary {
                return replacingOccurrences(dictionary: dictionaryValue, postion: postion)
            } else {
                return element
            }
        }
    }
    
    ///根据给定的键值对数组做值的替换，如keyValues为：
    ///{
    ///    "phone" : "***",
    ///    "idNo" : "3403*****"
    ///}
    ///在self的所有层次的位置上的phone和idNo将会被替换为"***"和"3403*****"
    ///无论self的所有层次职位上key对应的值是什么类型（字符串，数值，对象），都会被替换为keyValues中key对应的value
    public func replacingOccurrences(keyValues: [String : String]) -> ParamDictionary {
        return replacingOccurrences(dictionary: self, keyValues: keyValues)
    }
    
    fileprivate func replacingOccurrences(dictionary target: ParamDictionary, keyValues: [String : String]) -> ParamDictionary {
        var dictionary = [:] as ParamDictionary
        target.forEach { (key, value) in
            if let valueInPostion = keyValues[key] {
                dictionary[key] = valueInPostion
            } else if let dictionaryValue = value as? ParamDictionary {
                dictionary[key] = replacingOccurrences(dictionary: dictionaryValue, keyValues: keyValues)
            } else if let arrayValue = value as? AnyArray {
                dictionary[key] = replacingOccurrences(array: arrayValue, keyValues: keyValues)
            } else {
                dictionary[key] = value
            }
        }
        return dictionary
    }
    
    fileprivate func replacingOccurrences(array target: AnyArray, keyValues: [String : String]) -> AnyArray {
        return target.compactMap { (element) -> Any? in
            if let dictionaryValue = element as? ParamDictionary {
                return replacingOccurrences(dictionary: dictionaryValue, keyValues: keyValues)
            } else {
                return element
            }
        }
    }
}
