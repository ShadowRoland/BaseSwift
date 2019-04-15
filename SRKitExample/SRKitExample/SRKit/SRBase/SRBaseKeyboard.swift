//
//  SRBaseKeyboard.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/17.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import IQKeyboardManagerSwift

let Keyboard = SRBaseKeyboard.shared

final class SRBaseKeyboard: NSObject {
    enum Manager: Int {//键盘管理使用类型
        case iq     = 0,//使用IQKeyboardManager
        sr,//使用SRKeyboardManager
        unable//不使用键盘管理捕捉，多用于网页或者自定义控制键盘事件
    }
    
    var manager = Manager.iq {
        didSet {
            let center = NotificationCenter.default as NotificationCenter
            if .iq == manager {
                IQKeyboardManager.shared.enable = true
                SRKeyboardManager.shared.enable = false
                center.removeObserver(self,
                                      name: UIResponder.keyboardWillChangeFrameNotification,
                                      object: nil)
            } else if .sr == manager {
                IQKeyboardManager.shared.enable = false
                SRKeyboardManager.shared.enable = true
                center.addObserver(self,
                                   selector: #selector(keyboardWillChangeFrame(_:)),
                                   name: UIResponder.keyboardWillChangeFrameNotification,
                                   object: nil)
            } else {
                IQKeyboardManager.shared.enable = false
                SRKeyboardManager.shared.enable = false
                center.removeObserver(self,
                                      name: UIResponder.keyboardWillChangeFrameNotification,
                                      object: nil)
            }
        }
    }
    
    private(set) var isVisible = false
    private(set) var keyboardHeight: CGFloat = 0
    fileprivate var keyboadDidHideBlock: (() -> Void)?
    
    public class var shared: SRBaseKeyboard {
        if sharedInstance == nil {
            sharedInstance = SRBaseKeyboard()
            let center = NotificationCenter.default as NotificationCenter
            center.addObserver(sharedInstance!,
                               selector: #selector(keyboardWillShow),
                               name: UIResponder.keyboardWillShowNotification,
                               object: nil)
            center.addObserver(sharedInstance!,
                               selector: #selector(keyboardDidShow),
                               name: UIResponder.keyboardDidShowNotification,
                               object: nil)
            center.addObserver(sharedInstance!,
                               selector: #selector(keyboardWillHide(_:)),
                               name: UIResponder.keyboardWillHideNotification,
                               object: nil)
            center.addObserver(sharedInstance!,
                               selector: #selector(keyboardDidHide),
                               name: UIResponder.keyboardDidHideNotification,
                               object: nil)
            center.addObserver(sharedInstance!,
                               selector: #selector(keyboardWillChangeFrame(_:)),
                               name: UIResponder.keyboardWillChangeFrameNotification,
                               object: nil)
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: SRBaseKeyboard?
    
    private override init() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.shouldToolbarUsesTextFieldTintColor = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        super.init()
    }
    
    //隐藏虚拟键盘
    func hide(_ didHideBlock: (() -> Void)? = nil) {
        if !isVisible {
            didHideBlock?()
        } else {
            keyboadDidHideBlock = didHideBlock
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder),
                                            to: nil,
                                            from: nil,
                                            for: nil)
        }
    }
    
    //MARK: - Keyboard Notification
    
    @objc func keyboardWillShow() {
        if .sr == manager {
            SRKeyboardManager.shared.keyboardWillShow()
        }
    }
    
    @objc func keyboardDidShow() {
        isVisible = true
        if .sr == manager {
            SRKeyboardManager.shared.keyboardDidShow()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if .sr == manager {
            if let userInfo = notification.userInfo {
                let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
                SRKeyboardManager.shared.keyboardWillHide(duration)
            }
        }
    }
    
    @objc func keyboardDidHide() {
        isVisible = false
        if let keyboadDidHideBlock = keyboadDidHideBlock {
            keyboadDidHideBlock()
        }
        keyboadDidHideBlock = nil
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let frame = frameValue.cgRectValue
                keyboardHeight = frame.size.height
                if .sr == manager && isVisible {
                    let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
                    SRKeyboardManager.shared.riseView(duration)
                }
            }
        }
    }
}
