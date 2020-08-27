//
//  Common.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import Alamofire
import SDWebImage

class Common {
    //MARK: - Current User Information
    
    //推送的deviceToken
    private static var deviceToken = ""
    
    public static var currentDeviceToken: String {
        if deviceToken == "",
            let token = UserStandard[UDKey.currentDeviceToken] as? String {
            deviceToken = token
        }
        return deviceToken
    }
    
    public class func updateDeviceToken(_ deviceToken: String) {
        Common.deviceToken = deviceToken
        UserStandard[UDKey.currentDeviceToken] = deviceToken
    }
    
    //MARK: - Event
    
    public static var events: [Event] = []
    
    public class func removeEvent(_ event: Event?) {
        guard let event = event else { return }
        objc_sync_enter(events)
        Common.events = events.filter { $0.option != event.option }
        objc_sync_exit(events)
    }
    
    public class func removeEvent(option: Event.Option?) {
        guard let option = option else { return }
        objc_sync_enter(events)
        Common.events = events.filter { $0.option != option }
        objc_sync_exit(events)
    }
    
    public class func appendEvent(_ event: Event?, forced: Bool = true) {
        guard let event = event else { return }
        
        objc_sync_enter(events)
        if forced {
            events = events.filter { $0.option != event.option }
            events.append(event)
        } else if events.first(where: { $0.option == event.option }) == nil {
            events.append(event)
        }
        objc_sync_exit(events)
    }
    
    //MARK: - Business Feature
    
    static weak var rootVC: BaseViewController?
    
    //清除所有可能的弹出框、覆盖在keyWindow上的view和viewController
    public class func clearPops() {
        SRAlert.dismissAll() //自定义的弹出框
        SRAlertController.dismissAll() //系统弹出框
        SRShareTool.shared.dismiss(false)
    }
}

#if BASE_FRAMEWORK
#else
extension Common {
    class func clearForLogin(_ message: String? = nil) {
        guard let rootvC = Common.rootVC,
            let navigationController = rootvC.navigationController,
            !rootvC.isKind(of: LoginViewController.self) else {
                return
        }
        
        SRAlert.dismissAll() //自定义的弹出框
        SRAlertController.dismissAll() //系统弹出框
        SRShareTool.shared.dismiss(false) //分享
        
        if Config.entrance == .sns { //退出到登录页面
            //将modal出来的视图dismiss
            for vc in navigationController.viewControllers.reversed() {
                if vc.isKind(of: LoginViewController.self) {
                    break
                } else if let presentedViewController = vc.presentedViewController {
                    presentedViewController.dismiss(animated: false, completion: nil)
                }
            }
            rootvC.srPopBack(toClasses: [LoginViewController.self])
        } else if Config.entrance == .news { //在当前页面弹出登录页
            if let rootVC = Common.rootVC, rootVC.presentedViewController == nil {
                rootVC.srModal("LoginViewController", storyboard: "Profile")
            }
        }
        if let message = message {
            SRAlert.showToast(message)
        }
    }
}
#endif
