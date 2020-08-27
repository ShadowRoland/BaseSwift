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
    public class SRBaseBusinessComponent: NSObject, UIGestureRecognizerDelegate, SRSimplePromptDelegate, SRNavigationBarDelegate {
        public weak var viewController: UIViewController?
        
        public var navigationBarType: NavigationBarType = .system
        public var navigationBackgroundAlpha = 0.5 as CGFloat
        
        //MARK: 导航栏或状态栏下的子视图
        open var navigationBarTopConstraint: NSLayoutConstraint? {
            if let viewController = viewController,
                navigationBarType == .sr {
                let navigationBar = self.navigationBar
                if /*!navigationBar.isHidden,*/
                    let constraint = navigationBar.superview?.constraints.first(where: {
                    (($0.firstItem === navigationBar && $0.secondItem === viewController.view)
                        || ($0.firstItem === viewController.view && $0.secondItem === navigationBar))
                    && $0.firstAttribute == .top
                    && $0.secondAttribute == .top
                }) {
                    return constraint
                }
            }
            return nil
        }
        
        public lazy var navigationBar: SRNavigationBar = {
            let navigationBar = SRNavigationBar()
            navigationBar.barStyle = .default
            navigationBar.shadowImage = nil
            navigationBar.delegate = self
            if let viewController = viewController {
                viewController.view.addSubview(navigationBar)
                constrain(navigationBar) {
                    $0.top == $0.superview!.top
                    $0.leading == $0.superview!.leading
                    $0.trailing == $0.superview!.trailing
                    $0.height == SRNavigationBar.height
                }
                //let group = constrain(navigationBar) {
                //    $0.top == $0.superview!.top + C.srStatusBarHeight()
                //}
//                var constraint =
//                    NSLayoutConstraint(item: navigationBar,
//                                       attribute: .top,
//                                       relatedBy: .equal,
//                                       toItem: viewController.view,
//                                       attribute: .top,
//                                       multiplier: 1.0,
//                                       constant: C.srStatusBarHeight())
//                navigationBar.addConstraint(constraint)
            }
            return navigationBar
        }()
        
        public var navigationItem: SRNavigationItem {
            return navigationBar.navigationItem
        }
        
        //MARK: 导航栏或状态栏底部位置
        
        class Observed {
            fileprivate init() {}
            weak var object: AnyObject?
            var frame: CGRect = .zero
            var bottom: CGFloat = 0
        }
        
        var _statusBarObserved = Observed()
        var statusBarObserved: Observed {
            if _statusBarObserved.object == nil {
                if #available(iOS 13.0, *) {
//                    if let statusBarManager = UIApplication.shared.keyWindow?.windowScene?.statusBarManager {
//                        if statusBarManager.responds(to: Selector(("createLocalStatusBar"))) {
//                            if let localStatusBar = statusBarManager.perform(Selector(("createLocalStatusBar")))?.takeUnretainedValue(),
//                            localStatusBar.responds(to: Selector(("statusBar"))),
//                            let statusBar = localStatusBar.perform(Selector(("statusBar")))?.takeRetainedValue() as? UIView {
//                                _statusBarObserved.object = statusBar
//                            }
//                        }
//                    }
                    if let statusBarManager = UIApplication.shared.keyWindow?.windowScene?.statusBarManager {
                        _statusBarObserved.object = statusBarManager
                        _statusBarObserved.object?.addObserver(self, forKeyPath: "statusBarFrame", options: .new, context: nil)
                    }
                } else {
                    _statusBarObserved.object = UIApplication.shared.value(forKey: "statusBar") as? UIView
                    _statusBarObserved.object?.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
                }
            }
            return _statusBarObserved
        }
        let uiNavigationBarObserved = Observed()
        let srNavigationBarObserved = Observed()
        
        private func observeNavigationBarFrame() {
            guard let viewController = viewController else {
                return
            }
            
            let srNavigationBarType = viewController.srNavigationBarType
            if srNavigationBarType == .system {
                var uinavigationBar = viewController.navigationController?.navigationBar
                if let navigaionController = viewController.navigationController,
                !navigaionController.viewControllers.contains(viewController) {
                    uinavigationBar = nil
                }

                if uinavigationBar !== uiNavigationBarObserved.object {
                    if let view = uiNavigationBarObserved.object {
                        view.removeObserver(self, forKeyPath: "frame")
                    }
                    if let view = srNavigationBarObserved.object {
                        view.removeObserver(self, forKeyPath: "frame")
                        srNavigationBarObserved.object = nil
                    }
                    if let uinavigationBar = uinavigationBar {
                        uinavigationBar.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
                        uiNavigationBarObserved.object = uinavigationBar
                        uiNavigationBarObserved.frame = .zero
                        observeValue(forKeyPath: "frame", of: uinavigationBar, change: nil, context: nil)
                    }
                }
            } else if srNavigationBarType == .sr {
                let srNavigationBar = viewController.srNavigationBar
                if srNavigationBar !== srNavigationBarObserved.object {
                    if let view = uiNavigationBarObserved.object {
                        view.removeObserver(self, forKeyPath: "frame")
                        self.uiNavigationBarObserved.object = view
                    }
                    if let view = srNavigationBarObserved.object {
                        view.removeObserver(self, forKeyPath: "frame")
                    }
                    
                    srNavigationBar.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
                    srNavigationBarObserved.object = srNavigationBar
                    srNavigationBarObserved.frame = .zero
                    observeValue(forKeyPath: "frame", of: srNavigationBar, change: nil, context: nil)
                }
            }
        }
        
        public var topLayoutGuide: CGFloat {
            guard let viewController = viewController, viewController.isViewLoaded else {
                return 0
            }
            
            var bottom = topLayoutGuideStatusBar()
            let srNavigationBarType = viewController.srNavigationBarType
            if srNavigationBarType == .system {
                var observed: Observed?
                if uiNavigationBarObserved.object != nil {
                    observed = uiNavigationBarObserved
                } else {
                    observed = Observed()
                    if let navigaionController = viewController.navigationController,
                    navigaionController.viewControllers.contains(viewController)  {
                        observed?.object = navigaionController.navigationBar
                    }
                }
                bottom = topLayoutGuideNavigationBar(observed!)
            } else if srNavigationBarType == .sr {
                var observed: Observed?
                if srNavigationBarObserved.object != nil {
                    observed = srNavigationBarObserved
                } else {
                    observed = Observed()
                    observed?.object = viewController.srNavigationBar
                }
                bottom = topLayoutGuideNavigationBar(observed!)
            }
            return bottom
        }
        
        public func topLayoutGuideStatusBar(_ update: Bool = false) -> CGFloat {
            let viewController = self.viewController!
            let view = viewController.view!
            var statusBar: UIView?
            var frame: CGRect = .zero
            var isHidden = true
            if #available(iOS 13.0, *) {
                if let object = statusBarObserved.object {
                    let statusBarManager = object as! UIStatusBarManager
                    isHidden = statusBarManager.isStatusBarHidden
                    frame = statusBarManager.statusBarFrame
                }
            } else {
                if let object = statusBarObserved.object {
                    let view = object as! UIView
                    isHidden = view.isHidden
                    frame = view.frame
                    statusBar = view
                }
            }
            if isHidden {
                //状态栏没隐藏，根据状态栏获取底部位置
                let condition = update ? frame != statusBarObserved.frame : true
                if condition {
                    let window = view.window != nil ? view.window! : UIApplication.shared.keyWindow!
                    let top = window.convert(view.frame.origin, from: view.superview).y
                    var bottom = 0 as CGFloat
                    if let statusBar = statusBar {
                        bottom = window.convert(CGPoint(x: frame.origin.x,
                                                        y: frame.origin.y + frame.size.height),
                                                from: statusBar.superview).y
                    } else {
                        bottom = frame.origin.y + frame.size.height
                    }
                    bottom = max(bottom - top, 0)
                    if update {
                        statusBarObserved.frame = frame
                        statusBarObserved.bottom = bottom
                    }
                    return bottom
                } else {
                    return statusBarObserved.bottom
                }
            } else {
                //无法获取状态栏位置，根据设备和型号获取状态栏高度和位置
                let window = view.window != nil ? view.window! : UIApplication.shared.keyWindow!
                let top = window.convert(view.frame.origin, from: view.superview).y
                var bottom = C.screenOrientation == .portrait ? C.statusBarHeight() : 0
                bottom = max(bottom - top, 0)
//                    if update {
//                        statusBarObservedFrame = statusBar.frame
//                        statusBarObservedBottom = bottom
//                    }
                return bottom
            }
        }
        
        //MARK: 导航栏或状态栏下的子视图
        
        open func regainTopLayout() {
            let bottom = topLayoutGuide
            if let constraint = topLayoutSubviewHeightConstraint, bottom != constraint.constant {
                constraint.constant = bottom
            }
        }
        
        open var topLayoutSubviewHeightConstraint: NSLayoutConstraint? {
            if let topLayoutSubview = topLayoutSubview,
                let constraint = topLayoutSubview.constraints.first(where: {
                $0.firstItem === topLayoutSubview && $0.firstAttribute == .height
            }) {
                return constraint
            }
            return nil
        }
        
        var _topLayoutSubview: UIView? = .init()
        open var topLayoutSubview: UIView? {
            get {
                if let view = viewController?.view,
                    let topLayoutSubview = _topLayoutSubview,
                    !view.subviews.contains(topLayoutSubview) {
                    view.addSubview(topLayoutSubview)
                    view.insertSubview(topLayoutSubview, at: 0)
                    constrain(topLayoutSubview) { (view) in
                        view.top == view.superview!.top
                        view.leading == view.superview!.leading
                        view.trailing == view.superview!.trailing
                        view.height == 0
                    }
                }
                return _topLayoutSubview
            }
            set {
                if newValue !== _topLayoutSubview {
                    _topLayoutSubview?.removeFromSuperview()
                }
                _topLayoutSubview = newValue
            }
        }
        
        //MARK: - KVO
        
        fileprivate func topLayoutGuideNavigationBar(_ observed: Observed, update: Bool = false) -> CGFloat {
            let viewController = self.viewController!
            let view = viewController.view!
            if let navigationBar = observed.object, !navigationBar.isHidden {
                //如果可以获取到系统导航栏位置，直接取导航栏位置做参照物
                let condition = update ? navigationBar.frame != observed.frame : true
                if condition {
                    let window = view.window != nil ? view.window! : UIApplication.shared.keyWindow!
                    let top = window.convert(view.frame.origin, from: view.superview).y
                    var bottom = window.convert(CGPoint(x: navigationBar.frame.origin.x,
                                                        y: navigationBar.frame.origin.y + navigationBar.frame.size.height),
                                                from: navigationBar.superview).y
                    bottom = max(bottom - top, 0)
                    if update {
                        observed.frame = navigationBar.frame
                        observed.bottom = bottom
                    }
                    return bottom
                } else {
                    return observed.bottom
                }
            } else {
                //如果获取不到导航栏位置，获取状态栏位置
                return topLayoutGuideStatusBar()
            }
        }
        
        public override func observeValue(forKeyPath keyPath: String?,
                                          of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {
            if uiNavigationBarObserved.object === object as AnyObject? {
                if let viewController = viewController as? SRBaseViewController,
                    viewController.srIsTop && viewController.view != nil {
                    let bottom = topLayoutGuideNavigationBar(uiNavigationBarObserved, update: true)
                    let constraint = topLayoutSubviewHeightConstraint
                    if bottom != constraint?.constant {
                        constraint?.constant = bottom
                    }
                }
            } else if srNavigationBarObserved.object === object as AnyObject? {
                if let viewController = viewController as? SRBaseViewController,
                    viewController.srIsTop && viewController.view != nil {
                    let bottom = topLayoutGuideNavigationBar(srNavigationBarObserved, update: true)
                    let constraint = topLayoutSubviewHeightConstraint
                    if bottom != constraint?.constant {
                        constraint?.constant = bottom
                    }
                }
            } else if statusBarObserved.object === object as AnyObject? {
                if let viewController = viewController as? SRBaseViewController,
                    viewController.srIsTop && viewController.view != nil {
                    var bottom = topLayoutGuideStatusBar(true)
                    if viewController.srNavigationBarType == .system {
                        bottom = topLayoutGuideNavigationBar(uiNavigationBarObserved)
                    } else if viewController.srNavigationBarType == .sr {
                        bottom = topLayoutGuideNavigationBar(srNavigationBarObserved)
                    }
                    let constraint = viewController.topLayoutSubviewHeightConstraint
                    if bottom != constraint?.constant {
                        constraint?.constant = bottom
                    }
                }
            }
        }
        
        //MARK: - SRNavigationBarDelegate
        public func navigationBarDidLayout(_ navigationBar: SRNavigationBar) {
            if let constraint = navigationBarTopConstraint {
                let bottom = topLayoutGuideStatusBar()
                if constraint.constant != bottom {
                    constraint.constant = bottom
                }
            }
        }
        
        fileprivate struct AssociatedKeys {
            static var baseBusiness = "UIViewController.SRBaseBusinessComponent.baseBusiness"
        }
        
        #if DEBUG
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
            if #available(iOS 13.0, *) {
                _statusBarObserved.object?.removeObserver(self, forKeyPath: "statusBarFrame")
            } else {
                _statusBarObserved.object?.removeObserver(self, forKeyPath: "frame")
            }
            uiNavigationBarObserved.object?.removeObserver(self, forKeyPath: "frame")
            srNavigationBarObserved.object?.removeObserver(self, forKeyPath: "frame")
        }
        #endif
        
        public var isViewDidAppear = false   //进入页面时初始的操作是否已被执行
        public var isNavigationBarButtonsActive = false   //viewController的导航栏按钮是否有效
        
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
            guard let viewController = viewController else { return }
            
            let navigationBarType = viewController.srNavigationBarType
            if navigationBarType ==  .system {
                navigationBar.isHidden = true
                if let navigationController = viewController.navigationController, isViewDidAppear {
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
                viewController.navigationController?.isNavigationBarHidden = true
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
                if let viewController = viewController, viewController.srIsModalRootViewController {
                    if let vc = viewController.navigationController as? SRNavigationController {
                        vc.isPageSwipeEnabled = false
                        vc.interactivePopGestureRecognizer?.isEnabled = false
                    }
                    return
                }
                
                if pageBackGestureStyle.contains(.page) {
                    if let viewController = viewController,
                        let vc = viewController.navigationController as? SRNavigationController {
                        vc.isPageSwipeEnabled = true
                    }
                }
            }
        }
        
        public var isPageLongPressEnabled = false {
            didSet {
                guard !C.environment.contains(.production) else { return }
                if let viewController = viewController,
                    let vc = viewController.navigationController as? SRNavigationController {
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
    var srBaseComponent: SRBaseBusinessComponent {
        get {
            if let component =
                objc_getAssociatedObject(self, &SRBaseBusinessComponent.AssociatedKeys.baseBusiness)
                    as? SRBaseBusinessComponent {
                return component
            }
            
            let component = SRBaseBusinessComponent()
            component.viewController = self
            objc_setAssociatedObject(self,
                                     &SRBaseBusinessComponent.AssociatedKeys.baseBusiness,
                                     component,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return component
        }
        set {
            let component = newValue
            component.viewController = self
            objc_setAssociatedObject(self,
                                     &SRBaseBusinessComponent.AssociatedKeys.baseBusiness,
                                     component,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var srParams: ParamDictionary {
        get {
            return srBaseComponent.params
        }
        set {
            srBaseComponent.params = newValue
        }
    }
    
    var srStatusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
    
    var srNavigationBarHeight: CGFloat {
        var height = 0 as CGFloat
        if srNavigationBarType == .system,
            let navigationController = navigationController,
            !navigationController.navigationBar.isHidden {
            height += srNavigationBar.height
        } else if srNavigationBarType == .sr, !srNavigationBar.isHidden {
            height += srNavigationBar.height
        }
        return height
    }
    
    var srNavigationBarTopConstraint: NSLayoutConstraint? {
        return srBaseComponent.navigationBarTopConstraint
    }
    
    var srNavigationBar: SRNavigationBar {
        get {
            return srBaseComponent.navigationBar
        }
        set {
            srBaseComponent.navigationBar = newValue
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
    
    var srNavigationBarType: NavigationBarType {
        get {
            return srBaseComponent.navigationBarType
        }
        set {
            srBaseComponent.navigationBarType = newValue
        }
    }
    
    var srNavigationBarAppear: NavigationBar.Appear {
        get {
            return srBaseComponent.navigationBarAppear
        }
        set {
            srBaseComponent.navigationBarAppear = newValue
        }
    }
    
    var isNavigationBarVisible: Bool {
        switch srNavigationBarAppear {
        case .visible:
            return true
            
        case .hidden:
            return false
            
        case .custom:
            if srNavigationBarType == .system {
                if let navigationController = navigationController {
                    return !navigationController.isNavigationBarHidden
                } else {
                    return false
                }
            } else if srNavigationBarType == .sr {
                return !srNavigationBar.isHidden
            } else {
                return false
            }
        }
    }
    
    func setNavigationBarAppear(_ srNavigationBarAppear: NavigationBar.Appear, animated: Bool) {
        srBaseComponent.setNavigationBarAppear(srNavigationBarAppear, animated: animated)
    }
    
    var srStateMachine: SRStateMachine {
        return srBaseComponent.stateMachine
    }
    
    var srEvent: SRKit.Event? {
        get {
            return srBaseComponent.event
        }
        set {
            srBaseComponent.event = newValue
        }
    }
    
    var srIsPreviewed: Bool {
        get {
            return srBaseComponent.isPreviewed
        }
        set {
            srBaseComponent.isPreviewed = newValue
        }
    }
    
    var srPageBackGestureStyle: SRBaseBusinessComponent.PageBackGestureStyle {
        get {
            return srBaseComponent.pageBackGestureStyle
        }
        set {
            srBaseComponent.pageBackGestureStyle = newValue
        }
    }
    
    var srIsPageLongPressEnabled: Bool {
        get {
            return srBaseComponent.isPageLongPressEnabled
        }
        set {
            srBaseComponent.isPageLongPressEnabled = newValue
        }
    }
}

public extension UIViewController {
    class func srViewController(_ identifier: String,
                                storyboard: String,
                                bundle: Bundle? = nil) -> UIViewController? {
        return UIStoryboard(name: storyboard, bundle: bundle ?? Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    class var srCurrentWindow: UIWindow? {
        let window = UIApplication.shared.keyWindow
        if let window = window {
            if window.windowLevel != .normal {
                return UIApplication.shared.windows.first { $0.windowLevel == .normal }
            }
        }
        return window
    }
    
    class var srTop: UIViewController? {
        guard let viewController = UIViewController.srCurrentWindow?.rootViewController else {
            return nil
        }
        return UIViewController.srTop(viewController: viewController)
    }
    
    class func srTop(viewController: UIViewController) -> UIViewController? {
        if let presentedViewController = viewController.presentedViewController {
            return UIViewController.srTop(viewController: presentedViewController)
        } else if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return UIViewController.srTop(viewController: selectedViewController)
        } else if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return UIViewController.srTop(viewController: visibleViewController)
        }
        
        return viewController
    }
}

extension UIViewController {
    //MARK: - Autorotate Orientation
    
    /// 判断设备屏幕方向是否真的发生旋转，传入参数为nil时会强制通过，一般用于初始化或者强制刷新页面布局
    public func srGuardDeviceOrientationDidChange(_ sender: AnyObject?) -> Bool {
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
    
    var srIsModalRootViewController: Bool {
        if let vc = navigationController as? SRModalViewController,
            vc.viewControllers.count > 1,
            self === vc.viewControllers[1] {
            return true
        } else {
            return false
        }
    }
    
    @discardableResult
    public func srShow(_ identifier: String,
                       storyboard: String,
                       animated: Bool = true,
                       params: ParamDictionary? = nil,
                       event: SRKit.Event? = nil) -> UIViewController? {
        return srShow(UIViewController.srViewController(identifier, storyboard: storyboard),
                      animated: animated,
                      params: params,
                      event: event)
    }
    
    @discardableResult
    public func srShow(_ viewController: UIViewController?,
                       animated: Bool = true,
                       params: ParamDictionary? = nil,
                       event: SRKit.Event? = nil) -> UIViewController? {
        guard let viewController = viewController, navigationController != nil else { return nil }
        if let params = params {
            viewController.srParams = params
        }
        if let event = event {
            viewController.srEvent = event
            viewController.srEvent?.sender = self
        }
        Keyboard.hide { [weak self] in
            self?.navigationController?.pushViewController(viewController, animated: animated)
        }
        return viewController
    }
    
    @available(iOS 13.0, *)
    @discardableResult
    public func srModal(_ identifier: String,
                        storyboard: String,
                        animated: Bool = true,
                        presentationStyle style: UIModalPresentationStyle = .automatic,
                        params: ParamDictionary? = nil,
                        event: SRKit.Event? = nil,
                        completion: (() -> Void)? = nil) -> UIViewController? {
        return srModal(UIViewController.srViewController(identifier, storyboard: storyboard),
                       animated: animated,
                       params: params,
                       event: event,
                       completion: completion)
    }
    
    @available(iOS 13.0, *)
    @discardableResult
    public func srModal(_ viewController: UIViewController?,
                        animated: Bool = true,
                        presentationStyle style: UIModalPresentationStyle = .automatic,
                        params: ParamDictionary? = nil,
                        event: SRKit.Event? = nil,
                        completion: (() -> Void)? = nil) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        if let params = params {
            viewController.srParams = params
        }
        if let event = event {
            viewController.srEvent = event
            viewController.srEvent?.sender = self
        }
        Keyboard.hide { [weak self] in
            if let strongSelf = self {
                let modalVC = SRModalViewController.standard(viewController)
                modalVC.modalPresentationStyle = style
                strongSelf.present(modalVC,
                          animated: animated,
                          completion: completion)
            }
        }
        return viewController
    }
    
    @discardableResult
    public func srModal(_ identifier: String,
                        storyboard: String,
                        animated: Bool = true,
                        params: ParamDictionary? = nil,
                        event: SRKit.Event? = nil,
                        completion: (() -> Void)? = nil) -> UIViewController? {
        return srModal(UIViewController.srViewController(identifier, storyboard: storyboard),
                       animated: animated,
                       params: params,
                       event: event,
                       completion: completion)
    }
    
    @discardableResult
    public func srModal(_ viewController: UIViewController?,
                        animated: Bool = true,
                        params: ParamDictionary? = nil,
                        event: SRKit.Event? = nil,
                        completion: (() -> Void)? = nil) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        if let params = params {
            viewController.srParams = params
        }
        if let event = event {
            viewController.srEvent = event
            viewController.srEvent?.sender = self
        }
        Keyboard.hide { [weak self] in
            if let strongSelf = self {
                let modalVC = SRModalViewController.standard(viewController)
                strongSelf.present(modalVC,
                          animated: animated,
                          completion: completion)
            }
        }
        return viewController
    }
    
    public func srPopBack(_ animated: Bool = true) {
        guard navigationController != nil else { return }
        
        //Keyboard.hide { [weak self] in
        if srIsModalRootViewController {
            (navigationController as! SRModalViewController).dismiss(animated)
            return
        }
        
        navigationController?.popViewController(animated: animated)
    }
    
    //返回到指定类的ViewController，参数toClasses为指定类的数组，按照优先级排列
    @discardableResult
    public func srPopBack(toClasses: [AnyClass],
                        animated: Bool = true,
                        clear: Bool = true) -> UIViewController? {
        guard let navigationController = navigationController else { return nil }
        
        if let viewController = navigationController.viewControllers.last(where: { vc in
            toClasses.first { vc.isKind(of: $0) } != nil
        }) {
            srPopBack(to: viewController, animated: animated, clear: clear)
            return viewController
        }
        
        return nil
    }
    
    //返回到指定的ViewController
    public func srPopBack(to: UIViewController,
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
    
    public func srDismissModals() {
        func dismiss(_ presentedViewController: UIViewController?) {
            presentedViewController?.srDismissModals()
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
    public var srIsTop: Bool {
        let top = UIViewController.srTop
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
    public func srEnsureNavigationBarHidden(_ isHidden: Bool) {
        if srNavigationBarType == .system,
            let navigationController = navigationController,
            navigationController.topViewController === self
                && navigationController.navigationBar.topItem != navigationItem {
            navigationController.setNavigationBarHidden(!isHidden, animated: false)
            navigationController.setNavigationBarHidden(isHidden, animated: false)
        }
    }
    
    //MARK: - Common Features
    
    public func srShowToast(_ message: String?) {
        if SRAlert.showToast(message, in: view) {
            view.unableTimed()
        }
    }
    
    public func srRegainTopLayout() {
        srBaseComponent.regainTopLayout()
    }
    
    public var srTopLayoutGuide: CGFloat {
        return srBaseComponent.topLayoutGuide
    }
    
    public var srTopLayoutGuideStatusBar: CGFloat {
        return srBaseComponent.topLayoutGuideStatusBar()
    }
}
