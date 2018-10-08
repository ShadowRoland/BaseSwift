//
//  SRKeyboardManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/17.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit

//灰常简易的键盘管理
public final class SRKeyboardManager: NSObject {
    public weak var viewController: UIViewController?
    public weak var aboveKeyboardView: UIView?
    public var originViewFrame = CGRect()
    weak var textFieldView: UIView?
    var isAnimating = false
    var keyboardHideGr: UITapGestureRecognizer? //响应键盘消失的手势
    
    public class var shared: SRKeyboardManager {
        return sharedInstance
    }
    
    private static let sharedInstance = SRKeyboardManager()
    
    private override init() { }
    
    public var enable = false {
        didSet {
            //If not enable, enable it.
            if enable && !oldValue {// If not enabled, enable it.
                enableTextEditingNotification(enable: true)
            } else if !enable && oldValue {   //If not disable, desable it.
                enableTextEditingNotification(enable: false)
            }
        }
    }
    
    //MARK: - Keyboard
    
    public func riseView(_ duration: TimeInterval? = 0.5) {
        guard !isAnimating else { return }
        guard Keyboard.isVisible, let textFieldView = self.textFieldView else {
            fallView(duration)
            return
        }
        
        let window = viewController?.view.window
        let windowHeight = window?.bounds.size.height;
        var viewHeight =
            windowHeight! - (window?.convert(CGPoint(x: 0, y: textFieldView.bottom),
                                             from: textFieldView.superview).y)!
        if let aboveKeyboardView = self.aboveKeyboardView {
            let aboveViewHeight =
                windowHeight! - (window?.convert(CGPoint(x: 0, y: aboveKeyboardView.bottom),
                                                 from: aboveKeyboardView.superview).y)!
            viewHeight = min(viewHeight, aboveViewHeight)
        }
        let offset = originViewFrame.origin.y - (viewController?.view.frame.origin.y)!  //计算viewController?.view的已偏移量
        viewHeight -= offset //计算出原先的高度
        let riseHeight = Keyboard.keyboardHeight - (viewHeight - 2.0)
        if riseHeight > 0
            && viewController?.view.frame.origin.y != originViewFrame.origin.y - riseHeight {
            isAnimating = true
            UIView.animate(withDuration: duration!, animations: { [weak self] in
                self?.viewController?.view.frame =
                    (self?.originViewFrame.offsetBy(dx: 0, dy: -riseHeight))!
                }, completion: { [weak self] finished in
                    self?.isAnimating = false
                    self?.riseView(duration)
            })
        } else if riseHeight <= 0
            && viewController?.view.frame.origin.y != originViewFrame.origin.y {
            isAnimating = true
            UIView.animate(withDuration: duration!, animations: { [weak self] in
                self?.viewController?.view.frame = (self?.originViewFrame)!
            }) { [weak self] finished in
                self?.isAnimating = false
                self?.fallView(duration)
            }
        }
    }
    
    public func fallView(_ duration: TimeInterval? = 0.5) {
        guard !isAnimating
            && viewController?.view.frame.origin.y != originViewFrame.origin.y else {
                return
        }
        
        guard Keyboard.isVisible else {
            riseView(duration)
            return
        }
        
        isAnimating = true
        UIView.animate(withDuration: duration!, animations: { [weak self] in
            self?.viewController?.view.frame = (self?.originViewFrame)!
        }) { [weak self] finished in
            self?.isAnimating = false
            self?.fallView(duration)
        }
    }
    
    public func keyboardWillShow() {
        if let frame = viewController?.view.frame {
            originViewFrame = frame
        }
    }
    
    public func keyboardDidShow() {
        if keyboardHideGr == nil {
            keyboardHideGr = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        }
        UIApplication.shared.keyWindow?.addGestureRecognizer(keyboardHideGr!)
        riseView()
    }
    
    public func keyboardWillHide(_ duration: TimeInterval? = 0.5) {
        if let keyboardHideGr = self.keyboardHideGr {
            UIApplication.shared.keyWindow?.removeGestureRecognizer(keyboardHideGr)
        }
        fallView(duration)
    }
    
    @objc func hideKeyboard() {
        if textFieldView != nil {
            textFieldView?.resignFirstResponder()
        } else {
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder),
                                            to: nil,
                                            from: nil,
                                            for: nil)
        }
    }
    
    //MARK: - TextField & TextView Notification
    
    func enableTextEditingNotification(enable: Bool) {
        let center = NotificationCenter.default as NotificationCenter
        if enable {
            //Registering for textField notification.
            center.addObserver(self,
                               selector: #selector(textFieldViewDidBeginEditing(_:)),
                               name: .UITextViewTextDidBeginEditing,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(textFieldViewDidEndEditing(_:)),
                               name: .UITextViewTextDidEndEditing,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(textFieldViewDidBeginEditing(_:)),
                               name: .UITextFieldTextDidBeginEditing,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(textFieldViewDidEndEditing(_:)),
                               name: .UITextFieldTextDidEndEditing,
                               object: nil)
        } else {
            center.removeObserver(self,
                                  name: .UITextViewTextDidBeginEditing,
                                  object: nil)
            center.removeObserver(self,
                                  name: .UITextViewTextDidEndEditing,
                                  object: nil)
            center.removeObserver(self,
                                  name: .UITextFieldTextDidBeginEditing,
                                  object: nil)
            center.removeObserver(self,
                                  name: .UITextFieldTextDidEndEditing,
                                  object: nil)
        }
    }
    
    @objc func textFieldViewDidBeginEditing(_ notification: Notification) {
        //  Getting object
        textFieldView = notification.object as? UIView;
    }
    
    @objc func textFieldViewDidEndEditing(_ notification: Notification) {
        textFieldView = nil;
    }
}
