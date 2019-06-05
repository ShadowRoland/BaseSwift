//
//  ViewController.swift
//  SRKitExample
//
//  Created by Gary on 2019/4/15.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit

class ViewController: SRBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        LogInfo("喵喵喵")
//        navigationBarType = .sr
//        navigationBarAppear = .hidden
        setDefaultNavigationBar("Root")
//        navigationItem.backBarButtonItem = nil
        navBarRightButtonOptions = [[.title : "Base"]]
        showLoadDataFailView("加载中……")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //showProgress(.translucence)
    }
    
    override func performViewDidLoad() {
        //sshowLoadDataFailView("加载中……")
    }
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        show(SRViewController())
    }
}

