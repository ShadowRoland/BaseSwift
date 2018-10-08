//
//  UIButton+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/29.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension UIButton {
    var title: String? {
        get {
            return title(for: .normal)
        }
        set {
            setTitle(newValue, for: .normal)
        }
    }
    
    var titleColor: UIColor? {
        get {
            return titleColor(for: .normal)
        }
        set {
            setTitleColor(newValue, for: .normal)
        }
    }
    
    var titleFont: UIFont? {
        get {
            if let titleLabel = titleLabel {
                return titleLabel.font
            }
            return nil
        }
        set {
            if let font = newValue {
                titleLabel?.font = font
            }
        }
    }
    
    var image: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }
    
    var backgroundImage: UIImage? {
        get {
            return backgroundImage(for: .normal)
        }
        set {
            setBackgroundImage(newValue, for: .normal)
        }
    }
    
    func clicked(_ target: Any?, action: Selector) {
        addTarget(target, action: action, for: .touchUpInside)
    }
}
