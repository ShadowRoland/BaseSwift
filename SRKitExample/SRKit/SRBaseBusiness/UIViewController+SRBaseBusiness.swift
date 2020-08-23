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
import Cartography

extension UIViewController {
    public class SRBaseBusinessComponent: NSObject, UIGestureRecognizerDelegate, SRSimplePromptDelegate {
        public weak var decorator: UIViewController?
        
        public var navigationBarType: NavigationBarType = .system
        public var navigationBackgroundAlpha = 0.5 as CGFloat
        
        public lazy var navigationBar: SRNavigationBar = {
            let navigationBar = SRNavigationBar()
            navigationBar.barStyle = .default
            navigationBar.shadowImage = nil
            if let decorator = decorator {
                decorator.view.addSubview(navigationBar)
                constrain(navigationBar) {
                    $0.leading == $0.superview!.leading
                    $0.trailing == $0.superview!.trailing
                    $0.top == $0.superview!.top + C.statusBarHeight()
                    $0.height == SRNavigationBar.height
                }
                //let group = constrain(navigationBar) {
                //    $0.top == $0.superview!.top + C.statusBarHeight()
                //}
//                var constraint =
//                    NSLayoutConstraint(item: navigationBar,
//                                       attribute: .top,
//                                       relatedBy: .equal,
//                                       toItem: decorator.view,
//                                       attribute: .top,
//                                       multiplier: 1.0,
//                                       constant: C.statusBarHeight())
//                navigationBar.addConstraint(constraint)
            }
            return navigationBar
        }()
        
        public lazy var navigationItem: SRNavigationItem = {
            let navigationItem = SRNavigationItem()
            navigationBar.navigationItem = navigationItem
            return navigationItem
        }()
        
        fileprivate struct AssociatedKeys {
            static var baseBusiness = "UIViewController.SRBaseBusinessComponent.baseBusiness"
        }
        
        #if DEBUG
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        #endif
        
        public var isViewDidAppear = false   //进入页面时初始的操作是否已被执行
        public var isNavigationBarButtonsActive = false   //decorator的导航栏按钮是否有效
        
        public var progressMaskType: UIView.SRProgressComponent.MaskType! //延迟显示progress的maskType
        public lazy var progressContainerView: UIView = UIView()
        
        //MARK: Load Data Fail
        
        public var loadDataFailRetryRequest: SRHTTP.Request?//请求数据失败时显示点击重试的请求，一般是 页面刚进入发出的第一个http请求
        public var loadDataFailRetryHandler: (() -> Void)?  //请求数据失败时点击重试的操作
        public lazy var loadDataFailContainerView: UIView = UIView()
        public var loadDataFailView: SRSimplePromptView?
        
        public var isShowingLoadDataFailView: Bool {
            return loadDataFailView != nil && loadDataFailView!.superview != nil
        }
        
        public func showLoadDataFailView(_ text: String?, image: UIImage?) {
            dismissLoadDataFailView()
            loadDataFailView = SRSimplePromptView(text, image: image, width: loadDataFailContainerView.width)
            loadDataFailContainerView.addSubview(loadDataFailView!)
            constrain(loadDataFailView!) {
                $0.edges == inset($0.superview!.edges, 0)
            }
        }
        
        public func dismissLoadDataFailView() {
            loadDataFailView?.removeFromSuperview()
        }
        
        //MARK: SRSimplePromptDelegate httpFailRetry
        
        public func didClickSimplePromptView(_ view: SRSimplePromptView) {
            dismissLoadDataFailView()
            loadDataFailRetryHandler?()
        }
        
        //MARK: Navigation Bar Appear
        
        var _navigationBarAppear: NavigationBar.Appear = .visible
        public var navigationBarAppear: NavigationBar.Appear {
            get {
                return _navigationBarAppear
            }
            set {
                _navigationBarAppear = newValue
                setNavigationBarAppear(newValue, animated: false)
            }
        }
        
        public func setNavigationBarAppear(_ navigationBarAppear: NavigationBar.Appear,
                                           animated: Bool) {
            guard let decorator = decorator else { return }
            
            let navigationBarType = decorator.navigationBarType
            if navigationBarType ==  .system {
                navigationBar.isHidden = true
                if let navigationController = decorator.navigationController, isViewDidAppear {
                    switch navigationBarAppear {
                    case .visible:
                        navigationController.setNavigationBarHidden(false, animated: animated)
                    //navigationBarBackgroundView.isHidden = false
                    case .hidden:
                        navigationController.setNavigationBarHidden(true, animated: animated)
                    //navigationBarBackgroundView.isHidden = true
                    default: break
                    }
                } else {
                    //navigationBarBackgroundView.isHidden = true
                }
            }  else if navigationBarType == .sr {
                decorator.navigationController?.isNavigationBarHidden = true
                switch navigationBarAppear {
                case .visible:
                    navigationBar.isHidden = false
                case .hidden:
                    navigationBar.isHidden = true
                default: break
                }
            }
        }
        
        //MARK: Gesture
        
