//
//  HttpManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public typealias ParamEncoding = ParameterEncoding
public typealias ParamHeaders = HTTPHeaders

public class HttpManager: BusinessManager {
    var manager: SRHttpManager!
    var queue = DispatchQueue.init(label: "com.http.manager",
                                   qos: .utility,
                                   attributes: .concurrent)
    var requests: [DataRequest] = []
    
    public class var shared: HttpManager {
        return sharedInstance
    }
    
    private static let sharedInstance = HttpManager(.http)
    
    private override init(_ module: ManagerModule) {
        manager = SRHttpManager(30)
        
        HttpDefine.initAPIs()
        
        super.init(module)
        manager.queue = queue
    }
    
    override public func callBusiness(_ funcId: UInt, params: Any?) -> BFResult<Any> {
        guard let capability = Manager.Http.capability(funcId) else {
            return .failure(BFError.callModuleFailed(.capabilityNotExist(funcId)))
        }
        
        if capability.isFunction {
            switch capability {
            case .function(let function):
                switch function {
                case .clearRequests:
                    cancel(sender: params as? String)
                    
                case .updateToken:
                    if Common.isLogin() {
                        HttpManager.httpHeaders[ParamKey.token] =
                            Common.currentProfile()?.token ?? EmptyString
                    } else {
                        HttpManager.httpHeaders.removeValue(forKey: ParamKey.token)
                    }
                    
                case .updateSecurityPolicy:
                    break
                    
                default: break
                }
                
            default: break
            }
        }
        
        return .success(nil)
    }
    
    static private var httpHeaders: [String: String] = [:]
    
    func cancel(_ requst: URLRequest?) {
        guard let requst = requst else { return }
        objc_sync_enter(requests)
        requests = requests.filter {
            let result = requst != $0.request
            if !result {
                $0.cancel()
            }
            return result
        }
        objc_sync_exit(requests)
    }
    
    func cancel(sender: String?) {
        guard let sender = sender else { return }
        objc_sync_enter(requests)
        requests = requests.filter {
            let result = sender != $0.sender
            if !result {
                $0.cancel()
            }
            return result
        }
        objc_sync_exit(requests)
    }
    
    func remove(_ requst: URLRequest?) {
        guard let requst = requst else { return }
        objc_sync_enter(requests)
        requests = requests.filter { requst != $0.request }
        objc_sync_exit(requests)
    }
    
    //MARK: - Request
    
    var lastUrl = EmptyString
    
