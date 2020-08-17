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
    public var requests: [SRHTTP.Request] = []
    
    open var defaultRequestHeaders: ParamHeaders {
        return Alamofire.SessionManager.defaultHTTPHeaders
    }
    
    open var defaultRequestParams: ParamDictionary  {
        var params = [:] as ParamDictionary
        params[Param.Key.os] = C.osVersion
        params[Param.Key.deviceModel] = C.deviceModel
        params[Param.Key.version] = C.appVersion
        params[Param.Key.deviceId] = C.deviceId
        return params
    }
    
    open var sessionDelegate = SessionDelegate()
    
    ///打印http请求日志的环境，默认为不再非生产环境的所有环境
    open var logRequestEnvironment: Const.RunEnvironment = .nonProduction
    ///打印http返回日志的环境，默认为不再非生产环境的所有环境
    open var logResponseEnvironment: Const.RunEnvironment = .nonProduction

    open func cancel(sender: String?) {
        guard let sender = sender else { return }
        objc_sync_enter(requests)
        requests = requests.filter { request in
            if let options = request.options, nil != options.first(where: {
                switch $0 {
                case .sender(let s):
                    return sender == s
                    
                default:
                    return false
                }
            }) {
                SRHttpManager.queue.async { request.request?.cancel() }
                return false
            } else {
                return true
            }
        }
        objc_sync_exit(requests)
    }
    
    open func cancel(_ request: SRHTTP.Request?) {
        guard let request = request else { return }
        objc_sync_enter(requests)
        requests = requests.filter {
            if request === $0 {
                SRHttpManager.queue.async { request.request?.cancel() }
                return false
            } else {
                return true
            }
        }
        objc_sync_exit(requests)
    }
    
    open func remove(_ request: SRHTTP.Request?) {
        guard let request = request else { return }
        objc_sync_enter(requests)
        requests = requests.filter { request !== $0 }
        objc_sync_exit(requests)
    }
    
    //MARK: - Request
    
    public static var lastRequestUrl = ""
    
    open func request(_ request: SRHTTP.Request,
                      success: ((Any) -> Void)?,
                      failure: ((SRHTTP.Result<Any>.Failure<Any>) -> Void)?) {
        let url = request.url
        guard let requestUrl = URL(string: url) else {
            respond(.failure(.http(.init("Invalid http request url"))), failure: failure)
            return
        }
        
        var params = request.params ?? [:]
        params += defaultRequestParams
        request.params = params
        
        if request.headers == nil {
            request.headers = self.defaultRequestHeaders
        }
        
        let manager = self.manager(request.timeout, retryCount: request.retryCount)
        switch request.method {
        case .post:
            SRHttpManager.queue.async {
                if request.encoding == nil {
                    request.encoding = JSONEncoding.default
                }
                self.logRequest(request)
                request.request = manager.post(requestUrl,
                                           params: request.params!,
                                           encoding: request.encoding!,
                                           headers: request.headers!)
                { response in
                    request.response = response
                    self.complete(request, success: success, failure: failure)
                }
                self.requests.append(request)
            }
            
        case .get:
            SRHttpManager.queue.async {
                if request.encoding == nil {
                    request.encoding = URLEncoding.default
                }
                self.logRequest(request)
                request.request = manager.get(requestUrl,
                                              params: request.params!,
                                              encoding: request.encoding!,
                                              headers: request.headers!)
                { response in
                    request.response = response
                    self.complete(request, success: success, failure: failure)
                }
                self.requests.append(request)
            }
            
        case .upload:
            SRHttpManager.queue.async {
                if request.encoding == nil {
                    request.encoding = URLEncoding.httpBody
                }
                if request.files == nil {
                    request.files = []
                }
                self.logRequest(request)
                request.request = nil
                manager.upload(requestUrl,
                               files: request.files!,
                               params: request.params!,
                               encoding: request.encoding!,
                               headers: request.headers!)
                { response in
                    request.response = .init(request: response.request,
                                             response: response.response,
                                             data: response.data,
                                             error: response.error,
                                             timeline: response.timeline,
                                             metrics: nil)
                    self.complete(request, success: success, failure: failure)
                }
                self.requests.append(request)
            }
        }
    }
    
    open func manager(_ timeout: TimeInterval?, retryCount: Int?) -> SRHttpTool {
        let key = "\(timeout ?? SRHTTP.defaultTimeout)/,\(retryCount ?? SRHTTP.defaultRetryCount)/"
        var manager = managers[key]
        if manager == nil {
            manager = SRHttpTool(timeout ?? SRHTTP.defaultTimeout,
                                 retryCount: retryCount ?? SRHTTP.defaultRetryCount,
                                 sessionDelegate: sessionDelegate)
            managers[key] = manager
        }
        return manager!
    }
    
    //MARK: Analysis response data
    
    open func analysis(_ request: SRHTTP.Request) -> SRHTTP.Result<Any> {
        let response = request.response
        guard let jsonData = response?.data else {
            logResponse(request)
            return .failure(.http(.responseSerialization))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonData, options: .mutableContainers)
        } catch {
            logResponse(request, data: jsonData)
            return .failure(.http(.responseSerialization(error)))
        }
        
        logResponse(request, data: json)
        
        guard let code = json[SRHTTP.Key.Response.code].number else {
            return .failure(.http(.responseSerialization("can not find integer \(SRHTTP.Key.Response.code) in JSON object")))
        }
        
        return code.intValue == SRHTTP.Code.Response.success ? .success(json) : .failure(.business(json))
    }
    
    //MARK: Respond
    
    open func complete(_ request: SRHTTP.Request,
                       success: ((Any) -> Void)?,
                       failure: ((SRHTTP.Result<Any>.Failure<Any>) -> Void)?) {
        remove(request)
        let response = request.response
        if response?.error == nil {
            respond(analysis(request), success: success, failure: failure)
            return
        }
        
        logResponse(request)
        if let retryCount = request.retryCount, retryCount > 0 {
            request.retryCount = retryCount - 1
            SRHttpManager.queue.async {
                self.request(request, success: success, failure: failure)
            }
        } else {
            respond(.failure(.http(.init(response?.error?.localizedDescription ?? "[SR]Network request exception".localized,
                                         code: response?.response?.statusCode ?? SRHTTP.Code.Response.unknown))),
                    failure: failure)
        }
    }
    
    open func respond(_ result: SRHTTP.Result<Any>,
                      success: ((Any) -> Void)? = nil,
                      failure: ((SRHTTP.Result<Any>.Failure<Any>) -> Void)? = nil) {
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                success?(response ?? [:] as AnyDictionary)
                
            case .failure(let failureResponse):
                failure?(failureResponse)
            }
        }
    }
    
    //MARK: Log request body and response data
    
    open func logRequest(_ request: SRHTTP.Request) {
        guard logRequestEnvironment.contains(C.environment) else { return }
        
        var headers = request.headers
        if headers != nil,
            let parameterReplace = request.parameterReplace,
            let keyValues = parameterReplace.keyValues?.headers {
            headers = HTTPHeaders((headers!.dictionary.replacingOccurrences(keyValues: keyValues)) as! [String : String])
        }
        
        var params = request.params!
        if let parameterReplace = request.parameterReplace {
            if let postion = parameterReplace.postion?.request {
                params = params.replacingOccurrences(positions: postion)
            }
            if let keyValues = parameterReplace.keyValues?.request {
                params = params.replacingOccurrences(keyValues: keyValues)
            }
        }
        
        if let headers = headers, !headers.isEmpty {
            LogInfo(String(format: "New http request: %@, url: %@\nheader:%@\nbody:\n%@",
                           request.method.description,
                           request.url,
                           String(jsonObject: headers),
                           String(jsonObject: params)))
        } else {
            LogInfo(String(format: "New http request: %@, url: %@\nbody:\n%@",
                           request.method.description,
                           request.url,
                           String(jsonObject: params)))
        }
        let urlQuery = params.urlQuery
        SRHttpManager.lastRequestUrl = urlQuery.isEmpty ? request.url : request.url + "?" + urlQuery
        LogInfo("url:\n\(SRHttpManager.lastRequestUrl)")
    }
    
    open func logResponse(_ request: SRHTTP.Request, data: Any? = nil) {
        guard logResponseEnvironment.contains(C.environment) else { return }
        
        func replace(_ dictionary: ParamDictionary,
                     postion: ParamDictionary?,
                     keyValues: [String : String]?) -> ParamDictionary {
            var targetDictionary = dictionary
            if let postion = postion {
                targetDictionary = targetDictionary.replacingOccurrences(positions: postion)
            }
            if let keyValues = keyValues {
                targetDictionary = targetDictionary.replacingOccurrences(keyValues: keyValues)
            }
            return targetDictionary
        }
        
        let response = request.response!
        LogInfo(String(format: "http response %@ url: %@, request duration: %.4fs, total duration: %.4fs",
                       request.method.description,
                       request.url,
                       response.timeline.requestDuration,
                       response.timeline.totalDuration))
        if let error = response.error {
            if let statusCode = response.response?.statusCode {
                LogError("status code: \(statusCode), description: \(error.localizedDescription)")
            } else {
                LogError(error.localizedDescription)
            }
        } else if let json = data as? JSON {
            if let parameterReplace = request.parameterReplace,
                parameterReplace.postion?.response != nil || parameterReplace.keyValues?.response != nil {
                let object = json.object
                if let dictionary = object as? ParamDictionary {
                    let jsonObject = replace(dictionary,
                                             postion: parameterReplace.postion?.response,
                                             keyValues: parameterReplace.keyValues?.response)
                    LogInfo("response body json string:\n\(String(jsonObject: jsonObject))")
                } else if let array = object as? [ParamDictionary] {
                    let jsonObject = array.compactMap {
                        replace($0,
                                postion: parameterReplace.postion?.response,
                                keyValues: parameterReplace.keyValues?.response)
                    }
                    LogInfo("response body json string:\n\(String(jsonObject: jsonObject))")
                } else {
                    LogInfo("response body json string:\n\(json.rawString() ?? "")")
                }
            } else {
                LogInfo("response body json string:\n\(json.rawString() ?? "")")
            }
        } else if let dictionary = data as? ParamDictionary {
            var targetDictionary = dictionary
            if let parameterReplace = request.parameterReplace,
                parameterReplace.postion?.response != nil || parameterReplace.keyValues?.response != nil {
                targetDictionary = replace(dictionary,
                                           postion: parameterReplace.postion?.response,
                                           keyValues: parameterReplace.keyValues?.response)
            }
            let jsonString = String(jsonObject: targetDictionary)
            if !jsonString.isEmpty {
                LogInfo("response body json string:\n\(jsonString)")
            } else {
                LogInfo("response body:\n\(String(describing: targetDictionary))")
            }
        } else if let array = data as? [ParamDictionary] {
            var targetArray = array
            if let parameterReplace = request.parameterReplace,
                parameterReplace.postion?.response != nil || parameterReplace.keyValues?.response != nil {
                targetArray = array.compactMap {
                    replace($0,
                            postion: parameterReplace.postion?.response,
                            keyValues: parameterReplace.keyValues?.response)
                }
            }
            let jsonString = String(jsonObject: targetArray)
            if !jsonString.isEmpty {
                LogInfo("response body json string:\n\(jsonString)")
            } else {
                LogInfo("response body:\n\(String(describing: targetArray))")
            }
        } else if let data = data {
            LogInfo("response body:\n\(String(describing: data))")
        }
    }
    
    //MARK: Listener
    
    private class SRHttpListenerObject {
        init() { }
        weak var target: NSObject?
        var action: Selector?
        var queue: DispatchQueue?
    }
    
    private var listeners: [SRHttpListenerObject] = []
    
    open func addListener(forNetworkStatusChanged target: NSObject?, action: Selector?) {
        addListener(forNetworkStatusChanged: target, action: action, queue: nil)
    }
    
    open func addListener(forNetworkStatusChanged target: NSObject?, action: Selector?, queue: DispatchQueue?) {
        guard let target = target, let action = action else {
            return
        }
        
        objc_sync_enter(listeners)
        listeners = listeners.filter { $0.target == nil }
        let object = SRHttpListenerObject()
        object.target = target
        object.action = action
        if let queue = queue {
            object.queue = queue
        } else if Thread.isMainThread {
            object.queue = DispatchQueue.main
        }
        listeners.append(object)
        objc_sync_exit(listeners)
    }
    
    open func removeListener(forNetworkStatusChanged target: NSObject?, action: Selector? = nil) {
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
        }
        return _networkMonitor
    }
    
    open func startNetworkMonitor() {
        networkMonitor?.startListening(onQueue: SRHttpManager.queue, onUpdatePerforming: { [weak self] (status) in
            guard let strongSelf = self else { return }
            if strongSelf._networkStatus != status {
                strongSelf._networkStatus = status
                strongSelf.listeners.forEach { listener in
                    listener.queue?.async {
                        listener.target?.perform(listener.action, with: status)
                    }
                }
            }
        })
    }
    
    open func stoptNetworkMonitor() {
        networkMonitor?.stopListening()
    }
}
