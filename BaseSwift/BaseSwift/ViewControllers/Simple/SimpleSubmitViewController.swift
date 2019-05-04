//
//  SimpleSubmitViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/6/13.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON

class SimpleSubmitViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var cell: UITableViewCell!
    var textField: UITextField!
    var placeholderTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        defaultNavigationBar("Submit".localized)
        initView()
        setLoadDataFail(.get("data/getSimpleData", nil)) { [weak self] in
            self?.showProgress()
            self?.getSimpleData()
        }
        getSimpleData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier)
        textField = cell.contentView.viewWithTag(101) as? UITextField
        placeholderTextField = cell.contentView.viewWithTag(100) as? UITextField
        textField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification,
                          object: textField)
        submitButton.set(submit: false)
    }
    
    //MARK: - 业务处理
    
    //MARK: Http request
    
    func getSimpleData() {
        showProgress()
        httpRequest(.get("data/getSimpleData", nil), success: { [weak self] response in
            guard let strongSelf = self else { return }
            strongSelf.dismissProgress()
            strongSelf.placeholderTextField.text =
                (response as! JSON)[HTTP.Key.Response.data][Param.Key.title].string
            strongSelf.textField.text = ""
            strongSelf.submitButton.set(submit: false)
        })
    }
    
    func simpleSubmit() {
        self.showProgress()
        httpRequest(.post("data/simpleSubmit", nil), success: { [weak self] response in
            guard let strongSelf = self else { return }
            strongSelf.dismissProgress()
            SRAlert.show(message: "Winner Winner, Chicken Dinner!".localized)
        })
    }
    
    // MARK: - 事件响应
    
    @objc func textFieldEditingChanged(_ notification: Notification?) {
        let textField = notification?.object as! UITextField
        submitButton.set(submit: placeholderTextField.text! == textField.text)
    }
    
    @IBAction func clickSubmitButton(_ sender: Any) {
        Keyboard.hide { [weak self] in
            self?.simpleSubmit()
        }
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension SimpleSubmitViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
}

// MARK: - UITextFieldDelegate

extension SimpleSubmitViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if submitButton.isEnabled {
            clickSubmitButton(submitButton!)
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
