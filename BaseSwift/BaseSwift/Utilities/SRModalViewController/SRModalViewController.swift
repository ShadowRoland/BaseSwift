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
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    
    //MARK: - UINavigationBarDelegate
    
    //拦截导航栏默认提供的返回按钮的点击
    public override func navigationBar(_ navigationBar: UINavigationBar,
                              shouldPop item: UINavigationItem) -> Bool {
        if viewControllers.count == 2 {
            DispatchQueue.main.async {
                self.topViewController?.popBack(true)
            }
            return false
        }
        return super.navigationBar(navigationBar, shouldPop: item)
    }
}
