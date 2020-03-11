//
//  SRHttpServer.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/10.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import GCDWebServer
import SwiftyJSON

open class HttpServer: SRHttpServer {
    public class var shared: HttpServer {
        return sharedInstance
    }
    
    private static var sharedInstance = HttpServer()
    
    private override init() {
        super.init()
    }
    
    open override func handleRequest(_ method: String,
                                     request: GCDWebServerRequest) -> GCDWebServerResponse? {
        var result: BFResult<Any>?
        let path = format(request.url.path)
        if "GET" == method {
            if path == format("user/profile") {
                result = getProfile(request)
            } else if path == format("user/profileDetail") {
                result = getProfileDetail(request)
            } else if path == format("getVerificationCode") {
                result = getVerificationCode(request)
            } else if path == format("data/getSimpleData") {
                result = .success([Param.Key.title : "Hakuna matata"])
            } else if path == format("data/getSimpleList") {
                result = getSimpleList(request)
            } else if path == format("data/getMessages") {
                result = getMessages(request)
            }
        } else if "POST" == method {
            if path == format("user/login") {
                result = login(request)
            } else if path == format("user/register") {
                result = register(request)
            } else if path == format("user/resetPassword") {
                result = resetPassword(request)
            } else if path == format("user/profileDetail") {
                result = saveProfileDetail(request)
            } else if path == format("data/simpleSubmit") {
                result = .success([:])
            }
        }
        
        if let result = result {
            return  response(result)
        } else {
            return super.handleRequest(method, request: request)
        }
    }
}

extension HttpServer {
    
    func failure(_ description: String, code: Int? = nil) -> BFResult<Any> {
        return .failure(BFError(description, code: code ?? HTTP.Code.Response.success + 1))
    }
    
    //MARK: Profile
    
    struct VerificationCode {
        static var loginInfo = [:] as [String : String]
        static var forgetPasswordInfo = [:] as [String : String]
    }
    
    //compatible，是否兼容不登录状态
    func checkTokenExpired(_ request: GCDWebServerRequest,
                           compatible: Bool = false) -> BFResult<Any>? {
        var query: AnyDictionary?
        if request.method.uppercased() == "GET" {
            query = request.query
        } else if request.method.uppercased() == "POST" {
            query =
                (try? JSON(data: (request as! GCDWebServerURLEncodedFormRequest).data))?.rawValue
                as? AnyDictionary
        }
        if query == nil {
            query = [:]
        }
        
        //允许未登录状态的请求
        if query?[Param.Key.userId] == nil && compatible {
            return nil
        }
        
        //校验
        if query?[Param.Key.userId] != nil, HttpServer.token == request.headers[Param.Key.token] {
            return nil
        }
        
        return failure("Your login has expired, please login again.".localized,
                       code: HTTP.Code.Response.tokenExpired)
    }
    
    static var token = ""
    
    func login(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        var profile = getLocalProfile()
        let uName = query?[Param.Key.userName]
        if isEmptyString(uName)
            || (profile[Param.Key.userName] as! String) != (uName as! String) {
            return failure("用户名或密码不匹配")
        }
        
        let password = query?[Param.Key.password]
        if isEmptyString(password)
            || (profile[Param.Key.password] as! String).uppercased() != (password as! String).uppercased() {
            return failure("用户名或密码不匹配")
        }
        
        HttpServer.token = String(Date.timeIntervalSinceReferenceDate).md5()
        profile[Param.Key.token] = HttpServer.token
        
        return .success(profile)
    }
    
    func register(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        guard let countryCode = query?[Param.Key.countryCode],
            let phone = query?[Param.Key.phone],
            !isEmptyString(phone),
            (phone as! String).isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                return failure("无效的手机号码")
        }
        
        let phoneNumber = String(int: Number.int(countryCode)!) + (phone as! String)
        guard let code = query?[Param.Key.code] as? String,
            code == VerificationCode.loginInfo[phoneNumber] else {
                return failure("错误的短信验证码")
        }
        
        guard let password = query?[Param.Key.password] as? String,
            password.isPassword else {
                return failure("无效的密码")
        }
        
