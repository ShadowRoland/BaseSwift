//
//  HttpManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import Alamofire

public class HttpManager: SRHttpManager {
    public class var shared: HttpManager {
        return sharedInstance
    }
    
    private static var sharedInstance = HttpManager()
    
    private override init() {
        super.init()
    }
    
    public override var defaultRequestHeaders: ParamHeaders {
        var params = super.defaultRequestHeaders
        if let currentProfile = ProfileManager.currentProfile,
            currentProfile.isLogin,
            let token = currentProfile.token {
            params[Param.Key.token] = token
        }
        return params
    }
    
    public override var defaultRequestParams: ParamDictionary {
        var params = super.defaultRequestParams
        if let currentProfile = ProfileManager.currentProfile, currentProfile.isLogin {
            if let userId = currentProfile.userId {
                params[Param.Key.userId] = userId
            }
            if let token = currentProfile.token {
                params[Param.Key.token] = token
            }
            return params
        }
        return params
    }
    
    //MARK: Analysis response data
    
    public override func analysis(_ request: SRHTTP.Request) -> SRHTTP.Result<Any> {
        var result: HTTP.Result<Any>?
        switch request.method {
        case .get:
            let url = request.url
            if url == "http://interface.sina.cn/ent/feed.d.json" {
                result = analysisSina(request, jsonCallback: "callback")
            } else if url == "http://interface.sina.cn/ajax/jsonp/suggestion" {
                result = analysisSearchSuggestion(request)
            } else if url == "http://s.weibo.com" {
                result = .success(request.response?.data)
            } else if url == "http://api.cn.ronghub.com/user/getToken.json" {
                result = analysisIM(request)
            } else if url.hasPrefix("http://kan.msxiaobing.com/Api") {
                result = analysisMSXiaoBing(request)
            }
            
        default:
            break
        }

        if let result = result {
            return result
        }

        result = super.analysis(request)
        if result!.isSuccess {
            if request.url == C.baseHttpURL.appending(urlComponent: "user/login"),
                let json = result!.response as? JSON,
                let dictionary = json[HTTP.Key.Response.data].dictionaryObject,
                let profile = ProfileModel(JSON: dictionary) {
                print("dictionary:----\(String(jsonObject: dictionary))")
                profile.isLogin = true
                ProfileManager.currentProfile = profile
            }
        }

        return result!
    }
    
    func analysisSina(_ request: SRHTTP.Request, jsonCallback: String? = nil) -> HTTP.Result<Any> {
        guard let response = request.response,
            let jsonData = response.data,
            let string = String(data: jsonData, encoding: .utf8) else {
                logResponse(request, data: request.response?.data)
                return .failure(.http(.responseSerialization))
        }
        
        var jsonString = string
        if let jsonCallback = jsonCallback, !isEmptyString(jsonCallback) {
            //jsonP ->json
            let leadText = jsonCallback + "("
            let tailText = ");\n"
            if jsonString.substring(to: leadText.count) == leadText
                && jsonString.substring(from: max(jsonString.count - tailText.count, 0)) == tailText {
                jsonString = jsonString.substring(from: leadText.count,
                                                  to: jsonString.count - tailText.count - 1)
            }
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonString.data(using: .utf8, allowLossyConversion: false)!,
                            options: .mutableContainers)
        } catch {
            logResponse(request, data: jsonData)
            return .failure(.http(.responseSerialization(error)))
        }
        
        logResponse(request, data: json)
        
        guard let status = json[Param.Key.status].number else {
            return .failure(.http(.responseSerialization("can not find integer \(Param.Key.status) in JSON object")))
        }
        
        return status.intValue == 1 ? .success(json) : .failure(.business(json))
    }
    
    func analysisSearchSuggestion(_ request: SRHTTP.Request, cb: String? = nil) -> HTTP.Result<Any> {
        guard let response = request.response,
            let jsonData = response.data,
            let string = String(data: jsonData, encoding: .utf8) else {
                logResponse(request, data: request.response?.data)
                return .failure(.http(.responseSerialization))
        }
        
        var jsonString = string
        if let cb = cb, !isEmptyString(cb) {
            let leadText = "try{window.\(cb)&\(cb)("
            let tailText = ");}catch(e){}"
            if jsonString.substring(to: leadText.count) == leadText
                && jsonString.substring(from: max(jsonString.count - tailText.count, 0)) == tailText {
                jsonString = jsonString.substring(from: leadText.count,
                                                  to: jsonString.count - tailText.count)
            }
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonString.data(using: .utf8, allowLossyConversion: false)!,
                            options: .mutableContainers)
        } catch {
            logResponse(request, data: jsonData)
            return .failure(.http(.responseSerialization(error)))
        }
        
        logResponse(request, data: json)
        
        guard let code = json[Param.Key.code].number else {
            return .failure(.http(.responseSerialization("can not find integer \(Param.Key.code) in JSON object")))
        }
        
        return code.intValue == 100000 ? .success(json) : .failure(.business(json))
    }
    
    func analysisIM(_ request: SRHTTP.Request) -> HTTP.Result<Any> {
        guard let response = request.response, let jsonData = response.data else {
            logResponse(request, data: request.response?.data)
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
        
        guard let code = json[HTTP.Key.Response.code].number else {
            return .failure(.http(.responseSerialization("can not find integer \(HTTP.Key.Response.code) in JSON object")))
        }
        
        return code.intValue == HTTP.Code.Response.imSuccess ? .success(json) : .failure(.business(json))
    }
    
    //MARK: Analysis MSXiaoBing
    
    func analysisMSXiaoBing(_ request: SRHTTP.Request) -> HTTP.Result<Any> {
        guard let response = request.response, let jsonData = response.data else {
            logResponse(request, data: request.response?.data)
            return .failure(.http(.responseSerialization))
        }
        
        var json: JSON!
        do {
            json = try JSON(data: jsonData, options: .mutableContainers)
        } catch {
            logResponse(request, data: response.data)
            return .failure(.http(.responseSerialization(error)))
        }
        
        logResponse(request, data: json)
        
        return .success(json)
    }
}

extension HTTP.Code.Response {
    public static let imSuccess = 200  //im http请求完全成功时的错误码
}
