//
//  SRIndexPathSet.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

public class SRIndexPathSet: NSObject {
    private(set) var set: Set<SRIndexPathItem> = []

    public var enumerated: EnumeratedSequence<Set<SRIndexPathItem>> {
        return set.enumerated()
    }
    
    //将所有的items根据indexPath的大小顺序输出为数组
    public var sorted: [SRIndexPathItem] {
        return enumerated.sorted { $0.element.indexPath < $1.element.indexPath }.map { $0.element }
    }
    
    public func append(_ item: SRIndexPathItem?) {
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
    
    public func remove(_ item: SRIndexPathItem?) {
        guard let item = item else { return }
        set.remove(item)
    }
    
    //MARK: - 通过下标获取和设置
    
    public subscript(key: Any) -> SRIndexPathItem? {
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
