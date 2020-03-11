//
//  SRAlert.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/30.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import SCLAlertView
import Toast

public enum AlertType {
    case success
    case error
    case notice
    case warning
    case info
    case edit
    case wait
}

open class SRAlert: SCLAlertView {
    #if DEBUG
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    #endif

    static var allAlerts: [SRAlert] = []
    
    class func append(_ alert: SRAlert) {
        if allAlerts.firstIndex(of: alert) == nil {
            allAlerts.append(alert)
        }
    }
    
    class func remove(_ alert: SRAlert) {
        if let index = allAlerts.firstIndex(of: alert) {
            allAlerts.remove(at: index)
        }
    }
    
    open class func dismissAll() {
        Array<SRAlert>(allAlerts).forEach {
            $0.dismiss(animated: false, completion: nil)
            remove($0)
        }
    }
    
    open func show(_ type: AlertType,
                   title: String,
                   message: String,
                   closeButtonTitle: String? = nil) {
        switch type {
        case .success:
            showSuccess(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .error:
            showError(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .notice:
            showNotice(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .warning:
            showWarning(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .info:
            showInfo(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .edit:
            showEdit(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        case .wait:
            showWait(title, subTitle: message, closeButtonTitle: closeButtonTitle)
        }
    }
    
    open override func hideView() {
        super.hideView()
        SRAlert.remove(self)
    }
    
    override open func showTitle(_ title: String,
                                 subTitle: String,
                                 style: SCLAlertViewStyle,
                                 closeButtonTitle: String?,
                                 timeout: SCLAlertView.SCLTimeoutConfiguration?,
                                 colorStyle: UInt?,
                                 colorTextButton: UInt,
                                 circleIconImage: UIImage?,
                                 animationStyle: SCLAnimationStyle) -> SCLAlertViewResponder {
        SRAlert.append(self)
        return super.showTitle(title,
                               subTitle: subTitle,
                               style: style,
                               closeButtonTitle: closeButtonTitle,
                               timeout: timeout,
                               colorStyle: colorStyle,
                               colorTextButton: colorTextButton,
                               circleIconImage: circleIconImage,
                               animationStyle: animationStyle)
    }
    
    @discardableResult
    public class func show(_ title: String? = nil,
                           message: String? = nil,
                           type: AlertType = .info) -> SRAlert? {
        let str1 = NonNull.string(title)
        let str2 = NonNull.string(message)
        if str1 == "" && str2 == "" {
            LogWarn("the parameter 'title' and 'message' of SRCommon.showAlert are all empty")
            return nil
        }
        
        let alert = SRAlert()
        Keyboard.hide {
            alert.show(type, title: str1, message: str2, closeButtonTitle: "[SR]OK".srLocalized)
        }
        return alert
    }
    
    @discardableResult
    public class func showToast(_ message: String?,
                                in view: UIView = UIApplication.shared.keyWindow!,
                                duration: TimeInterval = 2.0) -> Bool {
        guard !isEmptyString(message) else { return false }
        
        var positionInWindow: CGPoint!
        if Keyboard.isVisible {
            let keyboardHeight = Keyboard.keyboardHeight + 5.0
            if keyboardHeight <= ScreenHeight / 2.0 {
                positionInWindow = CGPoint(x: ScreenWidth / 2.0, y: ScreenHeight / 2.0)
            } else {
                positionInWindow = CGPoint(x: ScreenWidth / 2.0,
                                           y: ScreenHeight - C.toastHeightAboveBottom)
            }
        } else {
            positionInWindow = CGPoint(x: ScreenWidth / 2.0,
                                       y: ScreenHeight - C.toastHeightAboveBottom)
        }
        view.makeToast(message!,
                       duration: duration,
                       position: view.convert(positionInWindow, from: view.window))
        return true
    }
}
