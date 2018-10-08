//
//  ResetPasswordViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/16.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON

class ResetPasswordViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    lazy var passwordCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "passwordCell")!
        passwordTextField = cell.contentView.viewWithClass(UITextField.self) as? UITextField
        passwordTextField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: .UITextFieldTextDidChange,
                          object: passwordTextField)
        return cell
    }()
    weak var passwordTextField: UITextField!
    
    lazy var newPasswordCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newPasswordCell")!
        newPasswordTextField = cell.contentView.viewWithClass(UITextField.self) as? UITextField
        newPasswordTextField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: .UITextFieldTextDidChange,
                          object: newPasswordTextField)
        return cell
    }()
    weak var newPasswordTextField: UITextField!
    
    lazy var confirmPasswordCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "confirmPasswordCell")!
        confirmPasswordTextField = cell.contentView.viewWithClass(UITextField.self) as? UITextField
        confirmPasswordTextField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: .UITextFieldTextDidChange,
                          object: confirmPasswordTextField)
        return cell
    }()
    weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    private lazy var cells: [UITableViewCell] = [passwordCell, newPasswordCell, confirmPasswordCell]
    private var resetPasswordType: ResetPasswordType = .smsCode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultNavigationBar("Reset Password".localized)
        resetPasswordType = params.isEmpty ? .password : .smsCode
        Common.change(submitButton: submitButton, enabled: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    //MARK: - 业务处理
    
    func checkSubmitButtonEnabled() -> Bool {
        if resetPasswordType == .password && Common.isEmptyString(passwordTextField.text) {
            return false
        }
        
        guard !Common.isEmptyString(newPasswordTextField.text),
            !Common.isEmptyString(confirmPasswordTextField.text) else {
                return false
        }
        
        return true
    }
    
    // MARK: - 事件响应
    
    @objc func textFieldEditingChanged(_ notification: Notification?) {
        if submitButton.isEnabled != checkSubmitButtonEnabled() {
            Common.change(submitButton: submitButton, enabled: checkSubmitButtonEnabled())
        }
    }
    
    @IBAction func clickSubmitButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        if resetPasswordType == .password && !passwordTextField.text!.isPassword {
            Common.showToast("Please enter the correct password!".localized)
            return
        }
        
        if !newPasswordTextField.text!.isPassword {
            Common.showToast("Please enter the correct new password!".localized)
            return
        }
        
        if newPasswordTextField.text! != confirmPasswordTextField.text {
            Common.showToast("The password you enter twice must be the same!".localized)
            return
        }
        
        Keyboard.hide {
            self.showProgress()
            var params: ParamDictionary?
            if self.resetPasswordType == .smsCode {
                params = self.params
                params?[ParamKey.type] = ResetPasswordType.smsCode.rawValue
                params?[ParamKey.newPassword] = self.newPasswordTextField.text!
            } else {
                params = [ParamKey.type : ResetPasswordType.password.rawValue,
                          ParamKey.password : self.passwordTextField.text!,
                          ParamKey.newPassword : self.newPasswordTextField.text!]
            }
            //            self?.httpReq(.post(.resetPassword), params)
            self.httpRequest(.post(.resetPassword),
                             params,
                             success:
                { response in
                    let alert = SRAlert()
                    alert.appearance.showCloseButton = false
                    alert.addButton("OK".localized,
                                    backgroundColor: NavigartionBar.backgroundColor,
                                    action:
                        { [weak self] in
                            if self?.resetPasswordType == .smsCode {
                                self?.popBack(toClasses: [LoginViewController.self])
                            } else {
                                if Entrance == .sns {
                                    self?.popBack(toClasses: [LoginViewController.self])
                                } else if Entrance == .news || Entrance == .aggregation {
                                    Common.currentProfile()?.isLogin = false
                                    NotifyDefault.post(Notification.Name.This.reloadProfile)
                                    self?.popBack(toClasses: [MoreViewController.self])
                                }
                            }
                    })
                    alert.show(.notice,
                               title: "Reset successfully".localized,
                               message: "Please login again".localized)
            })
        }
    }
}

//MARK: - UITextFieldDelegate

extension ResetPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if string.length > 0 {
            return string.regex(Regex.passwordInputing)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if passwordTextField == textField {
            newPasswordTextField.becomeFirstResponder()
        } else if newPasswordTextField == textField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if confirmPasswordTextField == textField {
            textField.resignFirstResponder()
        }
        return true
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ResetPasswordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resetPasswordType == .password ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return resetPasswordType == .password ? cells[0] : cells[1]
        } else if indexPath.row == 1 {
            return resetPasswordType == .password ? cells[1] : cells[2]
        } else if indexPath.row == 2 {
            return cells[2]
        }
        
        return UITableViewCell()
    }
}

