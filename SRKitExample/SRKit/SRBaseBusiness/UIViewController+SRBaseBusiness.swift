//
//  UIViewController+SRBaseBusiness.swift
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

extension UIViewController {
    public class SRBaseBusinessComponent: NSObject, UIGestureRecognizerDelegate {
        public weak var decorator: UIViewController?
        
        public lazy var navigationBarBackgroundView: UIView = {
            let view = UIView(frame: CGRect(0, 0, ScreenWidth, NavigationBarHeight))
            decorator?.view.addSubview(view)
            view.backgroundColor = NavigationBar.backgroundColor
            return view
        }()
        public var navigationBackgroundAlpha = 0.5 as CGFloat
        
        fileprivate struct AssociatedKeys {
            static var baseBusiness = "UIViewController.SRBaseBusinessComponent.baseBusiness"
        }
        
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        
        public var isViewDidAppear = false   //进入页面时初始的操作是否已被执行
        public var isNavigationBarButtonsActive = false   //decorator的导航栏按钮是否有效
        
        public var needShowProgress = false   //延迟显示progress的判断依据
        public var progressMaskType: UIView.SRProgressComponent.MaskType! //延迟显示progress的maskType
        public lazy var progressContainerView: UIView = UIView()
        
        //MARK: Load Data Fail
        
        public var loadDataFailRetryMethod: HTTP.Method?//请求数据失败时显示点击重试的请求，一般是 页面刚进入发出的第一个http请求
        public var loadDataFailRetryHandler: (() -> Void)?  //请求数据失败时点击重试的操作
        public lazy var loadDataFailContainerView: UIView = UIView()
        public var loadDataFailView: SRLoadDataStateView?
        
        public var isShowingLoadDataFailView: Bool {
            return loadDataFailView != nil && loadDataFailView!.superview != nil
        }
        
        public func showLoadDataFailView(_ inView: UIView, text: String?) {
            if loadDataFailView == nil {
                loadDataFailView = SRLoadDataStateView(.fail)
            }
            dismissLoadDataFailView()
            loadDataFailView?.show(inView, text: text)
        }
        
        public func resetLoadDataFailViewPosition() {
            loadDataFailView?.show(loadDataFailView!.superview!, text: loadDataFailView!.text)
        }
        
        public func dismissLoadDataFailView() {
            loadDataFailView?.removeFromSuperview()
        }
        
        //MARK: Navigation Bar Appear
        
        public var navigartionBarAppear: NavigationBar.Appear = .visible {
            didSet {
                if let navigationController = decorator?.navigationController,
                    isViewDidAppear,
                    oldValue != navigartionBarAppear {
                    switch navigartionBarAppear {
                    case .visible:
                        navigationController.isNavigationBarHidden = false
                        navigationBarBackgroundView.isHidden = false
                    case .hidden:
                        navigationController.isNavigationBarHidden = true
                        navigationBarBackgroundView.isHidden = true
                    default: break
                    }
                } else {
                    navigationBarBackgroundView.isHidden = false
                }
            }
        }
        
        //MARK: Gesture
        
        public struct PageBackGestureStyle : OptionSet {
            private(set) public var rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            public static var none = PageBackGestureStyle(rawValue: 0)
            
            public static var page = PageBackGestureStyle(rawValue: 1)
            
            public static var edge = PageBackGestureStyle(rawValue: 2)
        }
        
        public var pageBackGestureStyle: PageBackGestureStyle = .page {
            didSet {
                if let decorator = decorator, decorator.isModalRootViewController {
                    if let vc = decorator.navigationController as? SRNavigationController {
                        vc.isPageSwipeEnabled = false
                        vc.interactivePopGestureRecognizer?.isEnabled = false
                    }
                    return
                }
                
                if pageBackGestureStyle.contains(.page) {
                    if let vc = decorator?.navigationController as? SRNavigationController {
                        vc.isPageSwipeEnabled = true
                    }
                    //} else {
                    //    if let vc = decorator?.navigationController as? SRNavigationController {
                    //        vc.isPageSwipeEnabled = false
                    //        if pageBackGestureStyle.contains(.edge) {
                    //            vc.interactivePopGestureRecognizer?.isEnabled = true
                    //        } else {
                    //            vc.interactivePopGestureRecognizer?.isEnabled = false
                    //        }
                    //    }
                }
            }
        }
        
        public var isPageLongPressEnabled = false {
            didSet {
                guard Environment != .production else { return }
                if let vc = decorator?.navigationController as? SRNavigationController {
                    vc.isNavPageLongPressEnabled = isPageLongPressEnabled
                }
            }
        }
        
        //MARK: Params
        
        fileprivate var params = [:] as ParamDictionary
        
        //MARK: State machine
        
        fileprivate var stateMachine = SRStateMachine()
        
        //MARK: Event
        
        fileprivate var event: Event? = nil
        
