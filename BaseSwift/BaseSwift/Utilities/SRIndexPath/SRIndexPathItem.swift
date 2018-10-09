//
//  SRIndexPathItem.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

open class SRIndexPathItem: NSObject {
    public var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    public var config: [SRIndexPathConfigKey : Any] = [:]
    
    public required override init() {
        super.init()
    }
    
    public init(indexPath: IndexPath) {
        super.init()
        self.indexPath = indexPath
    }
}

//IndexPathItem property key in config dictionary
//因为IndexPathItem需要配置的参数过多，为了避免初始化函数的参数过多，故将所有的参数放在字典中
//应用于app内部
public struct SRIndexPathConfigKey: Hashable, Equatable, RawRepresentable {
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

public extension Dictionary where Key == SRIndexPathConfigKey {
    func jsonValue(configKey: Key,
                   type: JsonValueType,
                   outValue: UnsafeMutablePointer<Any?>) -> Bool {
        return jsonValue(configKey, type: type, outValue: outValue)
    }
}

public extension SRIndexPathSet {
    
    //MARK: - 通过下标获取和设置
    
    func item(indexPath: IndexPath) -> SRIndexPathItem? {
        return enumerated.first { indexPath == $0.element.indexPath }?.element
    }
    
    func update(indexPath: IndexPath, item: Any?) {
        guard let item = item as? SRIndexPathItem else {
            return
        }
        
        item.indexPath = indexPath
        append(item)
    }
    
    //MARK: - 通过参数获取item数组
    
    /**
     *  获取所有IndexPath长度为count的对象
     *  如参数count为2，将返回(1, 3), (2, 5), (7, 11)...
     *  @param count indexPath的长度
     *  @return items
     */
    func items(count: Int) -> [SRIndexPathItem] {
        return sorted.filter { count == $0.indexPath.count }
    }
    
    /**
     *  获取所有IndexPath第一位为输入参数的对象，并且可以限制返回数组中item的IndexPath长度，count为0表示长度无限制
     *  如参数headIndex为1，将返回(1, 5), (1, 2, 0), (1, 6, 0, 0)...
     *  如参数count为3，将只返回(1, 2, 0)
     *  @param headIndex 符合要求的索引的第一位
     *         count indexPath的长度
     *  @return items
     */
    
    func items(headIndex: Int, count: Int = 0) -> [SRIndexPathItem] {
        return sorted.filter {
            $0.indexPath[$0.indexPath.startIndex] == headIndex && (count <= 0 || count == $0.indexPath.count)
        }
    }
    
    /**
     *  获取所有IndexPath之前的部分为输入参数的对象，并且可以限制返回数组中item的IndexPath长度，count为0表示长度无限制
     *  如参数为(1, 2)，将返回(1, 2), (1, 2, 0), (1, 2, 0, 0)...
     *  如参数为3，将只返回(1, 2, 0)
     *  @param headIndexPath 符合要求的索引的前面部分
     *         count indexPath的长度
     *  @return items
     */
    func items(headIndexPath: IndexPath, count: Int = 0) -> [SRIndexPathItem] {
        return sorted.filter {
            $0.indexPath.count >= headIndexPath.count
                && $0.indexPath.prefix(headIndexPath.count) == headIndexPath
                && (count <= 0 || count == $0.indexPath.count)
        }
    }
}
