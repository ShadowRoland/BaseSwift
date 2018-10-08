//
//  SRHttpServer.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/10.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import GCDWebServer
import CocoaLumberjack
import SwiftyJSON
import CryptoSwift

public enum GCDWebServerResponseTime {
    case immediately
    case speediness
    case normal
    case long
    case timeout
}

public enum VerificationCodeType: Int {
    case login = 0
    case forgetPassword = 1
}

public enum ResetPasswordType: Int {
    case smsCode = 0
    case password = 1
}

public class SRHttpServer: NSObject {
    var isRunning: Bool { return webServer.isRunning }
    var webServer: GCDWebServer!
    
    //为nil时按正常流程返回，否则强制设置网络返回的结果
    var responseResult: BFResult<Any>?
    var responseTime: GCDWebServerResponseTime = .normal

    weak var listenVC: HttpServerViewController?
    
    public class var shared: SRHttpServer {
        return sharedInstance
    }
    
    private static let sharedInstance = SRHttpServer()
    
    private override init() {
        super.init()
        webServer = GCDWebServer()
        handleRequest()
    }
    
    struct Const {
        static let htmlBaseFormat = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head><body>%@</body></html>"
        static let logfileTailLength = 10000
    }
    
    struct VerificationCode {
        static var loginDic = [:] as [String : String]
        static var forgetPasswordDic = [:] as [String : String]
    }
    
    public func start() {
        if !webServer.isRunning {
            if webServer.start(withPort: 9999, bonjourName: EmptyString) {
                listenVC?.updateListenLabel("已启动")
            } else {
                listenVC?.updateListenLabel("启动失败 ")
            }
        } else {
            listenVC?.updateListenLabel("已启动")
        }
    }
    
    public func stop() {
        if webServer.isRunning {
            webServer.stop()
        }
        listenVC?.updateListenLabel("已停止服务")
    }
    
    func response(_ result: BFResult<Any>?) -> GCDWebServerResponse? {
        var serverResponse: GCDWebServerResponse?
        if responseResult == nil {
            if result == nil {
                let dictionary = BFResult.bfailure("操作失败，请求姿势不对").gcdWebServerResponse
                serverResponse = GCDWebServerDataResponse(jsonObject: dictionary)
            } else {
                serverResponse = GCDWebServerDataResponse(jsonObject: result?.gcdWebServerResponse as Any)
            }
        } else {
            if responseResult!.isSuccess {
                if let result = result, result.isSuccess {
                    serverResponse = GCDWebServerDataResponse(jsonObject: result.gcdWebServerResponse)
                } else {
                    serverResponse = GCDWebServerDataResponse(jsonObject: BFResult<Any>.success(nil).gcdWebServerResponse)
                }
            } else if responseResult!.isBFailure {
                if let result = result, result.isBFailure {
                    serverResponse = GCDWebServerDataResponse(jsonObject: result.gcdWebServerResponse)
                } else {
                    serverResponse =
                        GCDWebServerDataResponse(jsonObject: BFResult<Any>.bfailure(nil).gcdWebServerResponse)
                }
            } else if responseResult!.isFailure {
                serverResponse =
                    GCDWebServerErrorResponse.responseWithServerError(.httpStatusCode_InternalServerError,
                                                                      "服务器已经Boom Shakalaka")
            }
        }
        
        switch responseTime {
        case .immediately: break
        case .speediness:
            usleep(300)
        case .normal:
            sleep(1)
        case .long:
            sleep(10)
        case .timeout:
            sleep(100)
        }
        
        return serverResponse
    }
    
    //MARK: - Request Handler
    
