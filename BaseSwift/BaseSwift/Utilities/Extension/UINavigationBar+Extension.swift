//
//  UINavigationBar+Extension.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/9.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

public extension UINavigationBar {
    fileprivate static let runtimeKeyOverlay = UnsafeRawPointer(bitPattern: "overlay".hashValue)!
    var overlay: UIView {
        if let overlay = objc_getAssociatedObject(self, UINavigationBar.runtimeKeyOverlay)
            as? UIView {
            return overlay
        }
        
        let overlay = UIView()
        overlay.isUserInteractionEnabled = false
        overlay.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        addSubview(overlay)
        objc_setAssociatedObject(self,
                                 UINavigationBar.runtimeKeyOverlay,
                                 overlay,
                                 .OBJC_ASSOCIATION_RETAIN)
        return overlay
    }
    
    var srBackgroundColor: UIColor? {
        get { return overlay.backgroundColor }
        set { overlay.backgroundColor = newValue }
    }
    
    func srLayout() {
        bringSubview(toFront: overlay)
    }
}
