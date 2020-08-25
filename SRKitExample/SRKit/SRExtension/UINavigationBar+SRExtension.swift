//
//  UINavigationBar+SRExtension.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/9.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

public extension UINavigationBar {
    fileprivate struct AssociatedKeys {
        static var overlay = "UINavigationBar.overlay"
    }
    
    var overlay: UIView {
        get {
            if let overlay = objc_getAssociatedObject(self, &AssociatedKeys.overlay)
                as? UIView {
                return overlay
            }
            
            let overlay = UIView()
            overlay.isUserInteractionEnabled = false
            overlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            addSubview(overlay)
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.overlay,
                                     overlay,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return overlay
        }
        set {
            let overlay = newValue
            overlay.isUserInteractionEnabled = false
            overlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            addSubview(overlay)
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.overlay,
                                     overlay,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var srBackgroundColor: UIColor? {
        get { return overlay.backgroundColor }
        set { overlay.backgroundColor = newValue }
    }
    
    func srLayout() {
        bringSubviewToFront(overlay)
    }
}
