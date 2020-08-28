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
        srNavigationBarType = .sr
//        srNavigationBarAppear = .hidden
        setDefaultNavigationBar("Root")
//        navigationItem.backBarButtonItem = nil
        navBarRightButtonOptions = [.auto("Base".localized)]
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
//            self?.srNavigationItem.rightBarButtonItems?.forEach {
//                $0.isEnabled = false
//            }
            self?.srNavigationBarType = .system
        }
        showLoadDataFailView("加载中……")
        C.shouldAutorotate = true
        C.supportedInterfaceOrientations = .allButUpsideDown
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
//        show(SRViewController())
        let vc = ViewController()
        vc.view.backgroundColor = .white
        navigationController?.present(SRModalViewController.standard(vc), animated: true, completion: nil)
    }
}

