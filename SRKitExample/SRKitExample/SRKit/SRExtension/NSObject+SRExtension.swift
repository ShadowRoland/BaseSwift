//
//  NSObject+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public struct ObjectProperty: Equatable, Hashable, RawRepresentable {
    public typealias RawValue = String
    public var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int { return self.rawValue.hashValue }
}

public extension NSObject {
    typealias property = ObjectProperty

    func setProperty(_ property: NSObject.property, value: Any?) {
        setValue(value, forKey: property.rawValue)
    }
    
    func value(property: NSObject.property) -> Any? {
        return value(forKey: property.rawValue)
    }
    
    var propertyNames: [String] {
        var count: UInt32 = 0
        let properties = class_copyPropertyList(classForCoder, &count)
        return (0 ..< Int(count)).compactMap {
            String(utf8String: property_getName(properties![$0]))
        }
    }
    
    func hasProperty(_ property: NSObject.property) -> Bool {
        return propertyNames.contains(property.rawValue)
    }
    
    func hasProperty(name: String) -> Bool {
        return propertyNames.contains(name)
    }
    
    var methodNames: [String] {
        var count: UInt32 = 0
        let methods = class_copyMethodList(classForCoder, &count)
        return (0 ..< Int(count)).compactMap {
            String(utf8String: method_getName(methods![$0]).description)
        }
    }
    
    func hasMethod(_ property: NSObject.property) -> Bool {
        return methodNames.contains(property.rawValue)
    }
    
    func hasMethod(name: String) -> Bool {
        return methodNames.contains(name)
    }
}
