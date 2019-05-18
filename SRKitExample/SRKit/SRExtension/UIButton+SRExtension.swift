//
//  UIButton+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/29.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
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

//MARK: Submit button

public extension UIButton {
    //获取一个默认格式的提交按钮，类似于登录的大按钮
    convenience init(submit title: String,
                     normalColor: UIColor? = nil,
                     highlightedColor: UIColor? = nil) {
        self.init(type: .custom)
        frame = SubmitButton.frame
        layer.cornerRadius = SubmitButton.cornerRadius
        clipsToBounds = true
        titleColor = SubmitButton.titleColor
        titleFont = SubmitButton.font
        self.title = title
        if let normalColor = normalColor {
            setBackgroundImage(UIImage.rect(normalColor, size: bounds.size),
                               for: .normal)
            if let highlightedColor = highlightedColor {
                setBackgroundImage(UIImage.rect(highlightedColor, size: bounds.size),
                                   for: .highlighted)
            } else {
                setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                                size: bounds.size),
                                   for: .highlighted)
            }
        } else {
            setSubmitDefaultBackgroundColor()
        }
    }
    
    //改变提交按钮的样式，如果按钮没有设置BackgroundImage，将提供默认的样式
    //原因是若只设置了按钮的BackgroundColor的话，将没有点击效果的样式
    func set(submit enabled: Bool,
             normalColor: UIColor? = nil,
             highlightedColor: UIColor? = nil) {
        if currentBackgroundImage == nil {
            if let normalColor = normalColor {
                setBackgroundImage(UIImage.rect(normalColor, size: bounds.size),
                                   for: .normal)
                if let highlightedColor = highlightedColor {
                    setBackgroundImage(UIImage.rect(highlightedColor,
                                                    size: bounds.size),
                                       for: .highlighted)
                } else {
                    setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                                    size: bounds.size),
                                       for: .highlighted)
                }
            } else {
                setSubmitDefaultBackgroundColor()
            }
        }
        isEnabled = enabled
    }
    
    func setSubmitDefaultBackgroundColor() {
        setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorNormal,
                                        size: bounds.size),
                           for: .normal)
        setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                        size: bounds.size),
                           for: .highlighted)
        backgroundColor = .clear
    }
}