        return .success([:] as ParamDictionary)
    }
    
    func resetPassword(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        guard let type = Number.int(query?[Param.Key.type]),
            let enumType = ResetPasswordType(rawValue: type) else {
                return failure("无效的类型")
        }
        
        var profile: AnyDictionary?
        if enumType == .smsCode {
            guard let countryCode = Number.int(query?[Param.Key.countryCode]),
                let phone = query?[Param.Key.phone],
                !isEmptyString(phone),
                (phone as! String).isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                    return failure("无效的手机号码")
            }
            
            profile = getLocalProfile()
            guard countryCode == Number.int(profile?[Param.Key.countryCode]),
                phone as! String == profile?[Param.Key.phone] as! String else {
                    return failure("手机号码没有被注册")
            }
            
            let phoneNumber = String(int: Number.int(countryCode)!) + (phone as! String)
            guard let code = query?[Param.Key.code],
                !isEmptyString(code),
                VerificationCode.forgetPasswordInfo[phoneNumber] == code as? String else {
                    return failure("无效的短信验证码")
            }
        } else {
            if let expired = checkTokenExpired(request) {
                return expired
            }
            
            profile = getLocalProfile()
            guard let password = query?[Param.Key.password],
                !isEmptyString(password),
                password as! String == profile?[Param.Key.password] as! String else {
                    return failure("错误的旧密码")
            }
        }
        
        guard let newPassword = query?[Param.Key.newPassword],
            !isEmptyString(newPassword),
            (newPassword as! String).isPassword else {
                return failure("无效的新密码")
        }
        
        profile![Param.Key.password] = (newPassword as! String).md5().uppercased()
        saveLocalProfile(profile!)
        
        return .success([:] as ParamDictionary)
    }
    
    func getProfile(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = checkTokenExpired(request) { return expired }
        return .success(getLocalProfile())
    }
    
    func getProfileDetail(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = checkTokenExpired(request) { return expired }
        return .success(getLocalProfile().extend(getLocalProfileDetail()))
    }
    
    func saveProfileDetail(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = checkTokenExpired(request) { return expired }
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        
        let localProfile = getLocalProfile() as AnyDictionary
        var profile = localProfile
        query?.forEach {
            if localProfile[$0.key] != nil {
                profile[$0.key] = $0.value
            }
        }
        
        var profileDetail = getLocalProfileDetail() as AnyDictionary
        query?.forEach {
            if localProfile[$0.key] != nil {
                profileDetail[$0.key] = $0.value
            }
        }
        
        if let data = Data(jsonObject: profile) {
            try! data.write(to: URL(fileURLWithPath: C.documentsDirectory.appending(pathComponent: "profile.json")),
                            options: .atomic)
        }
        
        if let data = Data(jsonObject: profileDetail) {
            try! data.write(to: URL(fileURLWithPath: C.documentsDirectory.appending(pathComponent: "profile_detail.json")),
                            options: .atomic)
        }
        
        return .success(getLocalProfile().extend(getLocalProfileDetail()))
    }
    
    func getLocalProfile() -> ParamDictionary {
        if let dictionary = C.documentsDirectory.appending(pathComponent: "profile.json").fileJsonObject as? ParamDictionary {
            return dictionary
        }
        return C.resourceDirectory.appending(pathComponent: "json/debug/profile.json").fileJsonObject as! ParamDictionary
    }
    
    func getLocalProfileDetail() -> ParamDictionary {
        if let dictionary = C.documentsDirectory.appending(pathComponent: "profile_detail.json").fileJsonObject as? ParamDictionary {
            return dictionary
        }
        return C.resourceDirectory.appending(pathComponent: "json/debug/profile_detail.json").fileJsonObject as! ParamDictionary
    }
    
    func saveLocalProfile(_ profile: AnyDictionary) {
        guard let data = Data(jsonObject: profile) else {
            return
        }
        let jsonPath = C.documentsDirectory.appending(pathComponent: "profile.json")
        try! data.write(to: URL(fileURLWithPath: jsonPath))
    }
    
    func getVerificationCode(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let query = request.query
        guard let countryCode = query?[Param.Key.countryCode],
            let phone = query?[Param.Key.phone],
            !isEmptyString(phone),
            phone.isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                return failure("无效的手机号码")
        }
        
        guard let type = Number.int(query?[Param.Key.type]),
            let enumType = VerificationCodeType(rawValue: type) else {
                return failure("获取验证码的类型错误")
        }
        
        if enumType == .forgetPassword {
            let profile = getLocalProfile()
            guard Number.int(countryCode) == Number.int(profile[Param.Key.countryCode]),
                phone == profile[Param.Key.phone] as! String else {
                    return failure("手机号码没有被注册")
            }
        }
        
        //随机生成字符串
        var code = ""
        for _ in (0 ..< 4) {
            let randomNumber = Int.random(in: 0 ..< 36)
            if randomNumber <= 9 {
                code.append(String(int: Int(randomNumber)))
            } else {
                code.append(Character(UnicodeScalar(randomNumber - 10 + 97)!))
            }
        }
        
        let phoneNumber = String(int: Number.int(countryCode)!) + phone
        switch enumType {
        case .login:
            VerificationCode.loginInfo[phoneNumber] = code
            
        case .forgetPassword:
            VerificationCode.forgetPasswordInfo[phoneNumber] = code
        }
        return .success([Param.Key.countryCode : countryCode,
                         Param.Key.phone : phone,
                         Param.Key.type : type,
                         Param.Key.code : code])
    }
    
    //MARK: List Data
    
    func getSimpleList(_ request: GCDWebServerRequest) -> BFResult<Any> {
        var listData = C.resourceDirectory.appending(pathComponent: "json/debug/simple_list.json").fileJsonObject as! AnyDictionary
        
        //模拟服务器的分页
        let query = request.query
        let offset = Number.int(query?[Param.Key.offset]) ?? 0
        let limit = Number.int(query?[Param.Key.limit]) ?? 10
        if offset > 0 {
            listData.removeValue(forKey: Param.Key.images)
        }
        let list = listData[Param.Key.list] as! AnyArray
        let startIndex = limit * offset
        var endIndex = limit * (offset + 1)
        if startIndex < list.count {
            endIndex = min(list.count, endIndex)
        }
        listData[Param.Key.list] = Array(list[startIndex ..< endIndex])
        
        return .success(listData)
    }
    
    func getMessages(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = checkTokenExpired(request) { return expired }
        var listData = C.resourceDirectory.appending(pathComponent: "json/debug/messages.json").fileJsonObject as! AnyDictionary
        
        //模拟服务器的分页
        let query = request.query
        let offset = Number.int(query?[Param.Key.offset]) ?? 0
        let limit = Number.int(query?[Param.Key.limit]) ?? 10
        let list = listData[Param.Key.list] as! AnyArray
        let startIndex = limit * offset
        var endIndex = limit * (offset + 1)
        if startIndex < list.count {
            endIndex = min(list.count, endIndex)
            listData[Param.Key.list] = Array(list[startIndex ..< endIndex])
        } else {
            listData[Param.Key.list] = []
        }
        
        return .success(listData)
    }
}

public extension HTTP.Code.Response {
    static let tokenExpired = 400001  //登录已失效
}
