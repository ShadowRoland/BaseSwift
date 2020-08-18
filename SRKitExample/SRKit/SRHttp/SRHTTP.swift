//
//  SRHTTP.swift
//  SRKit
//
//  Created by Gary on 2020/1/2.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

public typealias HTTP = SRHTTP

public class SRHTTP {
    public static var defaultTimeout = 10.0 as TimeInterval
    public static var defaultRetryCount = 3
    
    open class Request {
        public enum Method: CustomDebugStringConvertible, CustomStringConvertible {
            case get
            case post
            case upload
            
            public var debugDescription: String {
                switch self {
                case .get:
                    return "GET"
                    
                case .post:
                    return "POST"
                    
                case .upload:
                    return "UPLOAD"
                }
            }
            
            public var description: String {
                return debugDescription
            }
        }
        
        public enum Option {
            case sender(String) ///请求发送者的对象地址
            case encoding(ParamEncoding) ///请求参数的编码方式
            case headers(ParamHeaders) ///请求头的参数
            case timeout(TimeInterval) ///超时时间
            case retryCount(Int) ///失败后重试的次数
            case parameterReplace(ParameterReplace)
        }
        
        open fileprivate(set) var method: Method
        open fileprivate(set) var originUrl: String {
            didSet {
                if !originUrl.hasPrefix("http:") && !originUrl.hasPrefix("https:") {
                    url = C.baseHttpURL.appending(urlComponent: originUrl)
                } else {
                    url = originUrl
                }
            }
        }
        open fileprivate(set) var url: String = ""
        open var params: ParamDictionary? = nil
        open var files: Array<ParamDictionary>? = nil
        
        open var options: [Option]? = nil {
            didSet {
                sender = nil
                encoding = nil
                headers = nil
                timeout = nil
                retryCount = nil
                parameterReplace = nil
                
                if let options = options {
                    for option in options {
                        switch option {
                        case .sender(let s):
                            sender = s
                            
                        case .encoding(let e):
                            encoding = e
                            
                        case .headers(let h):
                            headers = h
                            
                        case .timeout(let t):
                            timeout = t
                            
                        case .retryCount(let r):
                            retryCount = r
                            
                        case .parameterReplace(let p):
                            parameterReplace = p
                        }
                    }
                }
            }
        }
        open var sender: String?  = nil
        open var encoding: ParamEncoding?  = nil
        open var headers: ParamHeaders?  = nil
        open var timeout: TimeInterval?  = nil
        open var retryCount: Int? = nil
        open var parameterReplace: ParameterReplace? = nil
        
        open var request: DataRequest?
        open var response: AFDataResponse<Data?>?
        
        private init(_ method: Method,
                     url: String,
                     params: ParamDictionary?,
                     files: Array<ParamDictionary>?,
                     options: [Option]?) {
            self.method = method
            originUrl = url
            if !originUrl.hasPrefix("http:") && !originUrl.hasPrefix("https:") {
                self.url = C.baseHttpURL.appending(urlComponent: originUrl)
            } else {
                self.url = originUrl
            }
            self.params = params
            self.files = files
            self.options = options
        }
        
        public static func get(_ url: String,
                               params: ParamDictionary? = nil,
                               options: [Option]? = nil) -> Request {
            return .init(.get, url: url, params: params, files: nil, options: options)
        }
        
        public static func post(_ url: String,
                                params: ParamDictionary? = nil,
                                options: [Option]? = nil) -> Request {
            return .init(.post, url: url, params: params, files: nil, options: options)
        }
        
        public static func upload(_ url: String,
                                  files: Array<ParamDictionary>,
                                  params: ParamDictionary? = nil,
                                  options: [Option]? = nil) -> Request {
            return .init(.upload, url: url, params: params, files: nil, options: options)
        }
    }
    
    public struct Key {
        public struct Request: RawRepresentable, Hashable {
            public typealias RawValue = String
            public var rawValue: String
            
            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
        
        public struct Response { //需要和服务器端的返回字段保持一致，可定制
            public static var data = "data" //http请求返回的数据
            public static var code = "code"  //http请求返回的业务码，非http请求的stateCode
            public static var message = "message"  //http请求返回的提示信息
        }
    }
    
    public struct Code {
        public struct Response { //需要和服务器端的返回字段保持一致，可定制
            public static var success = 0  //http请求完全成功时的业务码
            public static var unknown = -99999  //http请求未知的业务码
        }
    }
    
    public enum Result<Value>: SRResult {
        case success(Value?)
        case failure(Failure<Any>)
        
        public var isSuccess: Bool {
            switch self {
            case .success:
                return true
                
            default:
                return false
            }
        }
        
        public var response: Any? {
            switch self {
            case .success(let value):
                return value
                
            case .failure(let failure):
                return failure.response
            }
        }
        
        public var code: Int {
            switch self {
            case .success(let value):
                return SRHTTP.Result<Value>.codeFromResponse(value) ?? SRHTTP.Code.Response.success
                
            case .failure(let failure):
                return failure.errorCode
            }
        }
        
