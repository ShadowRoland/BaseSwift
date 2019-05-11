//
//  ForgetPasswordViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/16.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import libPhoneNumber_iOS

public enum VerificationCodeType: Int {
    case login = 0
    case forgetPassword = 1
}

public enum ResetPasswordType: Int {
    case smsCode = 0
    case password = 1
}

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
                          name: UITextField.textDidChangeNotification,
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
                          name: UITextField.textDidChangeNotification,
                          object: verifyTextField)
        let verifyButton = cell.contentView.viewWithTag(101) as! UIButton
        verifyButton.clicked(self, action: #selector(clickVerifyButton(_:)))
        verifyWidthConstraint =
            verifyButton.constraints.first { "verifyWidthConstraint" == $0.identifier }
        
        let getTitle = "Get verification code".localized
        let againTitle = String(format: "Get again (%d)".localized, Const.verifyInterval)
        let title = getTitle.count > againTitle.count ? getTitle : againTitle
        let width = title.textSize(verifyButton.titleLabel!.font,
                                   maxWidth: ScreenWidth - SubviewMargin).width
        verifyWidthConstraint.constant = ceil(width) + 2.0 * Const.verifyButtonMargin
        return cell
    }()
    weak var verifyTextField: UITextField!
    lazy var verifyButton: UIButton = verifyCell.contentView.viewWithTag(101) as! UIButton
    weak var verifyWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var submitButton: UIButton!
    
    private lazy var cells = [countryCell, phoneCell, verifyCell]
    private var isGettingVerifyCode = false
    private var timer: Timer?
    private var second = Const.verifyInterval
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDefaultNavigationBar("Forget Password".localized)
        isGettingVerifyCode = false
        changeVerifyButton(false)
        submitButton.set(submit: false)
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
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func checkPhoneNO() -> Bool {
        guard let phone = phoneTextField.text,
            !isEmptyString(phone) else {
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
            verifyButton.backgroundColor = NavigationBar.backgroundColor
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
            !isEmptyString(verifyTextField.text) else {
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
            submitButton.set(submit: checkSubmitButtonEnabled())
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
        guard MutexTouch else { return }
        isGettingVerifyCode = true
        changeVerifyButton(checkVerifyButtonEnabled())
        httpRequest(.get("getVerificationCode",
                         [Param.Key.countryCode : Int(countryCodeLabel.text!)!,
                          Param.Key.phone : phoneTextField.text!,
                          Param.Key.type : VerificationCodeType.login.rawValue]),
                    success:
            { [weak self] response in
                guard let strongSelf = self else { return }
                strongSelf.isGettingVerifyCode = false
                strongSelf.startTimer()
                strongSelf.changeVerifyButton(strongSelf.checkVerifyButtonEnabled())
                if let code = (response as? JSON)?[HTTP.Key.Response.data][Param.Key.code] {
                    strongSelf.verifyTextField.text = String(object: code.rawValue as AnyObject)
                    strongSelf.submitButton.set(submit: strongSelf.checkSubmitButtonEnabled())
                }
            }, bfail: { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                strongSelf.isGettingVerifyCode = false
                strongSelf.changeVerifyButton(strongSelf.checkVerifyButtonEnabled())
                SRAlert.showToast(strongSelf.logBFail(url,
                                                     response: response,
                                                     show: false))
            }, fail: { [weak self] (_, error) in
                guard let strongSelf = self else { return }
                strongSelf.isGettingVerifyCode = false
                strongSelf.changeVerifyButton(strongSelf.checkVerifyButtonEnabled())
        })
    }
    
    func clickSubmitButton(_ sender: Any) {
        guard MutexTouch else { return }
        Keyboard.hide {
            self.show("ResetPasswordViewController",
                      storyboard: "Profile",
                      params: [Param.Key.countryCode : Int(self.countryCodeLabel.text!)!,
                               Param.Key.phone : self.phoneTextField.text!,
                               Param.Key.code : self.verifyTextField.text!])
        }
    }
}

//MARK: - UITextFieldDelegate

extension ForgetPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if !string.isEmpty {
            if phoneTextField == textField {
                return string.regex(String.Regex.number)
            } else if verifyTextField == textField {
                return string.regex(String.Regex.verificationCode)
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
        guard MutexTouch else { return }
        
        if indexPath.row == 0 {
            let vc = show("SelectCountryCodeViewController", storyboard: "Profile") as! SelectCountryCodeViewController
            vc.didSelectBlock = { [weak self] model in
                self?.countryNameLabel.text = model.name
                self?.countryCodeLabel.text = model.code
            }
        }
    }
}

