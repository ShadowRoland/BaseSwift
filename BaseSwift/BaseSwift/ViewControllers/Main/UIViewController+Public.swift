//
//  UIViewController+BaseBusiness.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import Cartography

extension UIViewController {
    public class PublicBusinessComponent: AdvertisingGuideDelegate {
        public weak var viewController: UIViewController?
        
        fileprivate struct AssociatedKeys {
            static var publicBusiness = "UIViewController.PublicBusinessComponent.publicBusiness"
        }
        
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        
        fileprivate var _advertisingVC: String?
        fileprivate weak var advertisingVC: AdvertisingGuideViewController? {
            willSet {
                if newValue == nil, let advertisingVC = advertisingVC { //意外被系统或者其他模块移除
                    advertisingDisDimiss(advertisingVC)
                }
            }
        }

        //MARK: - Advertising
        
        func showAdvertisingGuard() {
            guard viewController != nil, advertisingVC == nil else {
                return
            }
            
            let vc = UIViewController.srViewController("AdvertisingGuideViewController", storyboard: "Main")
                as! AdvertisingGuideViewController
            vc.delegate = self
            let window = UIApplication.shared.keyWindow! as UIWindow
            window.addSubview(vc.view)
            constrain(vc.view) { $0.edges == inset($0.superview!.edges, 0) }
            advertisingVC = vc
        }
        
        func showAdvertising() {
            guard let vc = viewController?.navigationController?.topViewController else {
                return
            }
            
            vc.srDismissModals()
            vc.srShow("AdvertisingViewController", storyboard: "Main")
        }
        
        //MARK: - AdvertisingGuideDelegate
        
        func advertisingGuideShowAdvertising(_ viewController: AdvertisingGuideViewController) {
            viewController.dimiss()
            self.viewController?.srStateMachine.end(Event(.showAdvertisingGuard))
        }
        
        func advertisingGuideSkip(_ viewController: AdvertisingGuideViewController) {
            viewController.dimiss()
            self.viewController?.srStateMachine.clearEvents()
            self.viewController?.srStateMachine.append(Event(.showAdvertising))
        }
        
        func advertisingDisDimiss(_ viewController: AdvertisingGuideViewController) {
            let pointer = String(pointer: viewController)
            if pointer != _advertisingVC { //保证只触发一次事件的结束
                _advertisingVC = pointer
                self.viewController?.srStateMachine.end(Event(.showAdvertisingGuard))
                DispatchQueue.main.async { [weak self] in
                    self?.advertisingVC = nil
                }
            }
        }
    }
    
    var publicBusinessComponent: PublicBusinessComponent {
        get {
            if let component =
                objc_getAssociatedObject(self, &PublicBusinessComponent.AssociatedKeys.publicBusiness)
                as? PublicBusinessComponent {
                return component
            }
            
            let component = PublicBusinessComponent()
            component.viewController = self
            objc_setAssociatedObject(self,
                                     &PublicBusinessComponent.AssociatedKeys.publicBusiness,
                                     component,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return component
        }
        set {
            let component = newValue
            component.viewController = self
            objc_setAssociatedObject(self,
                                     &PublicBusinessComponent.AssociatedKeys.publicBusiness,
                                     component,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
