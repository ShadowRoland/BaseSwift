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
        setDefaultNavigationBar("Base")
        pageBackGestureStyle = .edge
    }
}