        public struct PageBackGestureStyle : OptionSet {
            /// Returns the raw bitmask value of the option and satisfies the `RawRepresentable` protocol.
            private(set) public var rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            ///页面不可右滑返回
            public static let none = PageBackGestureStyle(rawValue: 1 << 0)
            ///页面可按住左边缘右滑返回
            public static let page = PageBackGestureStyle(rawValue: 1 << 1)
            ///页面所有部分都可按住右滑返回
            public static let edge = PageBackGestureStyle(rawValue: 1 << 2)
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
                    if let decorator = decorator,
                        let vc = decorator.navigationController as? SRNavigationController {
                        vc.isPageSwipeEnabled = true
                    }
                }
            }
        }
        
        public var isPageLongPressEnabled = false {
            didSet {
                guard !C.environment.contains(.production) else { return }
                if let decorator = decorator,
                    let vc = decorator.navigationController as? SRNavigationController {
                    vc.isNavPageLongPressEnabled = isPageLongPressEnabled
                }
            }
        }
        
        //MARK: Params
        
        fileprivate var params = [:] as ParamDictionary
        
        //MARK: State machine
        
        fileprivate var stateMachine = SRStateMachine()
        
        //MARK: Event
        
        fileprivate var event: SRKit.Event? = nil
        
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
    
    var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
    
    var navigationBarHeight: CGFloat {
        var height = 0 as CGFloat
        if navigationBarType == .system,
            let navigationController = navigationController,
            !navigationController.navigationBar.isHidden {
            height += navigationBar.height
        } else if navigationBarType == .sr, !navigationBar.isHidden {
            height += navigationBar.height
        }
        return height
    }
    
    var navigationHeaderHeight: CGFloat {
        return statusBarHeight + navigationBarHeight
    }
    
    var navigationBar: SRNavigationBar {
        get {
            return baseBusinessComponent.navigationBar
        }
        set {
            baseBusinessComponent.navigationBar = newValue
        }
    }
    
    struct NavigationBarType: RawRepresentable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let system = NavigationBarType(0)
        public static let sr = NavigationBarType(1)
    }
    
    var navigationBarType: NavigationBarType {
        get {
            return baseBusinessComponent.navigationBarType
        }
        set {
            baseBusinessComponent.navigationBarType = newValue
        }
    }
    
    var navigationBarAppear: NavigationBar.Appear {
        get {
            return baseBusinessComponent.navigationBarAppear
        }
        set {
            baseBusinessComponent.navigationBarAppear = newValue
        }
    }
    
    var isNavigationBarVisible: Bool {
        switch navigationBarAppear {
        case .visible:
            return true
            
        case .hidden:
            return false
            
        case .custom:
            if navigationBarType == .system {
                if let navigationController = navigationController {
                    return !navigationController.isNavigationBarHidden
                } else {
                    return false
                }
            } else if navigationBarType == .sr {
                return !navigationBar.isHidden
            } else {
                return false
            }
        }
    }
    
    func setNavigationBarAppear(_ navigationBarAppear: NavigationBar.Appear, animated: Bool) {
        baseBusinessComponent.setNavigationBarAppear(navigationBarAppear, animated: animated)
    }
    
    var stateMachine: SRStateMachine {
        return baseBusinessComponent.stateMachine
    }
    
    var event: SRKit.Event? {
        get {
            return baseBusinessComponent.event
        }
        set {
            baseBusinessComponent.event = newValue
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
    
    /// 判断设备屏幕方向是否真的发生旋转，传入参数为nil时会强制通过，一般用于初始化或者强制刷新页面布局
    public func guardDeviceOrientationDidChange(_ sender: AnyObject?) -> Bool {
        if sender == nil { return true }
        
        if !shouldAutorotate { //当前视图控制器不支持屏幕切换，不需要重新布局
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
                     event: SRKit.Event? = nil) -> UIViewController? {
        return show(UIViewController.viewController(identifier, storyboard: storyboard),
                    animated: animated,
                    params: params,
                    event: event)
    }
    
    @discardableResult
    public func show(_ viewController: UIViewController?,
                     animated: Bool = true,
                     params: ParamDictionary? = nil,
                     event: SRKit.Event? = nil) -> UIViewController? {
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
    
    @discardableResult
    public func modal(_ identifier: String,
                      storyboard: String,
                      animated: Bool = true,
                      params: ParamDictionary? = nil,
                      event: SRKit.Event? = nil,
                      completion: (() -> Void)? = nil) -> UIViewController? {
        return modal(UIViewController.viewController(identifier, storyboard: storyboard),
                     animated: animated,
                     params: params,
                     event: event,
                     completion: completion)
    }
    
    @discardableResult
    public func modal(_ viewController: UIViewController?,
                      animated: Bool = true,
                      params: ParamDictionary? = nil,
                      event: SRKit.Event? = nil,
                      completion: (() -> Void)? = nil) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        if let params = params {
            viewController.params = params
        }
        if let event = event {
            viewController.event = event
            viewController.event?.sender = self
        }
        Keyboard.hide { [weak self] in
            self?.present(SRModalViewController.standard(viewController),
                          animated: animated,
                          completion: completion)
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
        if navigationBarType == .system,
            let navigationController = navigationController,
            navigationController.topViewController === self
                && navigationController.navigationBar.topItem != navigationItem {
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
