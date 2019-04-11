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

public class SRNavigationController: UINavigationController, UIGestureRecognizerDelegate, UINavigationBarDelegate {
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
        //SRNavigationController.swizzle()
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
    
    //MARK: - Orientations
    
    override public var shouldAutorotate: Bool {
        if let topViewController = topViewController {
            return topViewController.shouldAutorotate
        }
        return super.shouldAutorotate
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let topViewController = topViewController {
            return topViewController.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let topViewController = topViewController {
            return topViewController.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    //MARK: - Status Bar
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
    
    //MARK: - UINavigationBar swizzle
    
    static var swizzleFlag = true
    
    class func swizzle() {
        guard self == UINavigationController.self else { return }
        
        if swizzleFlag {
            swizzleFlag = false
            let needSwizzleSelectors = [
                NSSelectorFromString("_updateInteractiveTransition:"),
                #selector(popToViewController),
                #selector(popToRootViewController)
            ]
            
            for selector in needSwizzleSelectors {
                let str = ("sr_" + selector.description).replacingOccurrences(of: "__", with: "_")
                let originalMethod = class_getInstanceMethod(self, selector)
                let swizzledMethod = class_getInstanceMethod(self, Selector(str))
                if originalMethod != nil && swizzledMethod != nil {
                    method_exchangeImplementations(originalMethod!, swizzledMethod!)
                }
            }
        }
    }
    
    @objc func sr_updateInteractiveTransition(_ percentComplete: CGFloat) {
        guard let topViewController = topViewController,
            let coordinator = topViewController.transitionCoordinator else {
            sr_updateInteractiveTransition(percentComplete)
            return
        }
        
        let fromViewController = coordinator.viewController(forKey: .from)
        let toViewController = coordinator.viewController(forKey: .to)
        
        // Background Alpha
        let fromAlpha = fromViewController?.navigationBarBackgroundAlpha ?? 0
        let toAlpha = toViewController?.navigationBarBackgroundAlpha ?? 0
        let newAlpha = fromAlpha + (toAlpha - fromAlpha) * percentComplete
        
        setNeedsNavigationBackground(alpha: newAlpha)
        
        // Tint Color
        let fromColor = fromViewController?.navigationBarTintColor ?? .blue
        let toColor = toViewController?.navigationBarTintColor ?? .blue
        let newColor = averageColor(fromColor: fromColor, toColor: toColor, percent: percentComplete)
        navigationBar.tintColor = newColor
        sr_updateInteractiveTransition(percentComplete)
    }
    
    // Calculate the middle Color with translation percent
    private func averageColor(fromColor: UIColor, toColor: UIColor, percent: CGFloat) -> UIColor {
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        toColor.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let nowRed = fromRed + (toRed - fromRed) * percent
        let nowGreen = fromGreen + (toGreen - fromGreen) * percent
        let nowBlue = fromBlue + (toBlue - fromBlue) * percent
        let nowAlpha = fromAlpha + (toAlpha - fromAlpha) * percent
        
        return UIColor(red: nowRed, green: nowGreen, blue: nowBlue, alpha: nowAlpha)
    }
    
    @objc func sr_popToViewController(_ viewController: UIViewController,
                                      animated: Bool) -> [UIViewController]? {
        setNeedsNavigationBackground(alpha: viewController.navigationBarBackgroundAlpha)
        navigationBar.tintColor = viewController.navigationBarTintColor
        return sr_popToViewController(viewController, animated: animated)
    }
    
    @objc func sr_popToRootViewControllerAnimated(_ animated: Bool) -> [UIViewController]? {
        setNeedsNavigationBackground(alpha: viewControllers.first?.navigationBarBackgroundAlpha ?? 0)
        navigationBar.tintColor = viewControllers.first?.navigationBarTintColor
        return sr_popToRootViewControllerAnimated(animated)
    }
    
    //MARK: - UINavigationBarDelegate
    
    public func navigationBar(_ navigationBar: UINavigationBar,
                              shouldPop item: UINavigationItem) -> Bool {
        if let topVC = topViewController,
            let coordinator = topVC.transitionCoordinator,
            coordinator.initiallyInteractive {
            if #available(iOS 10.0, *) {
                coordinator.notifyWhenInteractionChanges({ (context) in
                    self.dealInteractionChanges(context)
                })
            } else {
                coordinator.notifyWhenInteractionEnds({ (context) in
                    self.dealInteractionChanges(context)
                })
            }
            return true
        }
        
        let itemCount = navigationBar.items?.count ?? 0
        let count = viewControllers.count >= itemCount ? 2 : 1
        let popToVC = viewControllers[viewControllers.count - count]
        
        popToViewController(popToVC, animated: true)
        return true
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar,
                              shouldPush item: UINavigationItem) -> Bool {
        setNeedsNavigationBackground(alpha: topViewController?.navigationBarBackgroundAlpha ?? 0)
        navigationBar.tintColor = topViewController?.navigationBarTintColor
        return true
    }
    
    fileprivate func dealInteractionChanges(_ context: UIViewControllerTransitionCoordinatorContext) {
        let animations: (UITransitionContextViewControllerKey) -> () = {
            let nowAlpha = context.viewController(forKey: $0)?.navigationBarBackgroundAlpha ?? 0
            self.setNeedsNavigationBackground(alpha: nowAlpha)
            
            self.navigationBar.tintColor = context.viewController(forKey: $0)?.navigationBarTintColor
        }
        
        if context.isCancelled {
            let cancelDuration: TimeInterval = context.transitionDuration * Double(context.percentComplete)
            UIView.animate(withDuration: cancelDuration) {
                animations(.from)
            }
        } else {
            let finishDuration: TimeInterval = context.transitionDuration * Double(1 - context.percentComplete)
            UIView.animate(withDuration: finishDuration) {
                animations(.to)
            }
        }
    }
}

extension UINavigationController {
    fileprivate func setNeedsNavigationBackground(alpha: CGFloat) {
        if let barBackgroundView = navigationBar.subviews.first {
            let valueForKey = barBackgroundView.value(forKey:)
            
            if let shadowView = valueForKey("_shadowView") as? UIView {
                shadowView.alpha = alpha
                shadowView.isHidden = alpha == 0
            }
            
            if navigationBar.isTranslucent {
                if #available(iOS 10.0, *) {
                    if let backgroundEffectView = valueForKey("_backgroundEffectView") as? UIView, navigationBar.backgroundImage(for: .default) == nil {
                        backgroundEffectView.alpha = alpha
                        return
                    }
                } else {
                    if let adaptiveBackdrop = valueForKey("_adaptiveBackdrop") as? UIView ,
                        let backdropEffectView = adaptiveBackdrop.value(forKey: "_backdropEffectView") as? UIView {
                        backdropEffectView.alpha = alpha
                        return
                    }
                }
            }
            
            barBackgroundView.alpha = alpha
        }
    }
}

extension UIViewController {
    fileprivate struct AssociatedKeys {
        static var navigationBarBackgroundAlpha = "UIViewController.navigationBarBackgroundAlpha"
        static var navigationBarTintColor = "UIViewController.navigationBarTintColor"
    }
    
    open var navigationBarBackgroundAlpha: CGFloat {
        get {
            guard let alpha = objc_getAssociatedObject(self, &AssociatedKeys.navigationBarBackgroundAlpha) as? CGFloat else {
                return 1.0
            }
            return alpha
        }
        set {
            let alpha = max(min(newValue, 1.0), 0)
            objc_setAssociatedObject(self, &AssociatedKeys.navigationBarBackgroundAlpha,
                                     alpha,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            navigationController?.setNeedsNavigationBackground(alpha: alpha)
        }
    }
    
    open var navigationBarTintColor: UIColor {
        get {
            guard let tintColor =
                objc_getAssociatedObject(self, &AssociatedKeys.navigationBarTintColor) as? UIColor else {
                return UIColor.white
            }
            return tintColor
        }
        set {
            navigationController?.navigationBar.tintColor = newValue
            objc_setAssociatedObject(self, &AssociatedKeys.navigationBarTintColor,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