        //MARK: 3D Touch
        
        fileprivate var isPreviewed = false
    }
}

public extension UIViewController {
     var baseBusinessComponent: SRBaseBusinessComponent {
        if let component =
            objc_getAssociatedObject(self, &SRBaseBusinessComponent.AssociatedKeys.baseBusiness)
                as? SRBaseBusinessComponent {
            return component
        }
        
        let component = SRBaseBusinessComponent()
        component.decorator = self
        objc_setAssociatedObject(self,
                                 &SRBaseBusinessComponent.AssociatedKeys.baseBusiness,
                                 component,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return component
    }
    
    var params: ParamDictionary {
        get {
            return baseBusinessComponent.params
        }
        set {
            baseBusinessComponent.params = newValue
        }
    }
    
    var stateMachine: SRStateMachine {
        return baseBusinessComponent.stateMachine
    }
    
    var event: Event? {
        get {
            return baseBusinessComponent.event
        }
        set {
            baseBusinessComponent.event = event
        }
    }
    
    var isPreviewed: Bool {
        get {
            return baseBusinessComponent.isPreviewed
        }
        set {
            baseBusinessComponent.isPreviewed = newValue
        }
    }
    
    var navigartionBarAppear: NavigationBar.Appear {
        get {
            return baseBusinessComponent.navigartionBarAppear
        }
        set {
            baseBusinessComponent.navigartionBarAppear = newValue
        }
    }
    
    var pageBackGestureStyle: SRBaseBusinessComponent.PageBackGestureStyle {
        get {
            return baseBusinessComponent.pageBackGestureStyle
        }
        set {
            baseBusinessComponent.pageBackGestureStyle = newValue
        }
    }
    
    var isPageLongPressEnabled: Bool {
        get {
            return baseBusinessComponent.isPageLongPressEnabled
        }
        set {
            baseBusinessComponent.isPageLongPressEnabled = newValue
        }
    }
}

public extension UIViewController {
    class func viewController(_ identifier: String,
                              storyboard: String,
                              bundle: Bundle? = nil) -> UIViewController? {
        return UIStoryboard(name: storyboard, bundle: bundle ?? Bundle.main).instantiateViewController(withIdentifier: identifier)
    }

    class var currentWindow: UIWindow? {
        let window = UIApplication.shared.keyWindow
        if let window = window {
            if window.windowLevel != .normal {
                return UIApplication.shared.windows.first { $0.windowLevel == .normal }
            }
        }
        return window
    }
    
    class var top: UIViewController? {
        guard let viewController = UIViewController.currentWindow?.rootViewController else {
            return nil
        }
        return UIViewController.top(viewController: viewController)
    }
    
    class func top(viewController: UIViewController) -> UIViewController? {
        if let presentedViewController = viewController.presentedViewController {
            return UIViewController.top(viewController: presentedViewController)
        } else if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return UIViewController.top(viewController: selectedViewController)
        } else if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return UIViewController.top(viewController: visibleViewController)
        }
        
        return viewController
    }
}

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
    
    @discardableResult
    public func show(_ identifier: String,
                     storyboard: String,
                     animated: Bool = true,
                     params: ParamDictionary? = nil,
                     event: Event? = nil) -> UIViewController? {
        return show(UIViewController.viewController(identifier, storyboard: storyboard),
                    animated: animated,
                    params: params,
                    event: event)
    }
    
    @discardableResult
    public func show(_ viewController: UIViewController?,
                     animated: Bool = true,
                     params: ParamDictionary? = nil,
                     event: Event? = nil) -> UIViewController? {
        guard let viewController = viewController, navigationController != nil else { return nil }
        if let params = params {
            viewController.params = params
        }
        if let event = event {
            viewController.event = event
            viewController.event?.sender = self
        }
        Keyboard.hide { [weak self] in
            self?.navigationController?.pushViewController(viewController, animated: animated)
        }
        return viewController
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
    
    public func dismissModals() {
        func dismiss(_ presentedViewController: UIViewController?) {
            presentedViewController?.dismissModals()
            if let modalVC = presentedViewController as? SRModalViewController {
                modalVC.dismiss(animated: false, completion:modalVC.completionHandler)
            } else {
                presentedViewController?.dismiss(animated: false, completion: nil)
            }
        }
        
        if let navigationController = navigationController {
            navigationController.viewControllers.reversed().forEach {
                dismiss($0.presentedViewController)
            }
        } else if let navigationController = self as? UINavigationController {
            navigationController.viewControllers.reversed().forEach {
                dismiss($0.presentedViewController)
            }
        } else {
            dismiss(presentedViewController)
        }
    }
    
    //本视图是否展现在最前面
    public var isTop: Bool {
        let top = UIViewController.top
        if self === top {
            return true
        } else if let vc = top as? UINavigationController,
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
        if SRAlert.showToast(message, in: view) {
            view.unableTimed()
        }
    }
}

