//
//  IMManager.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/24.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON

public class IMManager {
    
    struct Const {
        static let headerKeyAppKey = "App-Key"
        static let headerKeyNonce = "Nonce"
        static let headerKeyTimestamp = "Timestamp"
        static let headerKeySignature = "Signature"
        static let nonceLength = 10
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
    
    class func login() {
        RCIM.shared().initWithAppKey("sfci50a7sod0i")
        let current =
            [Param.Key.userId : NonNull.string(ProfileManager.currentProfile?.userId),
             Param.Key.name : NonNull.string(ProfileManager.currentProfile?.name?.fullName),
             Param.Key.portraitUri : NonNull.string(ProfileManager.currentProfile?.headPortrait)]
        HttpManager.shared.request(.post("http://api.cn.ronghub.com/user/getToken.json",
                                         params: current,
                                         options: [.sender(String(pointer: self))]),
                                   success:
            { response in
                if let json = response as? JSON {
                    login(json[Param.Key.token].stringValue)
                }
        }) { failure in
            DispatchQueue.main.async {
                SRAlert.showToast("Chat service: \(failure.errorMessage)")
            }
        }
    }
    
    class func login(_ token: String) {
        guard ProfileManager.isLogin else {
            return
        }
        
        RCIM.shared()?.connect(withToken: token, timeLimit: 60, dbOpened: { code in
            
        }, success: { userId in
            LogInfo("IM login success")
            let profile = ProfileManager.currentProfile
            profile?.imToken = token
            profile?.isIMLogin = true
        }) { errorCode in
            DispatchQueue.main.async {
                SRAlert.showToast("IM login fail, code=\(errorCode)")
            }
        }
    }
}
