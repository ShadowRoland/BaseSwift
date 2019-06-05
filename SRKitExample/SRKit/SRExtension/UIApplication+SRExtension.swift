//
//  UIApplication+SRExtension.swift
//  SRKit
//
//  Created by Gary on 2019/6/1.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit

//MARK: Main thread guard

extension UIApplication {
    static var isMainThreadGuarded = false
    
    public static func mainThreadGuardSwizzleMethods() {
        guard !isMainThreadGuarded else { return }
        SRKit.methodSwizzling(UIApplication.self,
                              originalSelector: #selector(getter: UIApplication.keyWindow),
                              swizzledSelector: Selector(("mainThreadGuardKeyWindow")))
        SRKit.methodSwizzling(UIApplication.self,
                              originalSelector: #selector(getter: UIApplication.statusBarOrientation),
                              swizzledSelector: Selector(("mainThreadGuardStatusBarOrientation")))
        isMainThreadGuarded = true
    }
    
    var mainThreadGuardKeyWindow: UIWindow? {
        get {
            assert(Thread.isMainThread, "call UIApplication.keyWindow not in main thread")
            return self.mainThreadGuardKeyWindow
        }
    }
    
    var mainThreadGuardStatusBarOrientation: UIWindow? {
        get {
            assert(Thread.isMainThread, "call UIApplication.statusBarOrientation not in main thread")
            return self.mainThreadGuardStatusBarOrientation
        }
    }
}
