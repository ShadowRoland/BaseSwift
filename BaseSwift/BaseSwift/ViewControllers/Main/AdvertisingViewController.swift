//
//  AdvertisingViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/5.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class AdvertisingViewController: BaseViewController {
    override func viewDidLoad() {
        setDefaultNavigationBar("是兄弟就来⚔我")
    }

    override func performViewDidLoad() {
        //showAdvertising的结束定义为push完成新页面即可
        if let viewControllers = navigationController?.viewControllers {
            for i in (0 ..< viewControllers.count).reversed() {
                if self === viewControllers[i] && i > 0,
                    let previousVC = viewControllers[i - 1] as? BaseViewController,
                    let currentEvent = previousVC.srStateMachine.currentEvent,
                    currentEvent.option == .showAdvertising {
                    previousVC.srStateMachine.endCurrentEvent()
                    break
                }
            }
        }
    }
}