    func request(_ capability:HttpCapability,
                 sender: String?,
                 params: ParamDictionary?,
                 url: String?,
                 encoding: ParamEncoding?,
                 headers: ParamHeaders?,
                 success: ((HttpCapability, Any) -> Void)?,
                 bfail: ((HttpCapability, Any) -> Void)?,
                 fail: ((HttpCapability, BFError) -> Void)?) {
        var requestParams = params ?? [:]
        var requestUrl: URL?
        let api = HttpDefine.api(capability)
        if Common.isEmptyString(url) {
            requestUrl = Common.isEmptyString(api)
                ? URL(string: Config.shared.apiBaseUrl)
                : URL(string: Config.shared.apiBaseUrl)?.appendingPathComponent(api!)
            addExtraParam(&requestParams)
        } else {
            requestUrl = Common.isEmptyString(api)
                ? URL(string: url!)
                : URL(string: url!)?.appendingPathComponent(api!)
        }
        
        if requestUrl == nil {
            let error =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "request url is null!"])
            let result: BFResult<Any> =
                .failure(BFError.httpFailed(.afResponseFailed(error)))
            respond(result, capability: capability, fail: fail)
            return
        }
        
        let successHandler: (URLRequest?, Any?) -> Void = { request, data in
            self.remove(request)
            guard let result = self.result(capability,
                                           data: data,
                                           userInfo: requestParams) else {
                                            return
            }
            self.respond(result, capability: capability, success: success, bfail: bfail)
        }
        let failureHandler: (URLRequest?, Error) -> Void = { request, error in
            self.remove(request)
            let result: BFResult<Any> =
                .failure(BFError.httpFailed(.afResponseFailed(error)))
            self.respond(result, capability: capability, fail: fail)
        }
        
        switch capability {
        case .post:
            queue.async {
                //精简打印过长的参数
                if capability == .post(.uploadFaceImage) {
                    self.logRequest(requestUrl, type: "post",
                                    api: api,
                                    params: [EmptyString : "[Base64String]"])
                } else {
                    self.logRequest(requestUrl!, type: "post", api: api, params: requestParams)
                }
                
                let request = self.manager.post(requestUrl!,
                                                params: requestParams,
                                                encoding: encoding ?? JSONEncoding.default,
                                                headers: headers ?? HttpManager.httpHeaders,
                                                success: successHandler,
                                                failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                self.requests.append(request)
            }
            
        case .get:
            queue.async {
                self.logRequest(requestUrl!, type: "get", api: api, params: requestParams)
                let request = self.manager.get(requestUrl!,
                                               params: requestParams,
                                               encoding: encoding ?? URLEncoding.default,
                                               headers: headers ?? HttpManager.httpHeaders,
                                               success: successHandler,
                                               failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                self.requests.append(request)
            }
            
        case .upload:
            queue.async {
                //精简打印过长的参数
                var logParams = requestParams
                if let array = logParams[HttpKey.Upload.files] as? [ParamDictionary] {
                    logParams[HttpKey.Upload.files] = array.map { dictionary -> ParamDictionary in
                        if dictionary[HttpKey.Upload.data] != nil {
                            return dictionary.extend([HttpKey.Upload.data : "[FormData]"])
                        } else {
                            return dictionary
                        }
                    }
                }
                self.logRequest(requestUrl!, type: "upload", api: api, params: logParams)
                
                self.manager.upload(requestUrl!,
                                    params: requestParams,
                                    encoding: encoding ?? URLEncoding.httpBody,
                                    headers: headers ?? HttpManager.httpHeaders,
                                    success: successHandler,
                                    failure: failureHandler)
            }
            
        default: break
        }
    }
    
    func addExtraParam(_ params: inout ParamDictionary) {
        params[ParamKey.os] = OSVersion
        params[ParamKey.deviceModel] = DevieModel
        params[ParamKey.version] = AppVersion
        params[ParamKey.deviceId] = Common.uuid()
        params[ParamKey.deviceToken] = Common.currentDeviceToken()
        if Common.isLogin(), let userId = Common.currentProfile()?.userId {
            params[ParamKey.userId] = userId
        }
    }
    
    func logRequest(_ url: URL!, type: String, api: String?, params: ParamDictionary) {
        LogInfo(String(format: "http request %@ api: %@\nparameters:\n%@",
                       type,
                       api ?? EmptyString,
                       Common.jsonString(params) ?? EmptyString))
        if RunInEnvironment == .production { return }
        
        let urlQuery = params.urlQuery
        lastUrl = urlQuery.isEmpty ? url.absoluteString : url.absoluteString + "?" + urlQuery
        LogInfo("url:\n\(lastUrl)")
    }
    
    //MARK: - Response
    
    //MARK: Response result
    
    func result(_ capability: HttpCapability,
                data: Any?,
                userInfo: [AnyHashable : Any]?) -> BFResult<Any>? {
        var result: BFResult<Any>!
        switch capability {
        case .get(.sinaNewsList):
            result = analysisSina(data, userInfo: userInfo)
            
        case .get(.newsSuggestions):
            result = analysisSearchSuggestion(data, userInfo: userInfo)
            
        case .get(.sinaStockList):
            result = .success(data)
            
        case .post(.getIMToken):
            result = analysisIM(data)
            
        case .post(.uploadFaceImage), .post(.faceImageAnalyze):
            result = analysisMSXiaoBing(data)
            
        default:
            result = analysis(data)
        }
        
        //某些网络请求不需要等待返回
        //if capability == .post(.logout) { return nil }
        
        //某些网络请求特定的处理
        if result.isSuccess {
            switch capability {
            case .post(.login):
                BF.callBusiness(BF.businessId(.profile, Manager.Profile.funcId(.login)),
                                params: (result.value as? JSON)?[HttpKey.Response.data].dictionaryObject)
                
            case .get(.profile), .post(.profileDetail):
                BF.callBusiness(BF.businessId(.profile, Manager.Profile.funcId(.updateProfile)),
                                params: (result.value as? JSON)?[HttpKey.Response.data].dictionaryObject)
                
//            case .get(.messages):
//                let json = (result.value as? JSON)?[HttpKey.Response.data]
//                var dictionary = json?.dictionaryObject
//                dictionary?[ParamKey.data] = json?[ParamKey.list].array?.compactMap
//                    { (JSON) -> MessageModel? in
//                        if let dictionary = JSON.dictionaryObject {
//                            return MessageModel(JSON: dictionary)
//                        }
//                        return nil
//                }
//                result = .success(dictionary)
                
            case .get(.sinaNewsList):
                let json = result.value as? JSON
                var dictionary = json?.dictionaryObject
                dictionary?[ParamKey.data] = json?[ParamKey.list].array?.compactMap
                    { (JSON) -> SinaNewsModel? in
                        if let dictionary = JSON.dictionaryObject {
                            return SinaNewsModel(JSON: dictionary)
                        }
                        return nil
                }
                result = .success(dictionary)
                
            default: break
            }
        } else if result.isBFailure {
            if let json = result.value as? JSON,
                let errCode = json[HttpKey.Response.errorCode].number,
                errCode.intValue == HttpErrorCode.tokenExpired { //统一处理token失效
                Common.currentProfile()?.isLogin = false
                Common.clearForLogin(json[HttpKey.Response.errorMessage].string)
            }
        }
        
        return result
    }
    
    //MARK: Analysis response data
    
    func analysis(_ data: Any?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: data, options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if RunInEnvironment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let errCode = json[HttpKey.Response.errorCode].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format! ".localized])
            return .failure(BFError.httpFailed(.responseSerializationFailed(nsError)))
        }
        
        return errCode.intValue == HttpErrorCode.success ? .success(json) : .bfailure(json)
    }
    
    func analysisSina(_ data: Any?, userInfo: [AnyHashable : Any]?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        guard var jsonString = String(data: data, encoding: .utf8) else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        if let userInfo = userInfo,
            let jsonCallback = userInfo[ParamKey.jsonCallback] as? String,
            !Common.isEmptyString(jsonCallback) {
            //jsonP ->json
            let leadText = jsonCallback + "("
            let tailText = ");\n"
            if jsonString.substring(to: leadText.length) == leadText
                && jsonString.substring(from: max(jsonString.length - tailText.length, 0)) == tailText {
                jsonString = jsonString.substring(from: leadText.length,
                                                  to: jsonString.length - tailText.length)
            }
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonString.data(using: .utf8, allowLossyConversion: false)!,
                            options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if RunInEnvironment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let status = json[ParamKey.status].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format! ".localized])
            return .failure(BFError.httpFailed(.responseSerializationFailed(nsError)))
        }
        
        return status.intValue == 1 ? .success(json) : .bfailure(json)
    }
    
    func analysisSearchSuggestion(_ data: Any?,
                                  userInfo: [AnyHashable : Any]?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        guard var jsonString = String(data: data, encoding: .utf8) else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        if let userInfo = userInfo,
            let cb = userInfo[ParamKey.cb] as? String,
            !Common.isEmptyString(cb) {
            let leadText = "try{window.\(cb)&\(cb)("
            let tailText = ");}catch(e){}"
            if jsonString.substring(to: leadText.length) == leadText
                && jsonString.substring(from: max(jsonString.length - tailText.length, 0)) == tailText {
                jsonString = jsonString.substring(from: leadText.length,
                                                  to: jsonString.length - tailText.length)
            }
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonString.data(using: .utf8, allowLossyConversion: false)!,
                            options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if RunInEnvironment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let code = json[ParamKey.code].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format! ".localized])
            return .failure(BFError.httpFailed(.responseSerializationFailed(nsError)))
        }
        
        return code.intValue == 100000 ? .success(json) : .bfailure(json)
    }
    
    func analysisIM(_ data: Any?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: data, options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if RunInEnvironment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let errCode = json[HttpKey.Response.errorCode].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format! ".localized])
            return .failure(BFError.httpFailed(.responseSerializationFailed(nsError)))
        }
        
        return errCode.intValue == HttpErrorCode.imSuccess ? .success(json) : .bfailure(json)
    }
    
    //MARK: Analysis MSXiaoBing
    
    func analysisMSXiaoBing(_ data: Any?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: data, options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if RunInEnvironment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        return .success(json)
    }
    
    //MARK: Respond
    
    func respond(_ result: BFResult<Any>,
                 capability: HttpCapability,
                 success: ((HttpCapability, Any) -> Void)? = nil,
                 bfail: ((HttpCapability, Any) -> Void)? = nil,
                 fail: ((HttpCapability, BFError) -> Void)? = nil) {
        if result.isSuccess, let success = success {
            DispatchQueue.main.async {
                success(capability, result.value!)
            }
        } else if result.isBFailure, let bfail = bfail {
            DispatchQueue.main.async {
                bfail(capability, result.value!)
            }
        } else if result.isFailure, let fail = fail {
            DispatchQueue.main.async {
                fail(capability, result.error as! BFError)
            }
        }
    }
}
