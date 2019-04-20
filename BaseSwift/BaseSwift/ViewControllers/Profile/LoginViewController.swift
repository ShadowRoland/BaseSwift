//
//  LoginViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/12.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import LocalAuthentication

class LoginViewController: BaseViewController {
    @IBOutlet var closeButton: UIButton!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var authenticateButton: UIButton!
    
    @IBOutlet weak var headTopConstraint: NSLayoutConstraint!
    
    //MARK: - Arm
    
    @IBOutlet weak var leftArmImageView: UIImageView!
    @IBOutlet weak var rightArmImageView: UIImageView!
    @IBOutlet weak var leftHandImageView: UIImageView!
    @IBOutlet weak var rightHandImageView: UIImageView!
    
    @IBOutlet weak var leftArmTailConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftArmBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rightArmLeadConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightArmBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Hand
    
    @IBOutlet weak var leftHandLeadConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftHandCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftHandHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rightHandTailConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandHeightConstraint: NSLayoutConstraint!
    
    //MARK: -
    
    var isSecurity = false //正在输入密码的状态标记
    var isSecurityAnimating = false //输入密码时的动画状态标记
    var isLogining = false //正在发送登录请求的状态标记
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        isPageLongPressEnabled = true
        navigartionBarAppear = .hidden
        initView()
        
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification)
        NotifyDefault.add(self,
                          selector: #selector(textFieldEditingChanged(_:)),
                          name: UIResponder.keyboardWillChangeFrameNotification)
        
        accountTextField.text = "233" //FIXME: for debug, remember to remark when submit
        //passwordTextField.text = "666666"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authenticateButton.isHidden = !(checkAuthenticateDevice() && checkAuthenticateBusiness())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Keyboard.manager = .sr
        SRKeyboardManager.shared.aboveKeyboardView = submitButton
        
        /* 在iOS 9.2之后已失效，至今为止还未找到正确的方法
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
         appDelegate.lockedRotation = .portrait
         let value = UIInterfaceOrientation.portrait.rawValue
         UIDevice.current.setValue(value, forKey: "orientation")
         UIViewController.attemptRotationToDeviceOrientation()
         */
        UIViewController.attemptRotationToDeviceOrientation()
        
        if !authenticateButton.isHidden && !isLogining {
            authenticate()
        }
        if !isLogining {
            passwordTextField.text = ""
            textFieldEditingChanged(nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SRKeyboardManager.shared.aboveKeyboardView = nil
        /* 在iOS 9.2之后已失效，至今为止还未找到正确的方法
         let appDelegate = UIApplication.shared.delegate as! AppDelegate
         appDelegate.lockedRotation = .all
         */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    //强制竖屏
    override public var shouldAutorotate: Bool { return ShouldAutorotate && true }
    
    //只支持一个正面竖屏方向
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    //页面刚展示时使用正面竖屏方向
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let leftArmTailConstraintUp = 5.0 as CGFloat
        static let leftArmBottomConstraintUp = 15.0 as CGFloat
        static let leftArmTailConstraintDown = 58.0 as CGFloat
        static let leftArmBottomConstraintDown = 53.0 as CGFloat
        
        static let rightArmLeadConstraintUp = 10.0 as CGFloat
        static let rightArmBottomConstraintUp = leftArmBottomConstraintUp
        static let rightArmLeadConstraintDown = 61.0 as CGFloat
        static let rightArmBottomConstraintDown = leftArmBottomConstraintDown
        
        static let leftHandLeadConstraintShow = 6.0 as CGFloat
        static let leftHandLeadCenterYConstraintShow = 0 as CGFloat
        static let leftHandHeightConstraintShow = 40.0 as CGFloat
        static let leftHandLeadConstraintHide = ((leftHandHeightConstraintShow / 2.0) + 52.0) as CGFloat
        static let leftHandLeadCenterYConstraintHide = 25 as CGFloat
        static let leftHandHeightConstraintHide = 0 as CGFloat
        
        static let rightHandTailConstraintShow = 4.0 as CGFloat
        static let rightHandLeadCenterYConstraintShow = leftHandLeadCenterYConstraintShow
        static let rightHandHeightConstraintShow = leftHandHeightConstraintShow
        static let rightHandTailConstraintHide = ((rightHandHeightConstraintShow / 2.0) + 52.0) as CGFloat
        static let rightHandLeadCenterYConstraintHide = leftHandLeadCenterYConstraintHide
        static let rightHandHeightConstraintHide = leftHandHeightConstraintHide
    }
    
    func initView() {
        if Configs.entrance == .sns {
            closeButton.isHidden = true
        } else if Configs.entrance == .news {
            closeButton.isHidden = false
        }
        loginView.layer.borderWidth = 0.5
        loginView.layer.borderColor = UIColor.gray.cgColor
        
        //屏幕适配
        switch Common.screenScale() {
        case .iPad:
            headTopConstraint.constant = 200.0
        case .iPhone6P:
            headTopConstraint.constant = 120.0
        case .iPhone5:
            headTopConstraint.constant = 60.0
        case .iPhone4:
            headTopConstraint.constant = 40.0
        default:
            headTopConstraint.constant = 100.0
        }
        
        //将手臂降下来
        self.leftArmTailConstraint.constant = Const.leftArmTailConstraintDown
        self.leftArmBottomConstraint.constant = Const.leftArmBottomConstraintDown
        self.rightArmLeadConstraint.constant = Const.rightArmLeadConstraintDown
        self.rightArmBottomConstraint.constant = Const.rightArmBottomConstraintDown
        
        submitButton.set(submit: false)
        submitButton.layer.cornerRadius = SubmitButton.cornerRadius
        submitButton.clipsToBounds = true
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        //FIXME: FOR DEBUG，广播“触发状态机的完成事件”的通知
        if let sender = params[Param.Key.sender] as? String,
            let event = params[Param.Key.event] as? Int {
            LogDebug(NSStringFromClass(type(of: self)) + ".\(#function), sender: \(sender), event: \(event)")
            NotifyDefault.post(name: Notification.Name.Base.didEndStateMachineEvent,
                               object: params)
        }
    }
    
    func securityAnimate() {
        guard !isSecurityAnimating else {
            return
        }
        
        if isSecurity {//正在输入密码状态
            isSecurityAnimating = true
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.leftArmTailConstraint.constant = Const.leftArmTailConstraintUp
                self?.leftArmBottomConstraint.constant = Const.leftArmBottomConstraintUp
                
                self?.rightArmLeadConstraint.constant = Const.rightArmLeadConstraintUp
                self?.rightArmBottomConstraint.constant = Const.rightArmBottomConstraintUp
                
                self?.leftHandLeadConstraint.constant = Const.leftHandLeadConstraintHide
                self?.leftHandCenterYConstraint.constant = Const.leftHandLeadCenterYConstraintHide
                self?.leftHandHeightConstraint.constant = Const.leftHandHeightConstraintHide
                
                self?.rightHandTailConstraint.constant = Const.rightHandTailConstraintHide
                self?.rightHandCenterYConstraint.constant = Const.rightHandLeadCenterYConstraintHide
                self?.rightHandHeightConstraint.constant = Const.rightHandHeightConstraintHide
                
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) in
                    if finished {
                        self?.isSecurityAnimating = false
                        if !(self?.isSecurity)! { self?.securityAnimate() }
                    }
            })
        } else {//脱离输入密码状态
            isSecurityAnimating = true
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.leftArmTailConstraint.constant = Const.leftArmTailConstraintDown
                self?.leftArmBottomConstraint.constant = Const.leftArmBottomConstraintDown
                
                self?.rightArmLeadConstraint.constant = Const.rightArmLeadConstraintDown
                self?.rightArmBottomConstraint.constant = Const.rightArmBottomConstraintDown
                
                self?.leftHandLeadConstraint.constant = Const.leftHandLeadConstraintShow
                self?.leftHandCenterYConstraint.constant = Const.leftHandLeadCenterYConstraintShow
                self?.leftHandHeightConstraint.constant = Const.leftHandHeightConstraintShow
                
                self?.rightHandTailConstraint.constant = Const.rightHandTailConstraintShow
                self?.rightHandCenterYConstraint.constant = Const.rightHandLeadCenterYConstraintShow
                self?.rightHandHeightConstraint.constant = Const.rightHandHeightConstraintShow
                
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) in
                    if finished {
                        self?.isSecurityAnimating = false
                        if (self?.isSecurity)! { self?.securityAnimate() }
                    }
            })
        }
    }
    
    func checkSubmitButtonEnabled() -> Bool {
        return !isEmptyString(accountTextField.text)
            && !isEmptyString(passwordTextField.text)
    }
    
    //MARK: LocalAuthentication
    
    //查看硬件和系统是否支持
    func checkAuthenticateDevice() -> Bool {
        let context = LAContext()
        var error: NSError?
        let isSupport = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                  error: &error)
        if !isSupport && error?.code == Int(kLAErrorTouchIDNotAvailable) {
            return false
        }
        return true
    }
    
    //查看业务上是否支持
    func checkAuthenticateBusiness() -> Bool {
        guard UserStandard[USKey.forbidAuthenticateToLogin] == nil else {
            return false
        }
        
        guard let userName = UserStandard[USKey.lastLoginUserName],
            !isEmptyString(userName) else {
                return false
        }
        
        guard let password = UserStandard[USKey.lastLoginPassword],
            !isEmptyString(password) else {
                return false
        }
        
        return true
    }
    
    func checkAuthenticateSetting() -> Bool {
        let context = LAContext()
        var error: NSError?
        let isSupport = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                  error: &error)
        if !isSupport {
            SRAlert.show(message: "Authenticate not setup".localized, type: .warning)
            return false
        }
        return true
    }
    
    func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        navigationController?.view.isUserInteractionEnabled = false //在弹出指纹验证的弹窗时禁止屏幕移动和按钮
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Authenticate localized reason for login".localized)
        { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.accountTextField.text =
                        UserStandard[USKey.lastLoginUserName] as? String
                    self.passwordTextField.text = UserStandard[USKey.lastLoginPassword] as? String
                    self.showProgress()
                    self.login()
                }
            }
            DispatchQueue.main.async {
                self.navigationController?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    //MARK: Login
    
    func login() {
        isLogining = true
        //httpReq(.post(.login),
        //        [Param.Key.userName : accountTextField.text!,
        //         Param.Key.password : passwordTextField.text!.md5(),
        //         Param.Key.type : 0])
        httpRequest(.post(.login),
                    [Param.Key.userName : accountTextField.text!,
                     Param.Key.password : passwordTextField.text!.md5(),
                     Param.Key.type : 0],
                    success:
            { [weak self] response in
                guard let strongSelf = self else { return }
                strongSelf.isLogining = false
                strongSelf.dismissProgress()
                UserStandard[USKey.lastLoginUserName] = strongSelf.accountTextField.text!
                UserStandard[USKey.lastLoginPassword] = strongSelf.passwordTextField.text!
                BF.callBusiness(BF.businessId(.im, Manager.IM.funcId(.login)))
                if Configs.entrance == .sns {
                    strongSelf.show("SNSViewController", storyboard: "SNS")
                } else if Configs.entrance == .news || Configs.entrance == .aggregation {
                    NotifyDefault.post(name:Configs.reloadProfileNotification, object: nil)
                    strongSelf.popBack()
                }
        }, bfail: { [weak self] response in
            guard let strongSelf = self else { return }
            strongSelf.isLogining = false
            Common.change(submitButton: strongSelf.submitButton,
                          enabled: strongSelf.checkSubmitButtonEnabled())
            strongSelf.httpRespondBfail(.post(.login), response: response)
        }, fail: { [weak self] error in
            guard let strongSelf = self else { return }
            strongSelf.isLogining = false
            Common.change(submitButton: strongSelf.submitButton,
                          enabled: strongSelf.checkSubmitButtonEnabled())
            strongSelf.httpRespondFail(.post(.login), error: error)
        })
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickCloseButton(_ sender: Any) {
        guard MutexTouch else { return }
        popBack()
    }
    
    @objc func textFieldEditingChanged(_ notification: Notification?) {
        submitButton.set(submit: checkSubmitButtonEnabled())
    }
    
    @IBAction func clickForgetPasswordButton(_ sender: Any) {
        guard MutexTouch else { return }
        performSegue(withIdentifier: "loginShowForgetPasswordSegue", sender: self)
    }
    
    @IBAction func clickRegisterButton(_ sender: Any) {
        guard MutexTouch else { return }
        performSegue(withIdentifier: "loginShowRegisterSegue", sender: self)
    }
    
    @IBAction func clickSubmitButton(_ sender: Any) {
        guard MutexTouch else { return }
        Keyboard.hide { [weak self] in
            self?.showProgress()
            self?.login()
        }
    }
    
    @IBAction func clickAuthenticateButton(_ sender: Any) {
        guard MutexTouch else { return }
        guard checkAuthenticateSetting() else { return }
        authenticate()
    }
}

//MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if accountTextField == textField {
            passwordTextField.becomeFirstResponder()
        } else if passwordTextField == textField {
            Keyboard.hide({ [weak self] in
                if (self?.checkSubmitButtonEnabled())! {
                    self?.clickSubmitButton((self?.submitButton)!)
                }
            })
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if passwordTextField == textField {
            isSecurity = true
            securityAnimate()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if passwordTextField == textField {
            isSecurity = false
            securityAnimate()
        }
    }
}

