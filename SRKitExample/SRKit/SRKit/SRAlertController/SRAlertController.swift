//
//  SRAlertController.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/21.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

open class SRAlertController: UIAlertController { //代替UIAlertController
    static var allAlerts: [SRAlertController] = []
    
    class func append(_ alert: SRAlertController) {
        if SRAlertController.allAlerts.firstIndex(of: alert) == nil {
            SRAlertController.allAlerts.append(alert)
        }
    }
    
    class func remove(_ alert: SRAlertController) {
        if let index = SRAlertController.allAlerts.firstIndex(of: alert) {
            SRAlertController.allAlerts.remove(at: index)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        SRAlertController.append(self)
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    
    open class func dismissAll() {
        Array<SRAlertController>(allAlerts).forEach { $0.dismiss(animated: false, completion: nil) }
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        SRAlertController.remove(self)
    }
}
