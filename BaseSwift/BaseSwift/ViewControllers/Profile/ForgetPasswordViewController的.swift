//
//  ForgetPasswordViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/16.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON

class ForgetPasswordViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    lazy var countryCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell")!
        countryNameLabel = cell.contentView.viewWithTag(101) as? UILabel
        return cell
    }()
    weak var countryNameLabel: UILabel!
    
    lazy var phoneCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "phoneCell")!
        countryCodeLabel = cell.contentView.viewWithTag(100) as? UILabel
        phoneTextField = cell.contentView.viewWithTag(101) as? UITextField
        phoneTextField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: .UITextFieldTextDidChange,
                          object: phoneTextField)
        return cell
    }()
    weak var countryCodeLabel: UILabel!
    weak var phoneTextField: UITextField!
    
    lazy var verifyCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "verifyCell")!
        verifyTextField = cell.contentView.viewWithTag(100) as? UITextField
        verifyTextField.delegate = self
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: .UITextFieldTextDidChange,
                          object: verifyTextField)
        verifyButton = cell.contentView.viewWithTag(101) as? UIButton
        verifyButton.clicked(self, action: #selector(clickVerifyButton(_:)))
        verifyWidthConstraint =
            verifyButton.constraints.first { "verifyWidthConstraint" == $0.identifier }
        
        let getTitle = "Get verification code".localized
        let againTitle = String(format: "Get again (%d)".localized, Const.verifyInterval)
        let title = getTitle.length > againTitle.length ? getTitle : againTitle
        let width = Common.fitSize(title,
                                   font: verifyButton.titleLabel!.font,
                                   maxWidth: ScreenWidth() - SubviewMargin).width
        verifyWidthConstraint.constant = ceil(width) + 2.0 * Const.verifyButtonMargin
        return cell
    }()
    weak var verifyTextField: UITextField!
    weak var verifyButton: UIButton!
    weak var verifyWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var submitButton: UIButton!
    
    private lazy var cells = [countryCell, phoneCell, verifyCell]
    private var isGettingVerifyCode = false
    private var timer: Timer?
    private var second = Const.verifyInterval
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultNavigationBar("Forget Password".localized)
        isGettingVerifyCode = false
        changeVerifyButton(false)
        Common.change(submitButton: submitButton, enabled: false)
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let verifyButtonMargin = 5.0 as CGFloat
        static let verifyInterval = 60
    }
    
    //MARK: - 业务处理
    
    func startTimer() {
        guard timer == nil else {
            return
        }
        
        changeVerifyButton(false)
        second = Const.verifyInterval
        countDown()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(countDown),
                                     userInfo: nil,
                                     repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    func checkPhoneNO() -> Bool {
        guard let phone = phoneTextField.text,
            !Common.isEmptyString(phone) else {
                return false
        }
        
        let phoneUtil = NBPhoneNumberUtil()
        var phoneNumber: NBPhoneNumber?
        do {
            let countryCode = NSNumber(value: Int(countryCodeLabel.text!)!)
            let regionCode = phoneUtil.getRegionCode(forCountryCode: countryCode)
            phoneNumber = try phoneUtil.parse(phone, defaultRegion: regionCode)
            //let formattedString = try phoneUtil.format(phoneNumber, numberFormat: .E164)
            //NSLog("[%@]", formattedString)
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return false
        }
        return phoneUtil.isNumberGeographical(phoneNumber!)
    }
    
    func changeVerifyButton(_ enabled: Bool) {
        if enabled {
            verifyButton.backgroundColor = NavigartionBar.backgroundColor
            verifyButton.isEnabled = true
        } else {
            verifyButton.backgroundColor = UIColor.lightGray
            verifyButton.isEnabled = false
        }
    }
    
    func checkVerifyButtonEnabled() -> Bool {
        guard !isGettingVerifyCode,
            timer == nil else {
                return false
        }
        
        return checkPhoneNO()
    }
    
    func checkSubmitButtonEnabled() -> Bool {
        guard checkPhoneNO(),
            !Common.isEmptyString(verifyTextField.text) else {
                return false
        }
        
        return true
    }
    
    // MARK: - 事件响应
    
    func selectedCountyCode(_ notification: Notification) {
        let model = notification.object as! CountryCodeModel
        countryNameLabel.text = model.name
        countryCodeLabel.text = model.code
        if verifyButton.isEnabled != checkVerifyButtonEnabled() {
            changeVerifyButton(!verifyButton.isEnabled)
        }
    }
    
    @objc func textFieldEditingChanged(_ notification: Notification?) {
        let textField = notification?.object as! UITextField
        if phoneTextField == textField {
            if verifyButton.isEnabled != checkVerifyButtonEnabled() {
                changeVerifyButton(!verifyButton.isEnabled)
            }
        }
        
        if submitButton.isEnabled != checkSubmitButtonEnabled() {
            Common.change(submitButton: submitButton, enabled: checkSubmitButtonEnabled())
        }
    }
    
    @objc func countDown() {
        if second == 0 {
            timer?.invalidate()
            timer = nil
            verifyButton.title = "Get verification code".localized
            changeVerifyButton(true)
        } else {
            verifyButton.title = String(format: "Get again (%d)".localized, second)
            second -= 1
        }
    }
    
    @objc func clickVerifyButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        isGettingVerifyCode = true
        changeVerifyButton(checkVerifyButtonEnabled())
        httpRequest(.get(.getVerificationCode),
                    [ParamKey.countryCode : Int(countryCodeLabel.text!)!,
                     ParamKey.phone : phoneTextField.text!,
                     ParamKey.type : VerificationCodeType.login.rawValue],
                    success:
            { response in
                self.isGettingVerifyCode = false
                self.startTimer()
                self.changeVerifyButton(self.checkVerifyButtonEnabled())
                if let code = (response as? JSON)?[HttpKey.Response.data][ParamKey.code] {
                    self.verifyTextField.text = String(object: code.rawValue as AnyObject)
                    Common.change(submitButton: self.submitButton,
                                  enabled: self.checkSubmitButtonEnabled())
                }
        }, bfail: { response in
            self.isGettingVerifyCode = false
            self.changeVerifyButton(self.checkVerifyButtonEnabled())
            Common.showToast(self.logBFail(.get(.getVerificationCode),
                                           response: response,
                                           show: false))
        }, fail: { error in
            self.isGettingVerifyCode = false
            self.changeVerifyButton(self.checkVerifyButtonEnabled())
        })
    }
    
    func clickSubmitButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        Keyboard.hide {
            self.show("ResetPasswordViewController",
                      storyboard: "Profile",
                      params: [ParamKey.countryCode : Int(self.countryCodeLabel.text!)!,
                               ParamKey.phone : self.phoneTextField.text!,
                               ParamKey.code : self.verifyTextField.text!])
        }
    }
}

//MARK: - UITextFieldDelegate

extension ForgetPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if string.length > 0 {
            if phoneTextField == textField {
                return string.regex(Regex.number)
            } else if verifyTextField == textField {
                return string.regex(Regex.verificationCode)
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if phoneTextField == textField {
            verifyTextField.becomeFirstResponder()
        } else if verifyTextField == textField {
            textField.resignFirstResponder()
        }
        return true
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ForgetPasswordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "forgetPasswordShowCountrySegue", sender: self)
        }
    }
}

