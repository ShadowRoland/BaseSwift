//
//  BaseViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

open class BaseViewController: SRBaseViewController {
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isPageLongPressEnabled = true
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        HttpManager.shared.cancel(sender: String(pointer: self))
    }
    
    open func showWebpage(_ url: URL,
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
        srShow("WebpageViewController", storyboard: "Utility", params: dictionary, event: event)
    }
    
    //MARK: -
    
    override open func showLoadDataFailView(_ text: String?,
                                            image: UIImage? = nil,
                                            insets: UIEdgeInsets? = nil) {
        super.showLoadDataFailView(text, image: image ?? UIImage("request_fail")!, insets: insets)
    }
    
    //MARK: - Http Request
    
    open override var httpManager: SRHttpManager? {
        get {
            return HttpManager.shared
        }
        set {
            
        }
    }
    
    //MARK: SRStateMachineDelegate
    
    open override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Event) {
        #if BASE_FRAMEWORK
        #else
        self.stateMachine(stateMachine, didFireBase: event)
        #endif
    }
    
    open override func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Event) {
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
        srModal("LoginViewController", storyboard: "Profile", params: params)
    }
    
    func stateMachine(_ stateMachine: SRStateMachine, didFireBase event: Event) {
        switch event.option {
        case .openWebpage: //FIXME: FOR DEBUG，在所有的视图上弹出网页视图，也可以处理其他全局型的业务，如跳转到聊天页面，此处业务不是必需的，可按照具体需求操作
            guard srIsTop,
                let string = event.params?[Param.Key.url] as? String,
                let url = URL(string: string) else {
                    break
            }
            
            if let vc = self as? WebpageViewController {
                Common.clearPops()
                srDismissModals()
                var params = [Param.Key.url : url] as ParamDictionary
                if let title = event.params?[Param.Key.title] as? String {
                    params[Param.Key.title] = title
                }
                vc.srParams = params
                vc.reload()
                stateMachine.end(event)
            } else {
                Common.clearPops()
                srDismissModals()
                showWebpage(url, title: event.params?[Param.Key.title] as? String, event: event)
            }
            
        case .showProfile:
            guard srIsTop else { break }
            
            if isKind(of: ProfileViewController.self) { //当前页面是Profile页面
                stateMachine.end(event)
            } else if let viewControllers = navigationController?.viewControllers,
                let last = viewControllers.filter ({ $0.isKind(of: ProfileViewController.self) }).last { //Profile页面在当前页面之前
                Common.clearPops()
                srDismissModals()
                srPopBack(to: last)
                DispatchQueue.main.asyncAfter(deadline: .now() + C.viewControllerTransitionInterval, execute: { [weak self] in
                    self?.stateMachine.end(event)
                })
            } else { //视图栈中没有Profile页面，push新的Profile页面入栈
                Common.clearPops()
                srDismissModals()
                if !ProfileManager.isLogin { //若是非登录状态，弹出登录页面，因为查看个人信息需要先登录
                    presentLoginVC()
                } else { //push新的Profile页面入栈
                    srShow("ProfileViewController", storyboard: "Profile", event: event)
                }
            }
            
        case .showSetting:
            guard srIsTop else { break }
            
            if isKind(of: SettingViewController.self) { //当前页面是Setting页面
                stateMachine.end(event)
            } else if let viewControllers = navigationController?.viewControllers,
                let last = viewControllers.filter ({ $0.isKind(of: SettingViewController.self) }).last { //Setting页面在当前页面之前
                Common.clearPops()
                srDismissModals()
                srPopBack(to: last)
                DispatchQueue.main.asyncAfter(deadline: .now() + C.viewControllerTransitionInterval, execute: { [weak self] in
                    self?.stateMachine.end(event)
                })
            } else { //视图栈中没有Setting页面，push新的Setting页面入栈
                Common.clearPops()
                srDismissModals()
                srShow("SettingViewController", storyboard: "Profile", event: event)
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