    public func handleRequest() {
        webServer.addDefaultHandler(forMethod: "GET",
                                    request: GCDWebServerURLEncodedFormRequest.self)
        { (request) -> GCDWebServerResponse? in
            if let query = request.query {
                print("get query: \n\(Common.jsonString(query) ?? EmptyString)")
            }
            
            var result: BFResult<Any>?
            let path = self.format(request.url.path)
            if Common.isEmptyString(path) {
                var body = EmptyString
                if 0 == request.query?.count {//默认是访问手机的日志文件列表
                    body = self.logFiles()
                } else {
                    if let index = request.query!["index"] {
                        if let length = request.query!["length"] {
                            body = self.logFileContents((index as AnyObject).intValue,
                                                        length: (length as AnyObject).intValue)
                        } else {
                            body = self.logFileContents((index as AnyObject).intValue)
                        }
                        return GCDWebServerDataResponse(text: body)
                    }
                }
                return GCDWebServerDataResponse(html: String(format: Const.htmlBaseFormat, body))
            } else if path.hasSuffix(".html") {
                return self.getLocalHtml(request, path: path)
            } else if path == self.format(HttpDefine.api(.get(.profile))) {
                result = self.getProfile(request)
            } else if path == self.format(HttpDefine.api(.get(.profileDetail))) {
                result = self.getProfileDetail(request)
            } else if path == self.format(HttpDefine.api(.get(.getVerificationCode))) {
                result = self.getVerificationCode(request)
            } else if path == self.format(HttpDefine.api(.get(.simpleData))) {
                result = BFResult.success([ParamKey.title : "Hakuna matata"])
            } else if path == self.format(HttpDefine.api(.get(.simpleList))) {
                result = self.getSimpleList(request)
            } else if path == self.format(HttpDefine.api(.get(.messages))) {
                result = self.getMessages(request)
            }
            return  self.response(result)
        }
        
        webServer.addDefaultHandler(forMethod: "POST",
                                    request: GCDWebServerURLEncodedFormRequest.self)
        { (request) -> GCDWebServerResponse? in
            
            if let jsonRequest = request as? GCDWebServerURLEncodedFormRequest,
                let json = try? JSON(data: jsonRequest.data) {
                print("post data: \n\(json.rawString() ?? "")")
            }
            
            var result: BFResult<Any>?
            let path = self.format(request.url.path)
            if path == self.format(HttpDefine.api(.post(.login))) {
                result = self.login(request)
            } else if path == self.format(HttpDefine.api(.post(.register))) {
                result = self.register(request)
            } else if path == self.format(HttpDefine.api(.post(.resetPassword))) {
                result = self.resetPassword(request)
            } else if path == self.format(HttpDefine.api(.post(.profileDetail))) {
                result = self.saveProfileDetail(request)
            } else if path == self.format(HttpDefine.api(.post(.simpleSubmit))) {
                result = BFResult.success([:])
            }
            
            return  self.response(result)
        }
        
    }
    
    func format(_ path: String?) -> String {
        var pathStr = NSString(string: path ?? EmptyString)
        pathStr = pathStr.replacingOccurrences(of: "/",
                                               with: "",
                                               options: .caseInsensitive,
                                               range: NSMakeRange(0, 1)) as NSString
        return String(pathStr)
    }
    
    //compatible，是否兼容不登录状态
    func isTokenExpired(_ request: GCDWebServerRequest,
                        _ compatible: Bool = true) -> [AnyHashable : Any]? {
        var query: [AnyHashable : Any]?
        if request.method.uppercased() == "GET" {
            query = request.query
        } else if request.method.uppercased() == "POST" {
            query =
                (try? JSON(data: (request as! GCDWebServerURLEncodedFormRequest).data))?.rawValue
                as? [AnyHashable : Any]
        }
        if query == nil {
            query = [:]
        }
        
        //允许未登录状态的请求
        if query?[ParamKey.userId] == nil && compatible {
            return nil
        }
        
        //校验
        if query?[ParamKey.userId] != nil,
            let token = request.headers[ParamKey.token] as? String,
            token == self.token {
            return nil
        }
        
        return [HttpKey.Response.errorCode : HttpErrorCode.tokenExpired,
                HttpKey.Response.errorMessage : "Your login has expired, please login again.".localized]
    }
    
    //MARK: Log Reader
    