        public var message: String {
            switch self {
            case .success(let value):
                return SRHTTP.Result<Value>.messageFromResponse(value) ?? ""
                
            case .failure(let failure):
                return failure.errorMessage
            }
        }
        
        fileprivate static func codeFromResponse(_ response: Any?) -> Int? {
            if let dictionary = responseDictionary(response),
                let code = dictionary[SRHTTP.Key.Response.code] as? Int {
                return code
            } else if let code = response as? Int {
                return code
            } else {
                return nil
            }
        }
        
        fileprivate static func messageFromResponse(_ response: Any?) -> String? {
            let dictionary = responseDictionary(response)
            if let message = dictionary?[SRHTTP.Key.Response.message] as? String {
                return message
            } else if let message = dictionary?[SRHTTP.Key.Response.data] as? String {
                return message
            } else if let message = response as? String {
                return message
            } else {
                return nil
            }
        }
        
        fileprivate static func responseDictionary(_ response: Any?) -> ParamDictionary? {
            if let json = response as? JSON, let dictionary = json.dictionary {
                return dictionary
            } else if let dictionary = response as? ParamDictionary {
                return dictionary
            } else {
                return nil
            }
        }
        
        public enum Failure<Value> {
            case business(Any?)
            case http(SRHTTP.Error?)
            
            public var isBusiness: Bool {
                switch self {
                case .business:
                    return true
                    
                default:
                    return false
                }
            }
            
            public var response: Any? {
                switch self {
                case .business(let value):
                    return value
                    
                default:
                    return nil
                }
            }
            
            public var error: SRHTTP.Error? {
                switch self {
                case .http(let error):
                    return error
                    
                default:
                    return nil
                }
            }
            
            public var errorCode: Int {
                switch self {
                case .business(let value):
                    return SRHTTP.Result<Value>.codeFromResponse(value) ?? SRHTTP.Code.Response.unknown
                    
                case .http(let error):
                    return error?.errorCode ?? SRHTTP.Code.Response.unknown
                }
            }
            
            public var errorMessage: String {
                switch self {
                case .business(let value):
                    return SRHTTP.Result<Value>.messageFromResponse(value) ?? ""
                    
                case .http(let error):
                    return error?.errorDescription ?? ""
                }
            }
        }
    }
    
    public class Error: BFError {
        public static var responseSerialization = SRHTTP.Error("[SR]Response serialization failed".srLocalized)
        
        public static func responseSerialization(_ error: Any?) -> SRHTTP.Error {
            if let string = error as? String {
                return SRHTTP.Error("\(responseSerialization.errorDescription!), \(string)")
            } else if let error = error as? Swift.Error {
                return SRHTTP.Error("\(responseSerialization.errorDescription!), \(error.localizedDescription)")
            } else {
                return responseSerialization
            }
        }
    }
    
    public struct ParameterReplace {
        public fileprivate(set) var postion: Position?
        public fileprivate(set) var keyValues: KeyValues?
        
        init(position: Position? = nil, keyValues: KeyValues? = nil) {
            self.postion = position
            self.keyValues = keyValues
        }
        
        ///根据给定的位置做值的替换，如positions为：
        ///{
        ///    "body" :
        ///    {
        ///        "contact" :
        ///        [
        ///            {
        ///                "phone" : "***",
        ///                "idNo" : "3403*****"
        ///            }
        ///        ]
        ///    }
        ///}
        ///在self的三层位置上的phone和idNo将会被替换为"***"和"3403*****"
        ///无论self的同样位置同样key对应的值是什么类型（字符串，数值，对象），都会被替换为positions中同样位置同样key对应的value
        ///PS: 数组的成员只能是字典或者数组，而且只遍历第一个成员
        public struct Position {
            public var request: ParamDictionary?
            public var response: ParamDictionary?
            
            init(request: ParamDictionary? = nil, response: ParamDictionary? = nil) {
                self.request = request
                self.response = response
            }
        }
        
        ///根据给定的键值对数组做值的替换，如keyValues为：
        ///{
        ///    "phone" : "***",
        ///    "idNo" : "3403*****"
        ///}
        ///在self的所有层次的位置上的phone和idNo将会被替换为"***"和"3403*****"
        ///无论self的所有层次职位上key对应的值是什么类型（字符串，数值，对象），都会被替换为keyValues中key对应的value
        public struct KeyValues {
            public var request: [String : String]?
            public var response: [String : String]?
            public var headers: [String : String]?
            
            init(request: [String : String]? = nil,
                 response: [String : String]? = nil,
                 headers: [String : String]? = nil) {
                self.request = request
                self.response = response
                self.headers = headers
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension SRHTTP.Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success:
            return "SUCCESS, code: \(code), message: \(message)"
        case .failure:
            return "FAILURE, code: \(code), message: \(message)"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension SRHTTP.Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS: \(String(describing: value))"
        case .failure(let error):
            return "FAILURE: \(error)"
        }
    }
}
