//
//  SRBaseBusinessComponent.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/8.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

extension UIViewController {
    public class SRBaseBusinessComponent: NSObject {
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
        
        public var loadDataFailRetryMethod: HTTP.Method<Any>?//请求数据失败时显示点击重试的请求，一般是 页面刚进入发出的第一个http请求
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
                        vc.panEnable = false
                        vc.interactivePopGestureRecognizer?.isEnabled = false
                    }
                    return
                }
                
                if pageBackGestureStyle.contains(.page) {
                    if let vc = decorator?.navigationController as? SRNavigationController {
                        vc.panEnable = true
                    }
                } else {
                    if let vc = decorator?.navigationController as? SRNavigationController {
                        vc.panEnable = false
                        if pageBackGestureStyle.contains(.edge) {
                            vc.interactivePopGestureRecognizer?.isEnabled = true
                            vc.interactivePopGestureRecognizer?.delegate =
                                decorator as? UIGestureRecognizerDelegate
                        } else {
                            vc.interactivePopGestureRecognizer?.isEnabled = false
                        }
                    }
                }
            }
        }
        
        public var isPageLongPressEnabled = false {
            didSet {
                guard Environment != .production else { return }
                
                if let vc = decorator?.navigationController as? SRNavigationController {
                    vc.longPressEnable = isPageLongPressEnabled
                }
            }
        }
        
        //MARK: Params
        
        fileprivate var params = [:] as ParamDictionary
        
        //MARK: State machine
        
        fileprivate var stateMachine = SRStateMachine()
        
        //MARK: 3D Touch
        
        fileprivate var isPreviewed = false
    }
}

extension UIViewController {
    public var baseBusinessComponent: SRBaseBusinessComponent {
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
    
    public var params: ParamDictionary {
        get {
            return baseBusinessComponent.params
        }
        set {
            baseBusinessComponent.params = newValue
        }
    }
    
    public var stateMachine: SRStateMachine {
        return baseBusinessComponent.stateMachine
    }
    
    public var isPreviewed: Bool {
        get {
            return baseBusinessComponent.isPreviewed
        }
        set {
            baseBusinessComponent.isPreviewed = newValue
        }
    }
    
    public var navigartionBarAppear: NavigationBar.Appear {
        get {
            return baseBusinessComponent.navigartionBarAppear
        }
        set {
            baseBusinessComponent.navigartionBarAppear = newValue
        }
    }
    
    public var pageBackGestureStyle: SRBaseBusinessComponent.PageBackGestureStyle {
        get {
            return baseBusinessComponent.pageBackGestureStyle
        }
        set {
            baseBusinessComponent.pageBackGestureStyle = newValue
        }
    }
    
    public var isPageLongPressEnabled: Bool {
        get {
            return baseBusinessComponent.isPageLongPressEnabled
        }
        set {
            baseBusinessComponent.isPageLongPressEnabled = newValue
        }
    }
}