    func logFiles() -> String {
        listenVC?.updateListenLabel("接收请求：获取所有的日志文件列表")
        
        var body = EmptyString
        var contents: [Any]?
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: logsDirectory())
        } catch {
            return body.appendingFormat("<h2>获取日志文件列表失败</h2><p>%@</p>", error.localizedDescription)
        }
        
        if contents?.count == 0 {
            return body.appending("<h2>日志文件列表为空</h2>")
        }
        
        body.append("<h2>日志文件列表</h2>")
        body.append("<ul>")
        var sortedContents: [Any]? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory().appending(pathComponent: obj1 as? String)
            var properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory().appending(pathComponent: obj2 as? String)
            var properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
            let date2 = properties2[FileAttributeKey.modificationDate] as! Date
            
            return date2.compare(date1) == .orderedAscending
        })
        let list = (0 ..< (sortedContents?.count)!).map {
            String(format: "<li><a href=\"javascript:window.location.href=window.location.href + '?index=%d&length=%d'\">%@</a> <a href=\"javascript:window.location.href=window.location.href + '?index=%d'\">[全部]</a></li>",
                   $0,
                   Const.logfileTailLength,
                   sortedContents?[$0] as! CVarArg, $0)
        }
        body.append(list.joined(separator: EmptyString))
        body.append("</ul>")
        return body
    }
    
    func logFileContents(_ index: Int, length: Int = 0) -> String {
        if length > 0 {
            listenVC?.updateListenLabel(String(format: "接收请求：获取顺序为%d的日志文件内容最后%d字",
                                               index,
                                               length))
        } else {
            listenVC?.updateListenLabel(String(format: "接收请求：获取顺序为%d的日志全部文件内容",
                                               index))
        }
        
        var body = EmptyString
        var contents: [Any]?
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: logsDirectory())
        } catch {
            return body.appendingFormat("<h2>获取日志文件列表失败</h2><p>%@</p>", error.localizedDescription)
        }
        
        if index >= (contents?.count)! {
            return body.appending("<h2>无法获取日志文件，请刷新日志文件列表</h2>")
        }
        
        var sortedContents: [Any]? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory().appending(pathComponent: obj1 as? String)
            var properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory().appending(pathComponent: obj2 as? String)
            var properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
            let date2 = properties2[FileAttributeKey.modificationDate] as! Date
            
            return date2.compare(date1) == .orderedAscending
        })
        
        let fileName = sortedContents?[index] as? String
        let filePath = logsDirectory().appending(pathComponent: fileName!)
        body = body.appendingFormat("<h2>%@</h2>", fileName!)
        var fileContents: String?
        do {
            try fileContents = String(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            return body.appendingFormat("<p>无法读取文件内容，错误原因: <br>%@</p>",
                                        error.localizedDescription)
        }
        
        let fileLength = fileContents!.length
        if length > 0 && length < fileLength {
            return fileContents!.substring(from: max(fileLength - length, 0))
        }
        return fileContents!
    }
    
    var _logsDirectory: String?
    
    func logsDirectory() -> String {
        if _logsDirectory == nil {
            _logsDirectory = DDLogFileManagerDefault().logsDirectory
        }
        return _logsDirectory!
    }
    
    func getLocalHtml(_ request: GCDWebServerRequest, path: String) -> GCDWebServerDataResponse? {
        let dir = ResourceDirectory.appending(pathComponent: "html")
        let filePath = dir.appending(pathComponent: path)
        var fileContents: String?
        do {
            try fileContents = String(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            let description = String(format: "<p>无法读取文件内容，错误原因: <br>%@</p>",
                                     error.localizedDescription)
            return GCDWebServerDataResponse(html: String(format: Const.htmlBaseFormat, description))
        }
        
        return GCDWebServerDataResponse(html: fileContents!)
    }
    
    //MARK: Profile
    
    var token = EmptyString
    
    func login(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        var profile = getLocalProfile()
        let uName = query?[ParamKey.userName]
        if Common.isEmptyString(uName)
            || (profile[ParamKey.userName] as! String) != (uName as! String) {
            return BFResult.bfailure("用户名或密码不匹配")
        }
        
        let password = query?[ParamKey.password]
        if Common.isEmptyString(password)
            || (profile[ParamKey.password] as! String).uppercased() != (password as! String).uppercased() {
            return BFResult.bfailure("用户名或密码不匹配")
        }
        
        token = String(Date.timeIntervalSinceReferenceDate).md5()
        profile[ParamKey.token] = token
        
        return BFResult.success(profile)
    }
    
    func register(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        guard let countryCode = query?[ParamKey.countryCode],
            let phone = query?[ParamKey.phone],
            !Common.isEmptyString(phone),
            (phone as! String).isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                return BFResult.bfailure("无效的手机号码")
        }
        
        let phoneNumber = String(int: Number.int(countryCode)!) + (phone as! String)
        guard let code = query?[ParamKey.code] as? String,
            code == VerificationCode.loginDic[phoneNumber] else {
                return BFResult.bfailure("错误的短信验证码")
        }
        
        guard let password = query?[ParamKey.password] as? String,
            password.isPassword else {
            return BFResult.bfailure("无效的密码")
        }
        
        return BFResult.success(EmptyParams())
    }
    
    func resetPassword(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        guard let type = Number.int(query?[ParamKey.type]),
            let enumType = ResetPasswordType(rawValue: type) else {
                return BFResult.bfailure("无效的类型")
        }
        
        var profile: [AnyHashable : Any]?
        if enumType == .smsCode {
            guard let countryCode = Number.int(query?[ParamKey.countryCode]),
                let phone = query?[ParamKey.phone],
                !Common.isEmptyString(phone),
                (phone as! String).isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                    return BFResult.bfailure("无效的手机号码")
            }
            
            profile = getLocalProfile()
            guard countryCode == Number.int(profile?[ParamKey.countryCode]),
                phone as! String == profile?[ParamKey.phone] as! String else {
                return BFResult.bfailure("手机号码没有被注册")
            }
            
            let phoneNumber = String(int: Number.int(countryCode)!) + (phone as! String)
            guard let code = query?[ParamKey.code],
            !Common.isEmptyString(code),
            VerificationCode.forgetPasswordDic[phoneNumber] == code as? String else {
                return BFResult.bfailure("无效的短信验证码")
            }
        } else {
            if let expired = self.isTokenExpired(request, false) {
                return BFResult.bfailure(expired)
            }
            
            profile = getLocalProfile()
            guard let password = query?[ParamKey.password],
                !Common.isEmptyString(password),
                password as! String == profile?[ParamKey.password] as! String else {
                    return BFResult.bfailure("错误的旧密码")
            }
        }
        
        guard let newPassword = query?[ParamKey.newPassword],
            !Common.isEmptyString(newPassword),
            (newPassword as! String).isPassword else {
                return BFResult.bfailure("无效的新密码")
        }
        
        profile![ParamKey.password] = (newPassword as! String).md5().uppercased()
        saveLocalProfile(profile!)
        
        return BFResult.success(EmptyParams())
    }
    
    func getProfile(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = self.isTokenExpired(request, false) { return BFResult.bfailure(expired) }
        return BFResult.success(getLocalProfile())
    }
    
    func getProfileDetail(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = self.isTokenExpired(request, false) { return BFResult.bfailure(expired) }
        return BFResult.success(getLocalProfile().extend(getLocalProfileDetail()))
    }
    
    func saveProfileDetail(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = self.isTokenExpired(request, false) { return BFResult.bfailure(expired) }
        let jsonRequest = request as! GCDWebServerURLEncodedFormRequest
        let query = (try? JSON(data: jsonRequest.data))?.rawValue as? ParamDictionary
        
        let localProfile = getLocalProfile() as [AnyHashable : Any]
        var profile = localProfile
        query?.forEach {
            if localProfile[$0.key] != nil {
                profile[$0.key] = $0.value
            }
        }
        
        var profileDetail = getLocalProfileDetail() as [AnyHashable : Any]
        query?.forEach {
            if localProfile[$0.key] != nil {
                profileDetail[$0.key] = $0.value
            }
        }

        if let data = Common.jsonData(profile) {
            try! data.write(to: URL(fileURLWithPath: DocumentsDirectory.appending(pathComponent: "profile.json")),
                               options: .atomic)
        }
        
        if let data = Common.jsonData(profileDetail) {
            try! data.write(to: URL(fileURLWithPath: DocumentsDirectory.appending(pathComponent: "profile_detail.json")),
                       options: .atomic)
        }
        
        return BFResult.success(getLocalProfile().extend(getLocalProfileDetail()))
    }
    
    func getLocalProfile() -> ParamDictionary {
        if let dictionary =
            Common.readJsonFile(DocumentsDirectory.appending(pathComponent: "profile.json")) {
            return dictionary as! ParamDictionary
        }
        return Common.readJsonFile(ResourceDirectory.appending(pathComponent: "json/debug/profile.json")) as! ParamDictionary
    }
    
    func getLocalProfileDetail() -> ParamDictionary {
        if let dictionary =
            Common.readJsonFile(DocumentsDirectory.appending(pathComponent: "profile_detail.json")) {
            return dictionary as! ParamDictionary
        }
        return Common.readJsonFile(ResourceDirectory.appending(pathComponent: "json/debug/profile_detail.json")) as! ParamDictionary
    }
    
    func saveLocalProfile(_ profile: [AnyHashable : Any]) {
        guard let data = Common.jsonData(profile) else {
            return
        }
        let jsonPath = DocumentsDirectory.appending(pathComponent: "profile.json")
        try! data.write(to: URL(fileURLWithPath: jsonPath))
    }
    
    func getVerificationCode(_ request: GCDWebServerRequest) -> BFResult<Any> {
        let query = request.query
        guard let countryCode = query?[ParamKey.countryCode],
            let phone = query?[ParamKey.phone],
            !Common.isEmptyString(phone),
            (phone as! String).isMobileNumber(countryCode: Number.int(countryCode) ?? 0) else {
                return BFResult.bfailure("无效的手机号码")
        }
        
        guard let type = Number.int(query?[ParamKey.type]),
            let enumType = VerificationCodeType(rawValue: type) else {
                return BFResult.bfailure("获取验证码的类型错误")
        }
        
        if enumType == .forgetPassword {
            let profile = getLocalProfile()
            guard Number.int(countryCode) == Number.int(profile[ParamKey.countryCode]),
                phone as! String == profile[ParamKey.phone] as! String else {
                    return BFResult.bfailure("手机号码没有被注册")
            }
        }
        
        //随机生成字符串
        var code = ""
        for _ in (0 ..< 4) {
            let randomNumber = Int.random(0, 36)
            if randomNumber <= 9 {
                code.append(String(int: Int(randomNumber)))
            } else {
                code.append(Character(UnicodeScalar(randomNumber - 10 + 97)!))
            }
        }
        
        let phoneNumber = String(int: Number.int(countryCode)!) + (phone as! String)
        switch enumType {
        case .login:
            VerificationCode.loginDic[phoneNumber] = code
            
        case .forgetPassword:
            VerificationCode.forgetPasswordDic[phoneNumber] = code
        }
        return BFResult.success([ParamKey.countryCode : countryCode,
                                 ParamKey.phone : phone,
                                 ParamKey.type : type,
                                 ParamKey.code : code])
    }
    
    //MARK: List Data
    
    func getSimpleList(_ request: GCDWebServerRequest) -> BFResult<Any> {
        //if let expired = self.isTokenExpired(request) { return BFResult.bfailure(expired) }
        let jsonPath = ResourceDirectory.appending(pathComponent: "json/debug/simple_list.json")
        var listData = Common.readJsonFile(jsonPath) as! [AnyHashable : Any]
        
        //模拟服务器的分页
        let query = request.query
        let offset = Number.int(query?[ParamKey.offset]) ?? 0
        let limit = Number.int(query?[ParamKey.limit]) ?? 10
        if offset > 0 {
            listData.removeValue(forKey: ParamKey.images)
        }
        let list = listData[ParamKey.list] as! [Any]
        let startIndex = limit * offset
        var endIndex = limit * (offset + 1)
        if startIndex < list.count {
            endIndex = min(list.count, endIndex)
        }
        listData[ParamKey.list] = Array(list[startIndex ..< endIndex])
        
        return BFResult.success(listData)
    }
    
    func getMessages(_ request: GCDWebServerRequest) -> BFResult<Any> {
        if let expired = self.isTokenExpired(request) { return BFResult.bfailure(expired) }
        let jsonPath = ResourceDirectory.appending(pathComponent: "json/debug/messages.json")
        var listData = Common.readJsonFile(jsonPath) as! [AnyHashable : Any]
        
        //模拟服务器的分页
        let query = request.query
        let offset = Number.int(query?[ParamKey.offset]) ?? 0
        let limit = Number.int(query?[ParamKey.limit]) ?? 10
        let list = listData[ParamKey.list] as! [Any]
        let startIndex = limit * offset
        var endIndex = limit * (offset + 1)
        if startIndex < list.count {
            endIndex = min(list.count, endIndex)
        }
        listData[ParamKey.list] = Array(list[startIndex ..< endIndex])
    
        return BFResult.success(listData)
    }
}

