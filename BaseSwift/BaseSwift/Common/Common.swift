//
//  Common.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

public class Common: BaseCommon {
    
    //MARK: - Runing Environment

    public class func httpsCer(_ isServer: Bool) -> Data? {
        let cerPrefix = isServer ? "server_" : "client_"
        var cerFileName = cerPrefix + "develop.cer"
        if RunInEnvironment == RunEnvironment.test {
            cerFileName = cerPrefix + "test.cer"
        } else if RunInEnvironment == RunEnvironment.production {
            cerFileName = cerPrefix + "production.cer"
        }
        let filePath = "cer" + cerFileName
        let cerFilePath = ResourceDirectory.appending(pathComponent: filePath)
        let cerData: Data? = try! Data(contentsOf: URL(fileURLWithPath: cerFilePath))
        return cerData
    }
    
    //MARK: - Current User Information
    
    private static var profile: ProfileModel?
    
    public class func currentProfile() -> ProfileModel? {
        return profile
    }
    
    public class func updateCurrentProfile(_ profile: ProfileModel?) {
        Common.profile = profile
    }
    
    public class func isLogin() -> Bool {
        if let profile = Common.currentProfile() {
            return profile.isLogin
        }
        return false
    }
    
    //MARK: - Action
    
    private static var actionParams: ParamDictionary?
    
    public class var currentActionParams: ParamDictionary? {
        return actionParams
    }
    
    public class func updateActionParams(_ actionParams: ParamDictionary?) {
        Common.actionParams = actionParams
    }
    
    //清空指令
    public class func clearActionParams(_ event: Int) {
        clearActionParams(option: Event.Option(rawValue: event))
    }
    
    //清空指令
    public class func clearActionParams(option: Event.Option?) {
        if let option = option,
            let string = actionParams?[ParamKey.action] as? String,
            let action = Event.Action(rawValue: string),
            Event.actions(option).contains(action) {
            Common.updateActionParams(nil)
        }
    }
    
    //MARK: - Business Feature
    
    static weak var rootVC: BaseViewController?

    //清除所有可能的弹出框、覆盖在keyWindow上的view和viewController
    public class func clearPops() {
        SRAlert.dismissAll() //自定义的弹出框
        SRAlertController.dismissAll() //系统弹出框
        SRShareTool.shared.dismiss(false)
    }
    
    //清除所有modal出来的viewController
    public class func clearModals() {
        guard let rootvC = Common.rootVC else {
            return
        }
        clearModals(viewController: rootvC)
    }
    
    public class func clearModals(viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else {
            return
        }
        
        navigationController.viewControllers.reversed().forEach {
            if let presentedViewController = $0.presentedViewController {
                Common.clearModals(viewController: presentedViewController)
                if let modalVC = presentedViewController as? SRModalViewController {
                    modalVC.dismiss(animated: false, completion:modalVC.completionHandler)
                } else {
                    $0.presentedViewController?.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    public class func clearForLogin(_ message: String? = nil) {
        guard let rootvC = Common.rootVC,
            let navigationController = rootvC.navigationController,
            !rootvC.isKind(of: LoginViewController.self) else {
                return
        }
        
        SRAlert.dismissAll() //自定义的弹出框
        SRAlertController.dismissAll() //系统弹出框
        SRShareTool.shared.dismiss(false) //分享
        
        if Configs.entrance == .sns { //退出到登录页面
            //将modal出来的视图dismiss
            for vc in navigationController.viewControllers.reversed() {
                if vc.isKind(of: LoginViewController.self) {
                    break
                } else if let presentedViewController = vc.presentedViewController {
                    presentedViewController.dismiss(animated: false, completion: nil)
                }
            }
            rootvC.popBack(toClasses: [LoginViewController.self])
        } else if Configs.entrance == .news { //在当前页面弹出登录页
            if let rootVC = Common.rootVC, rootVC.presentedViewController == nil {
                let vc = Common.viewController("LoginViewController", storyboard: "Profile")
                let navVC = SRModalViewController.standard(vc)
                rootVC.present(navVC, animated: true, completion: nil)
            }
        }
        if let message = message {
            Common.showToast(message)
        }
    }
}
