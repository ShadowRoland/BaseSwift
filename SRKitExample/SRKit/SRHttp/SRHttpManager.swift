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
    public init() {
        startNetworkMonitor()
    }
    
    var managers: [String : SRHttpTool] = [:]
    public static var queue = DispatchQueue(label: "com.srhttp.manager",
                                            qos: .utility,
                                            attributes: .concurrent)
    public var requests: [DataRequest] = []
    public var defaultRequestHeaders: ParamHeaders = [:]
    public var defaultRequestParams: ParamDictionary  {
        var params = [:] as ParamDictionary
        params[Param.Key.os] = OSVersion
        params[Param.Key.deviceModel] = DevieModel
        params[Param.Key.version] = AppVersion
        params[Param.Key.deviceId] = DeviceId
        return params
    }
    
    open func cancel(sender: String?) {
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
    
    open func cancel(_ requst: URLRequest?) {
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
    
    open func remove(_ requst: URLRequest?) {
        guard let requst = requst else { return }
        objc_sync_enter(requests)
        requests = requests.filter { requst != $0.request }
        objc_sync_exit(requests)
    }
    
    //MARK: - Request
    
    public static var lastRequstUrl = ""
    
    open func request(_ method: HTTP.Method,
                        sender: String?,
                        encoding: ParamEncoding?,
                        headers: ParamHeaders?,
                        options: [HTTP.Key.Option : Any]?,
                        success: ((Any) -> Void)?,
                        bfail: ((HTTP.Method, Any) -> Void)?,
                        fail: ((HTTP.Method, BFError) -> Void)?) {
        let url = method.url
        guard let requestUrl = URL(string: url) else {
            let error =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid http request url"])
            respond(.failure(BFError.http(.afResponse(error))),
                    method: method,
                    fail: fail)
            return
        }
        
        var requestParams = method.params ?? [:]
        requestParams += defaultRequestParams
        let successHandler: (URLRequest?, Any?) -> Void = { request, data in
            self.remove(request)
            if Environment != .production {
                LogInfo(String(format: "http response %@ url: %@", method.type, url))
            }
            self.respond(self.analysis(method, data: data),
                         method: method,
                         success: success,
                         bfail: bfail)
        }
        let failureHandler: (URLRequest?, Error) -> Void = { request, error in
            self.remove(request)
            if Environment != .production {
                LogInfo(String(format: "http response %@ url: %@", method.type, url))
            }
            self.respond(.failure(BFError.http(.afResponse(error))),
                         method: method,
                         fail: fail)
        }
        
        let manager = self.manager(option: options)
        switch method {
        case .post:
            SRHttpManager.queue.async {
                self.logRequest(method, params: requestParams)
                let request = manager.post(requestUrl,
                                           params: requestParams,
                                           encoding: encoding ?? JSONEncoding.default,
                                           headers: headers ?? self.defaultRequestHeaders,
                                           success: successHandler,
                                           failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                self.requests.append(request)
            }
            
        case .get:
            SRHttpManager.queue.async {
                self.logRequest(method, params: requestParams)
                let request = manager.get(requestUrl,
                                          params: requestParams,
                                          encoding: encoding ?? URLEncoding.default,
                                          headers: headers ?? self.defaultRequestHeaders,
                                          success: successHandler,
                                          failure: failureHandler)
                if let sender = sender {
                    request.sender = sender
                }
                self.requests.append(request)
            }
            
        case .upload:
            SRHttpManager.queue.async {
                self.logRequest(method, params: requestParams)
                manager.upload(requestUrl,
                               files: method.files,
                               params: requestParams,
                               encoding: encoding ?? URLEncoding.httpBody,
                               headers: headers ?? self.defaultRequestHeaders,
                               success: successHandler,
                               failure: failureHandler)
            }
        }
    }
    
    open func manager(option: [HTTP.Key.Option : Any]?) -> SRHttpTool {
        let timeout = option?[.timeout] as? TimeInterval ?? HTTP.defaultTimeout
        let retryCount = option?[.retryCount] as? Int ?? HTTP.defaultRetryCount
        let key = "\(timeout)/,\(retryCount)/"
        var manager = managers[key]
        if manager == nil {
            manager = SRHttpTool(timeout, retryCount: retryCount)
            managers[key] = manager
        }
        return manager!
    }
    
    open func logRequest(_ method: HTTP.Method, params: ParamDictionary) {
        let url = method.url
        LogInfo(String(format: "New http request: %@, url: %@\nparameters:\n%@",
                       method.type,
                       url,
                       String(jsonObject: params)))
        
        if Environment == .production { return }
        let urlQuery = params.urlQuery
        SRHttpManager.lastRequstUrl = urlQuery.isEmpty ? url : url + "?" + urlQuery
        LogInfo("url:\n\(SRHttpManager.lastRequstUrl)")
    }
    
    //MARK: Analysis response data
    
    open func analysis(_ method: HTTP.Method, data: Any?) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.http(.responseSerialization(nil)))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: data, options: .mutableContainers)
        } catch {
            return .failure(BFError.http(.responseSerialization(error)))
        }
        
        if Environment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let errCode = json[HTTP.Key.Response.errorCode].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format"])
            return .failure(BFError.http(.responseSerialization(nsError)))
        }
        
        return errCode.intValue == HTTP.ErrorCode.success ? .success(json) : .bfailure(json)
    }
    
    //MARK: Respond
    
    open func respond(_ result: BFResult<Any>,
                            method: HTTP.Method,
                            success: ((Any) -> Void)? = nil,
                            bfail: ((HTTP.Method, Any) -> Void)? = nil,
                            fail: ((HTTP.Method, BFError) -> Void)? = nil) {
        DispatchQueue.main.async {
            if result.isSuccess, let success = success {
                success(result.value!)
            } else if result.isBFailure, let bfail = bfail {
                bfail(method, result.value!)
            } else if result.isFailure, let fail = fail {
                fail(method, result.error as! BFError)
            }
        }
    }
    
    //MARK: Listener
    
    private class SRHttpListenerObject {
        init() { }
        weak var target: NSObject?
        var action: Selector?
    }
    
    private var listeners: [SRHttpListenerObject] = []
    
    open func addListener(forNetworkStatus target: NSObject?, action: Selector?) {
        guard let target = target, let action = action else {
            return
        }
        
        objc_sync_enter(listeners)
        listeners = listeners.filter { $0.target == nil }
        let object = SRHttpListenerObject()
        object.target = target
        object.action = action
        listeners.append(object)
        objc_sync_exit(listeners)
    }
    
    open func removeListener(forNetworkStatus target: NSObject?, action: Selector? = nil) {
        guard let target = target else {
            return
        }
        objc_sync_enter(listeners)
        listeners = listeners.filter {
            if let action = action {
                return $0.target != target && $0.action != action
            } else {
                return $0.target != target
            }
        }
        objc_sync_exit(listeners)
    }
    
    private var _networkStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .notReachable
    public var networkStatus: NetworkReachabilityManager.NetworkReachabilityStatus { return _networkStatus }
    
    private var _networkMonitor: NetworkReachabilityManager? = nil
    private var networkMonitor: NetworkReachabilityManager? {
        if _networkMonitor == nil {
            _networkMonitor = NetworkReachabilityManager()
            _networkMonitor?.listener = { status in
                self._networkStatus = status
                self.listeners.forEach { $0.target?.perform($0.action, with: status) }
            }
        }
        return _networkMonitor
    }
    
    open func startNetworkMonitor() {
        networkMonitor?.startListening()
    }
    
    open func stoptNetworkMonitor() {
        networkMonitor?.stopListening()
    }
}
