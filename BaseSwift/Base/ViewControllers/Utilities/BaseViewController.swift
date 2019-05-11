//
//  BaseViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class BaseViewController: SRBaseViewController {
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        HttpManager.shared.cancel(sender: String(pointer: self))
    }
    
    func showWebpage(_ url: URL,
                     title: String? = nil,
                     params: ParamDictionary? = [:],
                     event: Event? = nil) {
        var dictionary: ParamDictionary = [Param.Key.url : url]
        if let title = title {
            dictionary[Param.Key.title] = title
        }
        if let params = params {
            dictionary += params
        }
        show("WebpageViewController", storyboard: "Utility", params: dictionary, event: event)
    }
    
    //MARK: - Http Request

    public override func httpRequest(_ method: HTTP.Method,
                                     anonymous: Bool = false,
                                     encoding: ParamEncoding? = nil,
                                     headers: ParamHeaders? = nil,
                                     options: [HTTP.Key.Option : Any]? = nil,
                                     success: ((Any) -> Void)? = nil,
                                     bfail: ((HTTP.Method, Any) -> Void)? = nil,
                                     fail: ((HTTP.Method, BFError) -> Void)? = nil) {
        var successHandler: ((Any) -> Void)!
        if let success = success {
            successHandler = success
        } else {
            successHandler = { [weak self] response in
                self?.httpRespondSuccess(response)
            }
        }
        
        var bfailHandler: ((HTTP.Method, Any) -> Void)!
        if let bfail = bfail {
            bfailHandler = bfail
        } else {
            bfailHandler = { [weak self] (method, response) in
                self?.httpRespondBfail(method, response: response)
            }
        }
        
        var failHandler: ((HTTP.Method, BFError) -> Void)!
        if let fail = fail {
            failHandler = fail
        } else {
            failHandler = { [weak self] (method, error) in
                self?.httpRespondFail(method, error: error)
            }
        }
        
        HttpManager.shared.request(method,
                                   sender: anonymous ? nil : String(pointer: self),
                                   encoding: encoding,
                                   headers: headers,
                                   options: options,
                                   success: successHandler,
                                   bfail: bfailHandler,
                                   fail: failHandler)
    }
    
    //MARK: SRStateMachineDelegate
    
    public override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Event) {
        #if BASE_FRAMEWORK
        #else
        self.stateMachine(stateMachine, didFireBase: event)
        #endif
    }
    
    public override func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Event) {
        #if BASE_FRAMEWORK
        #else
        self.stateMachine(stateMachine, didEndBase: event)
        #endif
    }
}

#if BASE_FRAMEWORK
#else
//MARK: - 可选业务

extension BaseViewController {
    func presentLoginVC(_ params: ParamDictionary? = nil) {
        modal("LoginViewController", storyboard: "Profile", params: params)
    }
    
    func stateMachine(_ stateMachine: SRStateMachine, didFireBase event: Event) {
        switch event.option {
        case .openWebpage: //FIXME: FOR DEBUG，在所有的视图上弹出网页视图，也可以处理其他全局型的业务，如跳转到聊天页面，此处业务不是必需的，可按照具体需求操作
            guard isTop,
                let string = event.params?[Param.Key.url] as? String,
                let url = URL(string: string) else {
                    break
            }
            
            if let vc = self as? WebpageViewController {
                Common.clearPops()
                dismissModals()
                var params = [Param.Key.url : url] as ParamDictionary
                if let title = event.params?[Param.Key.title] as? String {
                    params[Param.Key.title] = title
                }
                vc.params = params
                vc.reload()
                stateMachine.end(event)
            } else {
                Common.clearPops()
                dismissModals()
                showWebpage(url, title: event.params?[Param.Key.title] as? String, event: event)
            }
            
        case .showProfile:
            guard isTop else { break }
            
            if isKind(of: ProfileViewController.self) { //当前页面是Profile页面
                stateMachine.end(event)
            } else if let viewControllers = navigationController?.viewControllers,
                let last = viewControllers.filter ({ $0.isKind(of: ProfileViewController.self) }).last { //Profile页面在当前页面之前
                Common.clearPops()
                dismissModals()
                popBack(to: last)
                DispatchQueue.main.asyncAfter(deadline: .now() + ViewControllerTransitionInterval, execute: { [weak self] in
                    self?.stateMachine.end(event)
                })
            } else { //视图栈中没有Profile页面，push新的Profile页面入栈
                Common.clearPops()
                dismissModals()
                if !ProfileManager.isLogin { //若是非登录状态，弹出登录页面，因为查看个人信息需要先登录
                    presentLoginVC()
                } else { //push新的Profile页面入栈
                    show("ProfileViewController", storyboard: "Profile", event: event)
                }
            }
            
        case .showSetting:
            guard isTop else { break }
            
            if isKind(of: SettingViewController.self) { //当前页面是Setting页面
                stateMachine.end(event)
            } else if let viewControllers = navigationController?.viewControllers,
                let last = viewControllers.filter ({ $0.isKind(of: SettingViewController.self) }).last { //Setting页面在当前页面之前
                Common.clearPops()
                dismissModals()
                popBack(to: last)
                DispatchQueue.main.asyncAfter(deadline: .now() + ViewControllerTransitionInterval, execute: { [weak self] in
                    self?.stateMachine.end(event)
                })
            } else { //视图栈中没有Setting页面，push新的Setting页面入栈
                Common.clearPops()
                dismissModals()
                show("SettingViewController", storyboard: "Profile", event: event)
            }
        default:
            break
        }
    }
    
    func stateMachine(_ stateMachine: SRStateMachine, didEndBase event: Event) {
        switch event.option {
        case .openWebpage:
            Common.removeEvent(event)
            
        default:
            break
        }
        
    }
}
#endif
