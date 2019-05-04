//
//  SRIndexPath.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

open class SRIndexPath {
    open class Set: NSObject {
        private(set) var set: Swift.Set<SRIndexPath.Item> = []
        
        open var enumerated: EnumeratedSequence<Swift.Set<SRIndexPath.Item>> {
            return set.enumerated()
        }
        
        //将所有的items根据indexPath的大小顺序输出为数组
        open var sorted: [SRIndexPath.Item] {
            return enumerated.sorted { $0.element.indexPath < $1.element.indexPath }.map { $0.element }
        }
        
        open func append(_ item: SRIndexPath.Item?) {
            guard let item = item else { return }
            if set.contains(item) {
                set.update(with: item)
            } else {
                //删掉已存在相同indexPath的item
                let oldItem = enumerated.first { item.indexPath == $0.element.indexPath }?.element
                if oldItem != nil {
                    set.remove(oldItem!)
                }
                set.insert(item)
            }
        }
        
        open func remove(_ item: SRIndexPath.Item?) {
            guard let item = item else { return }
            set.remove(item)
        }
        
        open func removeAll() {
            set.removeAll()
        }
        
        open var numberOfSections: Int {
            return numberOfIndexPathes(0 ..< 1)
        }
        
        open func numberOfIndexPathes(_ range: Range<Int>) -> Int {
            if range.count <= 0 || set.isEmpty {
                return set.count
            }
            
            var indexPaths = [] as [IndexPath]
            enumerated.compactMap { item -> IndexPath? in
                var indexPath = item.element.indexPath
                let lower = indexPath.index(indexPath.startIndex, offsetBy: range.lowerBound)
                let upper = indexPath.index(indexPath.startIndex, offsetBy: range.upperBound)
                indexPath = indexPath[Range<IndexPath.Index>(uncheckedBounds: (lower: lower, upper: upper))]
                return !indexPath.isEmpty ? indexPath : nil
                }.forEach { indexPath in
                    if indexPaths.first(where: { indexPath == $0 }) == nil { //去重
                        indexPaths.append(indexPath)
                    }
            }
            return indexPaths.count
        }
        
        //MARK: - 通过下标获取和设置
        
        open subscript(key: Any) -> SRIndexPath.Item? {
            get {
                if key is IndexPath {
                    return item(indexPath: key as! IndexPath)
                } else if key is UITableViewCell {
                    return item(cell: key as! UITableViewCell)
                } else if key is String {
                    return item(paramKey: key as! String)
                } else if key is UIView {
                    return item(inputTextView: key as! UIView)
                }
                return nil
            }
            set (newValue) {
                if key is IndexPath {
                    update(indexPath: key as! IndexPath, item: newValue)
                } else if key is UITableViewCell {
                    update(cell: key as! UITableViewCell, item: newValue)
                } else if key is String {
                    update(paramKey: key as! String, item: newValue)
                } else if key is UIView {
                    update(inputTextView: key as! UIView, item: newValue)
                }
            }
        }
    }
    
    open class Item: NSObject {
        open var indexPath: IndexPath = IndexPath(row: 0, section: 0)
        open var config: [AttributedString.Key : Any] = [:]
        
        public required override init() {
            super.init()
        }
        
        public init(indexPath: IndexPath) {
            super.init()
            self.indexPath = indexPath
        }
    }
    
    open class AttributedString {
        public struct Key: RawRepresentable, Hashable {
            public typealias RawValue = String
            public var rawValue: String
            
            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }
}

public extension SRIndexPath.Set {
    //MARK: - 通过下标获取和设置
    
    func item(indexPath: IndexPath) -> SRIndexPath.Item? {
        return enumerated.first { indexPath == $0.element.indexPath }?.element
    }
    
    func update(indexPath: IndexPath, item: Any?) {
        guard let item = item as? SRIndexPath.Item else {
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
    func items(count: Int) -> [SRIndexPath.Item] {
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
    
    func items(headIndex: Int, count: Int = 0) -> [SRIndexPath.Item] {
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
    func items(headIndexPath: IndexPath, count: Int = 0) -> [SRIndexPath.Item] {
        return sorted.filter {
            $0.indexPath.count >= headIndexPath.count
                && $0.indexPath.prefix(headIndexPath.count) == headIndexPath
                && (count <= 0 || count == $0.indexPath.count)
        }
    }
}

public extension Dictionary where Key == SRIndexPath.AttributedString.Key {
    func jsonValue(configKey: Key,
                   type: JsonValueType,
                   outValue: UnsafeMutablePointer<Any?>) -> Bool {
        return jsonValue(configKey, type: type, outValue: outValue)
    }
}
