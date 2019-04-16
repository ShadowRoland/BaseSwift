//
//  SRHttpManager.swift
//  SRKit
//
//  Created by Gary on 2019/4/13.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

open class SRHttpManager {
    public static var manager: SRHttpTool!
    public static var queue = DispatchQueue.init(label: "com.srhttp.manager",
                                          qos: .utility,
                                          attributes: .concurrent)
    public static var requests: [DataRequest] = []
    public static var httpHeaders: [String: String] = [:]
    
    open class func cancel(sender: String?) {
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
    
    open class func cancel(_ requst: URLRequest?) {
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
    
    open class func remove(_ requst: URLRequest?) {
        guard let requst = requst else { return }
        objc_sync_enter(requests)
        requests = requests.filter { requst != $0.request }
        objc_sync_exit(requests)
    }
    
    //MARK: - Request
    
    public static var lastRequstUrl = ""
    
    open class func request(_ method: HTTP.Method<Any>,
                       sender: String?,
                       params: ParamDictionary?,
                       encoding: ParamEncoding?,
                       headers: ParamHeaders?,
                       success: ((String?, Any) -> Void)?,
                       bfail: ((String?, Any) -> Void)?,
                       fail: ((String?, BFError) -> Void)?) {
        guard let url = method.url, let requestUrl = URL(string: url) else {
            let error =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid http request url."])
            respond(.failure(BFError.httpFailed(.afResponseFailed(error))),
                    url: method.url,
                    fail: fail)
            return
        }
        
        let requestParams = params ?? [:]
        let successHandler: (URLRequest?, Any?) -> Void = { request, data in
            remove(request)
            respond(analysis(data), url: url, success: success, bfail: bfail)
        }
        let failureHandler: (URLRequest?, Error) -> Void = { request, error in
            remove(request)
            respond(.failure(BFError.httpFailed(.afResponseFailed(error))), url: url, fail: fail)
        }
        
        switch method {
        case .post:
            queue.async {
                logRequest(url, method: .post, params: requestParams)
                let request = manager.post(requestUrl,
                                           params: requestParams,
                                           encoding: encoding ?? JSONEncoding.default,
                                           headers: headers ?? SRHttpManager.httpHeaders,
                                           success: successHandler,
                                           failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                requests.append(request)
            }
            
        case .get:
            queue.async {
                logRequest(url, method: .get, params: requestParams)
                let request = manager.get(requestUrl,
                                          params: requestParams,
                                          encoding: encoding ?? URLEncoding.default,
                                          headers: headers ?? SRHttpManager.httpHeaders,
                                          success: successHandler,
                                          failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                requests.append(request)
            }
            
        case .upload:
            queue.async {
                logRequest(url, method: .post, params: requestParams)
                manager.upload(requestUrl,
                               files: method.files,
                               params: requestParams,
                               encoding: encoding ?? URLEncoding.httpBody,
                               headers: headers ?? SRHttpManager.httpHeaders,
                               success: successHandler,
                               failure: failureHandler)
            }
        }
    }
    
    open func addExtraParam(_ params: inout ParamDictionary) {
        params[Param.Key.os] = OSVersion
        params[Param.Key.deviceModel] = SRCommon.devieModel()
        params[Param.Key.version] = AppVersion
        params[Param.Key.deviceId] = SRCommon.uuid()
        params[Param.Key.deviceToken] = SRCommon.currentDeviceToken()
        if SRCommon.isLogin {
            params[Param.Key.userId] = SRCommon.userId
        }
    }
    
    open class func logRequest(_ url: String, method: HTTPMethod, params: ParamDictionary) {
        LogInfo(String(format: "http request %@ url: %@\nparameters:\n%@",
                       method.rawValue,
                       url,
                       SRCommon.jsonString(params) ?? ""))
        if Environment == .production { return }
        
        let urlQuery = params.urlQuery
        lastRequstUrl = urlQuery.isEmpty ? url : url + "?" + urlQuery
        LogInfo("url:\n\(lastRequstUrl)")
    }
    
    //MARK: Analysis response data
    
    open class func analysis(_ data: Any?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.httpFailed(.responseSerializationFailed(nil)))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: data, options: .mutableContainers)
        } catch {
            return .failure(BFError.httpFailed(.responseSerializationFailed(error)))
        }
        
        if Environment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let errCode = json[HTTP.Key.Response.errorCode].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format."])
            return .failure(BFError.httpFailed(.responseSerializationFailed(nsError)))
        }
        
        return errCode.intValue == HTTP.ErrorCode.success ? .success(json) : .bfailure(json)
    }
    
    //MARK: Respond
    
    open class func respond(_ result: BFResult<Any>,
                       url: String?,
                       success: ((String?, Any) -> Void)? = nil,
                       bfail: ((String?, Any) -> Void)? = nil,
                       fail: ((String?, BFError) -> Void)? = nil) {
        if result.isSuccess, let success = success {
            success(url, result.value!)
        } else if result.isBFailure, let bfail = bfail {
            bfail(url, result.value!)
        } else if result.isFailure, let fail = fail {
            fail(url, result.error as! BFError)
        }
    }
}
