//
//  HttpManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON

public class HttpManager: SRHttpManager {
    public class var shared: SRHttpManager {
        return sharedInstance
    }
    
    private static var sharedInstance = SRHttpManager()
    
    private override init() {
        super.init()
    }
    
    //MARK: Analysis response data
    
    override public func analysis(_ method: HTTP.Method, data: Any?) -> BFResult<Any> {
        var result: BFResult<Any>?
        switch method {
        case .get:
            let url = method.url
            if url == "http://interface.sina.cn/ent/feed.d.json" {
                result = analysisSina(data)
            } else if url == "http://interface.sina.cn/ajax/jsonp/suggestion" {
                result = analysisSearchSuggestion(data)
            } else if url == "http://s.weibo.com" {
                result = .success(data)
            } else if url == "http://api.cn.ronghub.com/user/getToken.json" {
                result = analysisIM(data)
            } else if url.hasPrefix("http://kan.msxiaobing.com/Api") {
                result = analysisMSXiaoBing(data)
            }
        default:
            break
        }

        if let result = result {
            return result
        }

        result = super.analysis(method, data: data)
        if result!.isSuccess {

        }

        return result!
    }
    
    func analysisSina(_ data: Any?, jsonCallback: String? = nil) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.http(.responseSerialization(nil)))
        }
        
        guard var jsonString = String(data: data, encoding: .utf8) else {
            return .failure(BFError.http(.responseSerialization(nil)))
        }
        
        if let jsonCallback = jsonCallback, !isEmptyString(jsonCallback) {
            //jsonP ->json
            let leadText = jsonCallback + "("
            let tailText = ");\n"
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
            return .failure(BFError.http(.responseSerialization(error)))
        }
        
        if Environment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let status = json[Param.Key.status].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format"])
            return .failure(BFError.http(.responseSerialization(nsError)))
        }
        
        return status.intValue == 1 ? .success(json) : .bfailure(json)
    }
    
    func analysisSearchSuggestion(_ data: Any?, cb: String? = nil) -> BFResult<Any> {
        guard let data = data as? Data else {
            return .failure(BFError.http(.responseSerialization(nil)))
        }
        
        guard var jsonString = String(data: data, encoding: .utf8) else {
            return .failure(BFError.http(.responseSerialization(nil)))
        }
        
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
            return .failure(BFError.http(.responseSerialization(error)))
        }
        
        if Environment != .production {
            LogInfo("json response string:\n\(json.rawString()!)")
        }
        
        guard let code = json[Param.Key.code].number else {
            let nsError =
                NSError(domain: NSCocoaErrorDomain,
                        code: -9999,
                        userInfo: [NSLocalizedDescriptionKey : "Invalid response JSON format"])
            return .failure(BFError.http(.responseSerialization(nsError)))
        }
        
        return code.intValue == 100000 ? .success(json) : .bfailure(json)
    }
    
    func analysisIM(_ data: Any?) -> BFResult<Any> {
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
        
        return errCode.intValue == HTTP.ErrorCode.imSuccess ? .success(json) : .bfailure(json)
    }
    
    //MARK: Analysis MSXiaoBing
    
    func analysisMSXiaoBing(_ data: Any?) -> BFResult<Any> {
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
        
        return .success(json)
    }
}

extension HTTP.ErrorCode {
    public static let imSuccess = 200  //im http请求完全成功时的错误码
}
