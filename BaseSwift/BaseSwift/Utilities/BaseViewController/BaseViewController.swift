//
//  BaseViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

public class BaseViewController: SRBaseViewController {
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
    
    //MARK: - Http Request
    
    override public func httpRequest(_ method: HTTP.Method<Any>,
                          params: ParamDictionary? = nil,
                          anonymous: Bool = false,
                          encoding: ParamEncoding? = nil,
                          headers: ParamHeaders? = nil,
                          options: [SRKit.HTTP.Key.Option : Any]? = nil,
                          success: ((Any) -> Void)? = nil,
                          bfail: ((String, Any) -> Void)? = nil,
                          fail: ((String, BFError) -> Void)? = nil) {
        var successHandler: ((Any) -> Void)!
        if let success = success {
            successHandler = success
        } else {
            successHandler = { [weak self] response in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondSuccess(response)
            }
        }
        
        var bfailHandler: ((String, Any) -> Void)!
        if let bfail = bfail {
            bfailHandler = bfail
        } else {
            bfailHandler = { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondBfail(url, response: response)
            }
        }
        
        var failHandler: ((String, BFError) -> Void)!
        if let fail = fail {
            failHandler = fail
        } else {
            failHandler = { [weak self] (url, error) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondFail(url, error: error)
            }
        }
        
        HttpManager.default.request(method,
                                    sender: anonymous ? nil : String(pointer: self),
                                    params: params,
                                    encoding: encoding,
                                    headers: headers,
                                    options: options,
                                    success: successHandler,
                                    bfail: bfailHandler,
                                    fail: failHandler)
    }
    
    //MARK: SRStateMachineDelegate
    
    public override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        switch event {
            //FIXME: FOR DEBUG，在所有的视图上弹出网页视图
            //也可以处理其他全局型的业务，如跳转到聊天页面
        //此处业务不是必需的，可按照具体需求操作
        case Event.Option.openWebpage.rawValue:
            guard isTop else { break }
            
            var string = ""
            if let url = Common.currentActionParams?[Param.Key.url] as? String {
                string = url
            }
            if let vc = self as? WebpageViewController {
                Common.clearPops()
                Common.clearModals()
                var params = [Param.Key.url : URL(string: string)!] as ParamDictionary
                if let title = Common.currentActionParams?[Param.Key.title] as? String {
                    params[Param.Key.title] = title
                }
                vc.params = params
                vc.reload()
                stateMachine.end(event)
            } else {
                NotifyDefault.add(self,
                                  selector: .didEndStateMachineEvent,
                                  name: Notification.Name.Base.didEndStateMachineEvent)
                Common.clearPops()
                Common.clearModals(viewController: self)
                showWebpage(URL(string: string)!,
                            title: Common.currentActionParams?[Param.Key.title] as? String,
                            params: [Param.Key.sender : String(pointer: self),
                                     Param.Key.event : event])
            }
        default:
            break
        }
    }
    
    public override func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Int) {
        guard let option = Event.Option(rawValue: event) else {
            return
        }
        
        Common.clearActionParams(option: option)
        
        switch option {
        case .openWebpage:
            NotifyDefault.remove(self, name: Notification.Name.Base.didEndStateMachineEvent)
            
        default:
            break
        }
    }
}

//MARK: - State Machine

extension SRStateMachine {
    //FIXME: FOR DEBUG，Event.Option一般都是即时发生的，新的Option加入等待队列时，旧的Option会被覆盖
    //如首页正在展示引导页（当前事件进行中），此时来了推送消息，点击推送消息，将推送消息里的action1加入到等待队列中。
    //若此时来了新推送消息，或者被其他应用所调用，转化成新的action2，在加入到等待队列中之前应该将action1给删除
    //这样引导页展示完毕后（当前事件已完成）就直接执行action2，而非先执行action1，再执行action2
    public func append(option: Event.Option) {
        guard !contains(option.rawValue) else {
            return
        }
        
        Event.Option.allCases.forEach { remove($0.rawValue) }
        append(option.rawValue)
    }
}
