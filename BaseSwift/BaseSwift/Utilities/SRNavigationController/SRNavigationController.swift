//
//  SRNavigationController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import REMenu
import SwiftyJSON

public class SRNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    public var panEnable = false {
        didSet {
            if panEnable != oldValue {
                let gr = interactivePopGestureRecognizer
                if panEnable {
                    gr?.view?.addGestureRecognizer(panRecognizer!)
                } else {
                    gr?.view?.removeGestureRecognizer(panRecognizer!)
                }
            }
        }
    }
    
    public var longPressEnable = false {
        didSet {
            if longPressEnable != oldValue && longPressRecognizer != nil {
                let gr = interactivePopGestureRecognizer
                if longPressEnable {
                    gr?.view?.addGestureRecognizer(longPressRecognizer)
                } else {
                    gr?.view?.removeGestureRecognizer(longPressRecognizer)
                }
            }
        }
    }
    
    /**
     *  滑动退出页面的手势
     *  注意，该手势与UITableViewCell的左滑冲突，会覆盖掉UITableViewCell的左滑操作
     *  如果页面中有UITableViewCell需要左滑的动作，需要禁止该手势
     */
    var panRecognizer: UIPanGestureRecognizer!
    
    /**
     *  长按导航栏或者页面的手势
     */
    var longPressRecognizer: UILongPressGestureRecognizer!
    var debugMenu: REMenu!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        //CommonShare.addNavigationController(self)
        initPopRecognizer()
        if RunInEnvironment != RunEnvironment.production {
            initDebugMenu()
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 9.0, *) {
            
        } else {
            navigationBar.srLayout()
        }
    }

    deinit {
        //CommonShare.cleanNavigartionHandlers()
    }
    
    func initPopRecognizer() {
        panRecognizer = UIPanGestureRecognizer()
        panRecognizer.delegate = self
        panRecognizer.maximumNumberOfTouches = 1;
        
        let gesture = interactivePopGestureRecognizer
        let targets = gesture?.value(forKey: "_targets") as? Array<AnyObject>
        let gestureRecognizerTarget = targets?.first as AnyObject
        let navigationInteractiveTransition = gestureRecognizerTarget.value(forKey: "_target")
        let handleTransition = NSSelectorFromString("handleNavigationTransition:") as Selector;
        panRecognizer.addTarget(navigationInteractiveTransition!, action: handleTransition)
    }
    
    func initDebugMenu() {
        let serverConfigItem = REMenuItem(title: "服务器配置",
                                          subtitle: "展示或修改当前的服务器配置",
                                          image: nil,
                                          highlightedImage: nil,
                                          action:
            { [weak self] (item) -> Void in
                DispatchQueue.main.asyncAfter(deadline: .now() + PerformDelay,
                                              execute:
                    { [weak self] in
                        let vc = Common.viewController("ServerConfigViewController",
                                                       storyboard: "Utility")
                        let navVC = SRModalViewController.standard(vc)
                        self?.present(navVC, animated: true, completion: nil)
                })
        })
        
        let httpServerItem = REMenuItem(title: "Local Http Server",
                                        subtitle: "查看手机内置的Web Server",
                                        image: nil,
                                        highlightedImage: nil,
                                        action:
            { [weak self] (item) -> Void in
                DispatchQueue.main.asyncAfter(deadline: .now() + PerformDelay,
                                              execute:
                    { [weak self] in
                        let vc = Common.viewController("HttpServerViewController",
                                                       storyboard: "Utility")
                        self?.present(vc, animated: true, completion: nil)
                })
        })
        
        let debugToolsItem = REMenuItem(title: "Debug Tools",
                                        subtitle: "定制的调试工具",
                                        image: nil,
                                        highlightedImage: nil,
                                        action:
            { [weak self] (item) -> Void in
                DispatchQueue.main.asyncAfter(deadline: .now() + PerformDelay,
                                              execute:
                    { [weak self] in
                        let vc = Common.viewController("DebugViewController",
                                                       storyboard: "Utility")
                        let navVC = SRModalViewController.standard(vc)
                        self?.present(navVC, animated: true, completion: nil)
                })
        })
        
        let copyUrlItem = REMenuItem(title: "展示并复制已登录的用户信息",
                                     subtitle: "展示当前已登录的用户信息并复制到系统剪贴板",
                                     image: nil,
                                     highlightedImage: nil,
                                     action:
            { [weak self] (item) -> Void in
                guard self != nil else { return }
                
                if Common.isLogin() {
                    let text = Common.currentProfile()?.toJSONString() ?? EmptyString
                    let alert = SRAlertController(title: nil,
                                                  message: text,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel".localized,
                                                  style: .cancel,
                                                  handler:nil))
                    self?.present(alert, animated: true, completion: nil)
                    UIPasteboard.general.string = text
                } else {
                    let alert = SRAlertController(title: nil,
                                                  message: "未登录",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel".localized,
                                                  style: .cancel,
                                                  handler:nil))
                    self?.present(alert, animated: true, completion: nil)
                }
        })
        debugMenu = REMenu(items: [serverConfigItem!,
                                   httpServerItem!,
                                   debugToolsItem!,
                                   copyUrlItem!])
        debugMenu.textColor = UIColor.white
        debugMenu.font = UIFont.title
        
        longPressRecognizer =
            UILongPressGestureRecognizer(target: self,
                                         action: #selector(handleLongPressed))
        navigationBar.addGestureRecognizer(longPressRecognizer)
    }
    
    @objc func handleLongPressed() {
        guard !debugMenu.isOpen
            && !debugMenu.isAnimating
            && (viewControllers.first { $0.isKind(of: ServerConfigViewController.self) } == nil) else {
                return
        }
        
        let httpServerItem = debugMenu.items[1] as! REMenuItem
        httpServerItem.title =
            "Local Http Server (" + (SRHttpServer.shared.isRunning ? "Opening" : "Closed") + ")"
        
        let originY =
            isNavigationBarHidden ? StatusBarHeight : NavigationBarHeight + StatusBarHeight
        debugMenu.show(from: CGRect(0, originY, ScreenWidth(), ScreenHeight()),
                       in: UIApplication.shared.keyWindow)
    }
    
    //MARK: Orientations
    
    override public var shouldAutorotate: Bool {
        if let last = viewControllers.last {
            return last.shouldAutorotate
        }
        return super.shouldAutorotate
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let last = viewControllers.last {
            return last.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let last = viewControllers.last {
            return last.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }
}



