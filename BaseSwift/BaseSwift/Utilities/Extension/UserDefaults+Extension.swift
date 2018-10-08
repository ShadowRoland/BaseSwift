//
//  UIView+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation


let UserStandard = UserDefaults.standard

public extension UserDefaults {
    subscript(key: String) -> Any? {
        get {
            return object(forKey: key)
        }
        set (newValue) {
            if newValue == nil {
                removeObject(forKey: key)
            } else {
                set(newValue, forKey: key)
            }
        }
    }
}
