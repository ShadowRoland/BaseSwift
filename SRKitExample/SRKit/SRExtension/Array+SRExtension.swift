//
//  Array+SRExtension.swift
//  SRKit
//
//  Created by Gary on 2020/8/20.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit

public extension Array where Element: AnyObject {
    mutating func append(nonduplicated object: Element?) {
        guard let object = object else { return }
        if isEmpty {
            append(object)
        }
        objc_sync_enter(self)
        if !contains(where: { $0 === object }) {
            append(object)
        }
        objc_sync_exit(self)
    }
    
    mutating func remove(object: Element?) {
        guard let object = object, !isEmpty else { return }
        objc_sync_enter(self)
        let array = drop { $0 === object }
        if array.count != count {
            removeAll()
            array.forEach { append($0) }
        }
        objc_sync_exit(self)
    }
}
