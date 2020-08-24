//
//  SRModalViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit

public class SRModalViewController: SRNavigationController {
    public var completionHandler: (() -> Void)?
    private weak var rootVC: UIViewController?
    private weak var modalVC: UIViewController?
    
    public class func standard(_ modalVC: UIViewController?) -> SRModalViewController {
        let rootVC = UIViewController()
        rootVC.view.alpha = 0
        let vc = SRModalViewController(rootViewController: rootVC)
        vc.rootVC = rootVC
        vc.modalVC = modalVC
        vc.pushViewController(vc.modalVC!, animated: false)
        return vc
    }
    
    override public init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    
    public func dismiss(_ animated: Bool = true) {
        dismiss(animated: animated, completion: completionHandler)
    }
    
    private override init(rootViewController: UIViewController?) {
        super.init(rootViewController: rootViewController!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    #if DEBUG
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    #endif
    
    fileprivate class SRModalViewControllerAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
        private weak var modalViewController: SRModalViewController?
        fileprivate var animated = true
        
        init(_ modalViewController: SRModalViewController) {
            super.init()
            self.modalViewController = modalViewController
        }
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            DispatchQueue.main.async {
                transitionContext?.completeTransition(true)
            }
            return 0
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            
        }
        
        func animationEnded(_ transitionCompleted: Bool) {
            modalViewController?.dismiss(animated)
        }
    }
    
    fileprivate lazy var rootAnimatedTransitioning: SRModalViewControllerAnimatedTransitioning = .init(self)
    
    //MARK: - UINavigationBarDelegate
    
//    //拦截导航栏默认提供的返回按钮的点击
//    public func navigationBar(_ navigationBar: UINavigationBar,
//                              shouldPop item: UINavigationItem) -> Bool {
//        if viewControllers.count == 2 {
//            DispatchQueue.main.async {
//                self.topViewController?.srPopBack(false)
//            }
//            return false
//        }
//        return true
//    }
    
    //MARK: - UIGestureRecognizerDelegate
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === interactivePopGestureRecognizer  {
            if let topViewController = topViewController, topViewController.srIsModalRootViewController {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    //MARK: - UINavigationControllerDelegate
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController === rootVC {
            rootAnimatedTransitioning.animated = animated
        }
    }
    
    public override func navigationController(_ navigationController: UINavigationController,
                                              didShow viewController: UIViewController,
                                              animated: Bool) {
        if viewController === rootVC {
            isPageSwipeEnabled = false
            srIsPageLongPressEnabled = viewController.srIsPageLongPressEnabled
        } else {
            super.navigationController(navigationController,
                                       didShow: viewController,
                                       animated: animated)
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if toVC === rootVC, operation == .pop {
            return rootAnimatedTransitioning
        } else {
            return .none
        }
    }
}
