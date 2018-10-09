//
//  AdvertisingViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/5.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

class AdvertisingViewController: BaseViewController {

    override func performViewDidLoad() {
        //showAdvertising的结束定义为push完成新页面即可
        if let viewControllers = navigationController?.viewControllers {
            for i in 0 ..< viewControllers.count {
                if self === viewControllers[i] && i > 0,
                    let previousVC = viewControllers[i - 1] as? BaseViewController,
                    Event.showAdvertising == previousVC.stateMachine.currentEvent {
                    previousVC.stateMachine.endCurrentEvent()
                    break
                }
            }
        }
    }
}