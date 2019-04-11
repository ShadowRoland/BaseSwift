//
//  IMManager.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/24.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON
import CryptoSwift
import Alamofire

public class IMManager: BusinessManager {
    
    struct Const {
        static let headerKeyAppKey = "App-Key"
        static let headerKeyNonce = "Nonce"
        static let headerKeyTimestamp = "Timestamp"
        static let headerKeySignature = "Signature"
        static let nonceLength = 10
    }
    
    override public init(_ module: ManagerModule) {
        super.init(module)
        
        RCIM.shared().initWithAppKey("sfci50a7sod0i")
    }
    
    //参见http://www.rongcloud.cn/docs/server.html#signature
    var httpHeaders: [String : String] {
        var headers = [:] as [String : String]
        headers[Const.headerKeyAppKey] = "sfci50a7sod0i"
        
        //随机生成字符串
        var nonce = ""
        (0 ..< Const.nonceLength).forEach { _ in nonce.append(String(int: Int.random(in: 0 ..< 10))) }
        headers[Const.headerKeyNonce] = nonce
        
        let timestamp = String(long: CLong(Date().timeIntervalSince1970))
        headers[Const.headerKeyTimestamp] = timestamp
        headers[Const.headerKeySignature] = ("of5p5wrcj7i4s" + nonce + timestamp).sha1()
        return headers
    }
    
    public func logBFail(_ capability: HttpCapability,
                         _ response: Any? = nil) {
        var responseArg = "response can not be printed" as CVarArg
        var code = EmptyString
        if let json = response as? JSON {
            if let arg = response as? CVarArg {
                responseArg = arg
            }
            code = json[HttpKey.Response.errorCode].stringValue
        } else if let arg = response as? CVarArg {
            responseArg = arg
        }
        LogError(String(format: "request failed, api: %@\nreponse: %@",
                        HttpDefine.api(capability)!,
                        responseArg))
        Common.showToast("IM requet: \(HttpDefine.api(capability)!) fail, code=\(code)")
    }
    
    func getToken(_ params: ParamDictionary) {
        HttpManager.shared.request(.post(.getIMToken),
                                   sender: String(pointer: self),
                                   params: params,
                                   url: "http://api.cn.ronghub.com",
                                   encoding: nil,
                                   headers: nil,
                                   success: { _, response in
                                    if let json = response as? JSON {
                                        self.login(json[ParamKey.token].stringValue)
                                    }
        }, bfail: { _, response in
            self.logBFail(.post(.getIMToken), response)
        }, fail: { (capability, error) in
            Common.showToast("Chat service: \(error.errorDescription ?? EmptyString)")
        })
    }
    
    func login(_ token: String) {
        guard Common.isLogin() else {
            return
        }
        
        RCIM.shared().connect(withToken: token, success: { (userId) in
            LogInfo("IM login success")
            let profile = Common.currentProfile()
            profile?.imToken = token
            profile?.isIMLogin = true
        }, error: { (code) in
            DispatchQueue.main.async {
                Common.showToast("IM login fail, code=\(code)")
            }
        }) {
            DispatchQueue.main.async {
                Common.showToast("IM token incorrect")
            }
        }
    }

    override public func callBusiness(_ funcId: UInt, params: Any?) -> BFResult<Any> {
        let capability = Manager.IM.Capability(rawValue: funcId) as Manager.IM.Capability?
        if capability == nil {
            return .failure(BFError.callModuleFailed(.capabilityNotExist(funcId)))
        }
        
        switch capability! {
        case .login:
            let current =
                [ParamKey.userId : NonNull.string(Common.currentProfile()?.userId),
                ParamKey.name : NonNull.string(Common.currentProfile()?.name?.fullName),
                ParamKey.portraitUri : NonNull.string(Common.currentProfile()?.headPortrait)]
            getToken(params as? ParamDictionary ?? current)
        default:
            break
        }
        return .success(nil)
    }
}

