//
//  SRViewController.swift
//  SRKitExample
//
//  Created by Gary on 2019/5/8.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit

class SRViewController: SRBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        srNavigationBarType = .sr
        srNavigationBarAppear = .visible
        setDefaultNavigationBar("Base")
        //srPageBackGestureStyle = .edge
        showLoadDataFailView("标记为需要重新布局，异步调用layoutIfNeeded刷新布局，不立即刷新，但layoutSubviews一定会被调用-layoutIfNeeded方法：",
                             image: UIImage("sr_load_data_fail"))
    }
}
