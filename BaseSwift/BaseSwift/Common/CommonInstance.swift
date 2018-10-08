//
//  CommonInstance.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Alamofire

let CommonShare: CommonInstance = CommonInstance.shared

public class CommonInstance: NSObject {
    var networkStatus: NetworkReachabilityManager.NetworkReachabilityStatus {
        return CommonInstance.networkMonitor!.networkReachabilityStatus
    }
    
    public class var shared: CommonInstance {
        return sharedInstance
    }
    
    private static let sharedInstance = CommonInstance()
    
    private override init() {
        super.init()
        startNetworkMonitor()
    }
    
    //MARK: Lock & unlock on views
    
    @objc func resetViewEnabled(_ timer: Timer) {
        if let view = timer.userInfo as? UIView {
            view.isUserInteractionEnabled = true
        }
    }
    
    public let maskButton = UIButton(type: UIButtonType.custom)
    
     @objc func resetButtonEnabled(_ timer: Timer) {
        if let maskButton = timer.userInfo as? UIButton {
            maskButton.removeFromSuperview()
        }
    }
    
    static private var touchHandling = false
    static private var touchHandleTimer: Timer?
    
    public func startTouchHandling() -> Bool {
        guard !CommonInstance.touchHandling else { return false }
        
        CommonInstance.touchHandling = true
        CommonInstance.touchHandleTimer?.invalidate()
        CommonInstance.touchHandleTimer =
            Timer.scheduledTimer(timeInterval: 0.2,
                                 target: self,
                                 selector: #selector(resetTouchHandling),
                                 userInfo: nil,
                                 repeats: false)
        return true
    }
    
    @objc func resetTouchHandling() {
        CommonInstance.touchHandling = false
    }
    
    //MARK: - Network monitor
    
    static private var networkMonitor: NetworkReachabilityManager?

    func startNetworkMonitor() {
        if CommonInstance.networkMonitor == nil {
            CommonInstance.networkMonitor = NetworkReachabilityManager()
            CommonInstance.networkMonitor?.stopListening()
        }
        CommonInstance.networkMonitor?.startListening()
    }
    
    /*
    //MARK: - Navigation Controller Handler
    
    fileprivate var navigartionHandlers: [NavigartionHandler] = []

    public func addNavigationController(_ navigationController: UINavigationController) {
        if nil != navigartionHandlers.first(where: {
            $0.navigationController === navigationController
        }) {
            return
        }
        
        let handler = NavigartionHandler()
        handler.navigationController = navigationController
        navigationController.delegate = handler
        navigartionHandlers.append(handler)
        cleanNavigartionHandlers()
    }
    
    func cleanNavigartionHandlers() {
        objc_sync_enter(navigartionHandlers)
        let array = navigartionHandlers.drop(while: { $0.navigationController == nil })
        if array.count < navigartionHandlers.count {
            navigartionHandlers = Array(array)
        }
        objc_sync_exit(navigartionHandlers)
    }
    
    //MARK: - Observer
    
    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        
    }
}

fileprivate class NavigartionHandler: NSObject, UINavigationControllerDelegate {
    weak var navigationController: UINavigationController?
    
    //public func navigationController(_ navigationController: UINavigationController,
    //                                 willShow viewController: UIViewController,
    //                                 animated: Bool) {
    //
    //}
    
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        //let viewControllers = navigationController.viewControllers
    }
 */
}
