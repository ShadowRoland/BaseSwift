//
//  SRAlert.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/30.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

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
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    
    static var allAlerts: [SRAlert] = []
    
    class func append(_ alert: SRAlert) {
        if allAlerts.index(of: alert) == nil {
            allAlerts.append(alert)
        }
    }
    
    class func remove(_ alert: SRAlert) {
        if let index = allAlerts.index(of: alert) {
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
}
