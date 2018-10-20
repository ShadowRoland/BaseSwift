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

extension UIViewController {
    public class PublicBusinessComponent {
        public weak var decorator: UIViewController?
        
        fileprivate struct AssociatedKeys {
            static var publicBusiness = "UIViewController.PublicBusinessComponent.publicBusiness"
        }
        
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        
        weak var advertisingVC: AdvertisingGuideViewController?

        //MARK: - Advertising
        
        func showAdvertisingGuard() {
            guard decorator != nil, advertisingVC != nil else {
                return
            }
            
            let vc = Common.viewController("AdvertisingGuideViewController", storyboard: "Main")
                as! AdvertisingGuideViewController
            vc.advertisingButton.clicked(self, action: #selector(clickAdvertisingButton(_:)))
            vc.skipButton.clicked(self, action: #selector(clickSkipButton(_:)))
            let window = UIApplication.shared.keyWindow! as UIWindow
            window.addSubview(vc.view)
            vc.view.frame = window.bounds
        }
        
        func showAdvertising() {
            guard let vc = decorator?.navigationController?.topViewController else {
                return
            }
            
            vc.navigationController?.presentingViewController?.dismiss(animated: false,
                                                                       completion: nil)
            vc.presentingViewController?.dismiss(animated: false, completion: nil)
            vc.show("AdvertisingViewController", storyboard: "Main")
        }
        
        @objc func clickAdvertisingButton(_ sender: Any) {
            guard Common.mutexTouch() else { return }
            advertisingVC?.dimiss()
        }
        
        @objc func clickSkipButton(_ sender: Any) {
            guard Common.mutexTouch() else { return }
            advertisingVC?.dimiss()
            //decorator?.stateMachine.clearEvents()
            //decorator?.stateMachine.append(Event.showAdvertising)
        }
    }
    
    var publicBusinessComponent: PublicBusinessComponent {
        if let component =
            objc_getAssociatedObject(self, &PublicBusinessComponent.AssociatedKeys.publicBusiness)
            as? PublicBusinessComponent {
            return component
        }
        
        let component = PublicBusinessComponent()
        component.decorator = self
        objc_setAssociatedObject(self,
                                 &PublicBusinessComponent.AssociatedKeys.publicBusiness,
                                 component,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return component
    }
}
