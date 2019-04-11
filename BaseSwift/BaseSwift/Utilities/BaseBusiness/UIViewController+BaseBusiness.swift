//
//  UIViewController+BaseBusiness.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC
import SwiftyJSON
import SDWebImage
import DTCoreText

//MARK: - Extension Features

extension UIViewController {
    
    //MARK: - Autorotate Orientation
    
    public func guardDeviceOrientationDidChange(_ sender: AnyObject?) -> Bool {
        if sender == nil { return true } //强制调用，一般用于初始化或者强制重新布局
        
        if !self.shouldAutorotate { //当前视图控制器不支持屏幕切换，不需要重新布局
            return false
        }
        
        //接受了通知，并且支持屏幕切换
        let deviceOrientation = UIDevice.current.orientation;
        
        //当前设备为纵向，并且所支持的方向也包含纵向，可以重新布局
        if deviceOrientation.isPortrait && supportedInterfaceOrientations.contains(.portrait) {
            return true
        }
        
        //当前设备为横向，并且所支持的方向也包含横向，可以重新布局
        if deviceOrientation.isLandscape && supportedInterfaceOrientations.contains(.landscape) {
            return true
        }
        
        return false
    }
    
    //MARK: - Navigator
    
    var isModalRootViewController: Bool {
        if let vc = navigationController as? SRModalViewController,
            vc.viewControllers.count > 1,
            self === vc.viewControllers[1] {
            return true
        } else {
            return false
        }
    }
    
    public func show(_ identifier: String,
                     storyboard: String,
                     animated: Bool = true,
                     params: ParamDictionary? = nil) {
        show(Common.viewController(identifier, storyboard: storyboard),
             animated: animated,
             params: params)
    }
    
    public func show(_ viewController: UIViewController,
                     animated: Bool = true,
                     params: ParamDictionary? = nil) {
        guard navigationController != nil else { return }
        
        if let params = params {
            viewController.params = params
        }
        Keyboard.hide { [weak self] in
            self?.navigationController?.pushViewController(viewController, animated: animated)
        }
    }
    
    public func popBack(_ animated: Bool = true) {
        guard navigationController != nil else { return }
        
        //Keyboard.hide { [weak self] in
        if isModalRootViewController {
            (navigationController as! SRModalViewController).dismiss(animated)
            return
        }
        
        navigationController?.popViewController(animated: animated)
    }
    
    //返回到指定类的ViewController，参数toClasses为指定类的数组，按照优先级排列
    @discardableResult
    public func popBack(toClasses: [AnyClass],
                        animated: Bool = true,
                        clear: Bool = true) -> UIViewController? {
        guard let navigationController = navigationController else { return nil }
        
        if let viewController = navigationController.viewControllers.last(where: { vc in
            toClasses.first { vc.isKind(of: $0) } != nil
        }) {
            popBack(to: viewController, animated: animated, clear: clear)
            return viewController
        }
        
        return nil
    }
    
    //返回到指定的ViewController
    public func popBack(to: UIViewController,
                        animated: Bool = true,
                        clear: Bool = true) {
        guard let navigationController = navigationController else { return }
        
        if clear {
            let reversed = navigationController.viewControllers.reversed()
            let array = reversed.prefix(while: { $0 !== to })
            if array.count != reversed.count {
                array.forEach { $0.presentedViewController?.dismiss(animated: false, completion: nil) }
            }
        }
        
        navigationController.popToViewController(to, animated: animated)
    }
    
    //本视图是否展现在最前面
    public var isFront: Bool {
        //guard let navigationController = navigationController else { return false }
        //return self === navigationController.topViewController
        //    && presentedViewController == nil
        //    && navigationController.presentedViewController == nil
        let frontVC = Common.frontVC()
        if self === frontVC {
            return true
        } else if let vc = frontVC as? UINavigationController,
            self === vc.topViewController {
            return true
        } else {
            return false
        }
    }
    
    //防止页面加载成功但是导航栏没有同步，限定在viewDidAppear使用
    public func ensureNavigationBarHidden(_ isHidden: Bool) {
        if let navigationController = navigationController,
            navigationController.topViewController === self
            && navigationController.navigationBar.topItem != self.navigationItem {
                navigationController.setNavigationBarHidden(!isHidden, animated: false)
                navigationController.setNavigationBarHidden(isHidden, animated: false)
        }
    }
    
    //MARK: - Common Features
    
    public func showToast(_ message: String?) {
        if Common.showToast(message, view) {
            Common.unableTimed(view)
        }
    }
    
    public func showWebpage(_ url: URL,
                            title: String? = nil,
                            params: ParamDictionary? = [:]) {
        var dictionary: ParamDictionary = ["url" : url]
        if let title = title {
            dictionary["title"] = title
        }
        if let params = params {
            dictionary += params
        }
        self.show("WebpageViewController", storyboard: "Utility", params: dictionary)
    }
}

