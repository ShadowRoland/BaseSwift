//
//  RegisterViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/16.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import DTCoreText
import libPhoneNumber_iOS

class RegisterViewController: BaseViewController {
    lazy var indexPathSet: SRIndexPath.Set = SRIndexPath.Set()
    @IBOutlet weak var tableView: UITableView!
    
    lazy var countryCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell")!
        countryNameLabel = cell.contentView.viewWithTag(101) as? UILabel
        countryNameLabel.adjustsFontSizeToFitWidth = true
        return cell
    }()
    weak var countryNameLabel: UILabel!
    
    lazy var countryCodeCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCodeCell")!
        countryCodeLabel = cell.contentView.viewWithTag(100) as? UILabel
        countryCodeLabel.adjustsFontSizeToFitWidth = true
        countryCodeLabel.textColor = UIColor.darkGray
        phoneTextField = cell.contentView.viewWithTag(101) as? UITextField
        phoneTextField.delegate = self
        return cell
    }()
    weak var countryCodeLabel: UILabel!
    weak var phoneTextField: UITextField!
    
    lazy var verifyCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "verifyCell")!
        verifyTextField = cell.contentView.viewWithTag(100) as? UITextField
        verifyTextField.delegate = self
        verifyButton = cell.contentView.viewWithTag(101) as? UIButton
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
    weak var verifyButton: UIButton!
    weak var verifyWidthConstraint: NSLayoutConstraint!
    
    lazy var passwordCell: UITableViewCell = {
        let cell = tableView.dequeueReusableCell(withIdentifier: "passwordCell")!
        passwordTextField = cell.contentView.viewWithTag(100) as? UITextField
        passwordTextField.delegate = self
        return cell
    }()
    weak var passwordTextField: UITextField!
    
    @IBOutlet var tableFooterView: UIView!
    @IBOutlet weak var agreementLabel: DTAttributedLabel!
    @IBOutlet weak var agreementHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!
    
    var isGettingVerifyCode = false
    var timer: Timer?
    var second = Const.verifyInterval
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultNavigationBar("Register".localized)
        isGettingVerifyCode = false
        initView()
        deviceOrientationDidChange()
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification,
                          object: phoneTextField)
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification,
                          object: verifyTextField)
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification,
                          object: passwordTextField)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let verifyButtonMargin = 5.0 as CGFloat
        static let verifyInterval = 60
        static let agreementMargin = 10.0 + 30.0 + TableCellHeight + 10.0 as CGFloat // as storyboard
    }
    
    func initView() {
        indexPathSet[IndexPath(row: 0, section: 0)] = SRIndexPath.Table(cell: countryCell)
        indexPathSet[IndexPath(row: 1, section: 0)] = SRIndexPath.Table(cell: countryCodeCell)
        indexPathSet[IndexPath(row: 2, section: 0)] = SRIndexPath.Table(cell: verifyCell)
        indexPathSet[IndexPath(row: 3, section: 0)] = SRIndexPath.Table(cell: passwordCell)
        
        agreementLabel.delegate = self
        agreementLabel.attributedString = "Register Agreement Text".localized.attributedString
        
        changeVerifyButton(false)
        submitButton.set(submit: false)
    }
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        var height = agreementLabel.intrinsicContentSize().height
        height = max(LabelHeight, height)
        agreementHeightConstraint.constant = height
        tableFooterView.frame = CGRect(0, 0, ScreenWidth, height + Const.agreementMargin)
        tableView.tableFooterView = tableFooterView
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
            !isEmptyString(verifyTextField.text),
            !isEmptyString(passwordTextField.text) else {
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
        //        httpReq(.get(.getVerificationCode),
        //                [Param.Key.countryCode : Int(countryCodeLabel.text!)!,
        //                 Param.Key.phone : phoneTextField.text!,
        //                 Param.Key.type : VerificationCodeType.login.rawValue])
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
        }, bfail: { [weak self] (method, response) in
            guard let strongSelf = self else { return }
            strongSelf.isGettingVerifyCode = false
            strongSelf.changeVerifyButton(strongSelf.checkVerifyButtonEnabled())
            SRAlert.showToast(strongSelf.logBFail(method, response: response, show: false))
        }, fail: { [weak self] (method, error) in
            guard let strongSelf = self else { return }
            strongSelf.isGettingVerifyCode = false
            strongSelf.changeVerifyButton(strongSelf.checkVerifyButtonEnabled())
        })
    }
    
    @IBAction func clickSubmitButton(_ sender: Any) {
        guard MutexTouch else { return }
        guard passwordTextField.text!.isPassword else {
            SRAlert.showToast("Please enter the correct password!".localized)
            return
        }
        Keyboard.hide { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.showProgress()
            strongSelf.httpRequest(.post("user/register",
                                   [Param.Key.countryCode : Int(strongSelf.countryCodeLabel.text!)!,
                                    Param.Key.phone : (strongSelf.phoneTextField.text)!,
                                    Param.Key.code : (strongSelf.verifyTextField.text)!,
                                    Param.Key.password : (strongSelf.passwordTextField.text)!]), success:
            { [weak self] response in
                let alert = SRAlert()
                //alert.appearance.showCloseButton = false
                alert.addButton("OK".localized,
                                backgroundColor: NavigationBar.backgroundColor,
                                action:
                    { [weak self] in
                        self?.popBack(toClasses: [LoginViewController.self])
                })
                alert.show(.notice,
                           title: "Registered successfully".localized,
                           message: "Please login again".localized)
            })
        }
    }
}

//MARK: - UITextFieldDelegate

extension RegisterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if !string.isEmpty {
            if phoneTextField == textField {
                return string.regex(String.Regex.number)
            } else if verifyTextField == textField {
                return string.regex(String.Regex.verificationCode)
            } else if passwordTextField == textField {
                return string.regex(String.Regex.passwordInputing)
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if phoneTextField == textField {
            verifyTextField.becomeFirstResponder()
        } else if verifyTextField == textField {
            passwordTextField.becomeFirstResponder()
        } else if passwordTextField == textField {
            textField.resignFirstResponder()
        }
        return true
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension RegisterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = indexPathSet[indexPath] as? SRIndexPath.Table {
            return item.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? SRIndexPath.Table, let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        if indexPath.section == 0 && indexPath.row == 0 {
            performSegue(withIdentifier: "registerShowCountrySegue", sender: self)
        }
    }
}
