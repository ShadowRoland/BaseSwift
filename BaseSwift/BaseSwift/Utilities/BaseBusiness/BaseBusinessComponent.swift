//
//  BaseBusinessComponent.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/8.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

extension UIViewController {
    public class BaseBusinessComponent: NSObject {
        public weak var decorator: UIViewController?
        
        fileprivate static let runtimeKey = UnsafeRawPointer(bitPattern: "baseBusiness".hashValue)!
        
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        
        public var isViewDidAppear = false   //进入页面时初始的操作是否已被执行
        public var isNavigationBarButtonsActive = false   //decorator的导航栏按钮是否有效
        
        public var needShowProgress = false   //延迟显示progress的判断依据
        public var progressMaskType: UIView.ProgressComponent.MaskType! //延迟显示progress的maskType
        public lazy var progressContainerView: UIView = UIView()
        
        //MARK: Load Data Fail
        
        public var loadDataFailRetryCapability: HttpCapability?//请求数据失败时显示点击重试请求的capability，一般是 页面刚进入发出的第一个http请求
        public var loadDataFailRetryHandler: (() -> Void)?  //请求数据失败时点击重试的操作
        public lazy var loadDataFailContainerView: UIView = UIView()
        public var loadDataFailView: LoadDataStateView?
        
        public var isShowingLoadDataFailView: Bool {
            return loadDataFailView != nil && loadDataFailView!.superview != nil
        }
        
        public func showLoadDataFailView(_ inView: UIView, text: String?) {
            if loadDataFailView == nil {
                loadDataFailView = LoadDataStateView(.fail)
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
        
        public var navigartionBarAppear: NavigartionBar.Appear = .visible {
            didSet {
                if let navigationController = decorator?.navigationController,
                    isViewDidAppear,
                    oldValue != navigartionBarAppear {
                    switch navigartionBarAppear {
                    case .visible:
                        navigationController.isNavigationBarHidden = false
                    case .hidden:
                        navigationController.isNavigationBarHidden = true
                    default: break
                    }
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
                guard RunInEnvironment != RunEnvironment.production else { return }
                
                if let vc = decorator?.navigationController as? SRNavigationController {
                    vc.longPressEnable = isPageLongPressEnabled
                }
            }
        }
        
        //MARK: Params
        
        fileprivate var params = EmptyParams()
        
        //MARK: State machine
        
        fileprivate var stateMachine = SRStateMachine()
        
        //MARK: 3D Touch
        
        fileprivate var isPreviewed = false
    }
}

extension UIViewController {
    public var baseBusinessComponent: BaseBusinessComponent {
        if let component = objc_getAssociatedObject(self, BaseBusinessComponent.runtimeKey)
            as? BaseBusinessComponent {
            return component
        }
        
        let component = BaseBusinessComponent()
        component.decorator = self
        objc_setAssociatedObject(self,
                                 BaseBusinessComponent.runtimeKey,
                                 component,
                                 .OBJC_ASSOCIATION_RETAIN)
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
    
    public var navigartionBarAppear: NavigartionBar.Appear {
        get {
            return baseBusinessComponent.navigartionBarAppear
        }
        set {
            baseBusinessComponent.navigartionBarAppear = newValue
        }
    }
    
    public var pageBackGestureStyle: BaseBusinessComponent.PageBackGestureStyle {
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
