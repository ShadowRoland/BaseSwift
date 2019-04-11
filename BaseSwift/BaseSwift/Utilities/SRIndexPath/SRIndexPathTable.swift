//
//  SRIndexPath.Table.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

//用于UITableView中的UITableViewCell
extension SRIndexPath {
    public class Table: SRIndexPath.Item {
        public var cell: UITableViewCell?
        public var height = TableCellHeight
        public var width = ScreenWidth()
        
        public var value: Any? //存储的value，也可以为文字、数字、数组以及其他类型等，以记录对应的文字内容、数字类型和索引等
        public var isValueChanged = false
        
        public var isIgnoreParamValue = false //在数据字典中读取数据时，忽略情景：获取不到正确的value时（包括1、paramKey为nil；2、字典不存在为paramKey的key；3、字典中paramKey对应的value为NSNull；4、字典中paramKey对应的value类型不正确）
        public var paramValueType: JsonValueType = .string //对应数据字典的value的类型
        public var paramKey: String? //对应数据字典的key
        public var paramValue: Any? //对应数据字典的value，目前的要求是必须可以转化为json字典中的value
        
        public required init() {
            super.init()
        }
        
        public init(cell: UITableViewCell?) {
            super.init()
            self.cell = cell
        }
    }
}

public extension SRIndexPath.Set {
    //MARK: - 通过下标获取和设置
    
    func item(cell: UITableViewCell) -> SRIndexPath.Table? {
        return enumerated.first { cell == ($0.element as? SRIndexPath.Table)?.cell }?.element
            as? SRIndexPath.Table
    }
    
    func item(paramKey: String) -> SRIndexPath.Table? {
        return enumerated.first { paramKey == ($0.element as? SRIndexPath.Table)?.paramKey }?.element
            as? SRIndexPath.Table
    }
    
    func update(cell: UITableViewCell, item: Any?) {
        guard let item = item as? SRIndexPath.Table else {
            return
        }
        
        remove(self.item(cell: cell))
        item.cell = cell
        append(item)
    }
    
    func update(paramKey: String, item: Any?) {
        guard let item = item as? SRIndexPath.Table else {
            return
        }
        
        remove(self.item(paramKey: paramKey))
        item.paramKey = paramKey
        append(item)
    }
}

public extension SRIndexPath.AttributedString.Key {
    static let height: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("height")
    static let width: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("width")
    static let paramKey: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("paramKey")
    static let paramValueType: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("paramValueType")
    static let isIgnoreParamValue: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("isIgnoreParamValue") //忽略json value的正确性，包括不为空和正确的value类型
}
