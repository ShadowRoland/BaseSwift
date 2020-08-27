//
//  SimpleViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/6/13.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON

class SimpleViewController: BaseViewController {
    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setDefaultNavigationBar("Single initialization request page".localized)
        navBarRightButtonOptions = [.text([.title("List".localized)])]
        getSimpleData()
        setLoadDataFail(.get("data/getSimpleData")) { [weak self] in
            self?.getSimpleData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    //MARK: - 业务处理
    
    //MARK: Http request
    
    func getSimpleData() {
        showProgress()
        httpRequest(.get("data/getSimpleData"), success: { [weak self] response in
            self?.dismissProgress()
            self?.label.text =
                (response as! JSON)[HTTP.Key.Response.data][Param.Key.title].string
        })
    }

    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        srShow(SimpleTableViewController(style: .plain))
    }
}
