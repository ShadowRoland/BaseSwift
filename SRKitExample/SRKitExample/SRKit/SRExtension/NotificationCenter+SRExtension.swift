//
//  UIView+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

let NotifyDefault = NotificationCenter.default

public extension NotificationCenter {
    func add(_ observer: Any,
             selector aSelector: Selector,
             name aName: NSNotification.Name?,
             object anObject: Any? = nil) {
        addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }
    
    func post(_ name: NSNotification.Name) {
        post(name: name, object: nil)
    }
    
    func remove(_ observer: Any,
                name aName: NSNotification.Name? = nil,
                object anObject: Any? = nil) {
        removeObserver(observer, name: aName, object: anObject)
    }
    
}