extension BFResult {
    var gcdWebServerResponse: [AnyHashable : Any] {
        var dictionary: ParamDictionary = [HttpKey.Response.errorCode : 0,
                   HttpKey.Response.errorMessage : "操作成功",
                   ParamKey.timestamp : CLong(Date().timeIntervalSince1970)]
        switch self {
        case .success(let value):
            dictionary[HttpKey.Response.data] = NonNull.dictionary(value)
        case .bfailure(let value):
            if let respondDictionary = value as? ParamDictionary,
                respondDictionary[HttpKey.Response.errorCode] != nil,
                respondDictionary[HttpKey.Response.errorMessage] != nil {
                dictionary = respondDictionary
                break
            }
            dictionary[HttpKey.Response.errorCode] = 1
            dictionary[HttpKey.Response.errorMessage] =
                Common.isEmptyString(value) ? "操作失败，请求姿势不对" : value
        case .failure:
            dictionary = [:]
        }
        return dictionary
    }
    
}

extension GCDWebServerErrorResponse {
    public class func responseWithServerError(_ errorCode: GCDWebServerServerErrorHTTPStatusCode,
                                              _ message: String) -> GCDWebServerErrorResponse {
        let title = String(format:"HTTP Error %i", errorCode.rawValue)
        let html = String.init(format: "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>%@</title></head><body><h1>%@</h1><h3>%@</h3></body></html>", title, message, EmptyString)
        let response = GCDWebServerErrorResponse(html: html)
        response?.statusCode = errorCode.rawValue
        return response!
    }
}
