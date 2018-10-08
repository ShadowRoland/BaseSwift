//
//  HttpDefine.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/23.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

let HttpTimeout = 15.0 as TimeInterval //http请求超时时间

public struct HttpKey {
    public struct Request { //移动端App自定义
        public static let params = "request.params" //http请求的数据参数，value格式为[String : Any]
        public static let capacity = "request.capacity" //http请求枚举，value格式为HttpCapability
        public static let url = "request.url" //http请求指定的url，如果存在该参数，将不用使用默认的url，value的格式为String
        public static let encoding = "request.encoding" //http请求指定的encoding，如果存在该参数，将不用使用默认的encoding，value的格式为Alamofire.ParamEncoding
        public static let headers = "request.headers" //http请求指定的headers，如果存在该参数，将不用使用默认的headers，value的格式为[String : Any]
        public static let userInfo = "request.userInfo" //http请求的附加信息，内容由请求方定制，用来区别返回时的用途，value格式为[String : Any]
        public static let sender = "request.sender" //http请求的发送者指针的字符串，value格式为String
        public static let retryLeft = "request.retryLeft" //http请求重试的剩余次数
    }
    
    public struct Response { //需要和服务器端的返回字段保持一致
        public static let data = "data" //http请求返回的数据
        public static let errorCode = "code"  //http请求返回的错误码
        public static let errorMessage = "message"  //http请求返回的错误信息
    }
    
    public struct Upload { //移动端App自定义
        public static let files = "upload.files" //提交文件的列表，value格式为[[String : Any]]
        public static let data = "upload.data" //提交文件的字节内容，value格式为Data
        public static let path = "upload.path" //提交文件的本地路径，value格式为String
        public static let name = "upload.name" //提交文件的文件名，value格式为String
    }
}

//http请求返回的errCode
public struct HttpErrorCode {
    public static let success = 0  //http请求完全成功时的错误码
    public static let imSuccess = 200  //im http请求完全成功时的错误码
    public static let tokenExpired = 400001  //登录已失效
}

public extension Manager {
    public struct Http {
        public enum Capability {
            case function(Function)
            
            //MARK: Profile
            case get(Get)
            case post(Post)
            case upload(Upload)
            
            //根据使用频率调整判断优先度，默认post请求最频繁
            var funcId: UInt {
                switch self {
                case .post(let value):
                    return value.rawValue
                case .get(let value):
                    return value.rawValue
                case .function(let value):
                    return value.rawValue
                case .upload(let value):
                    return value.rawValue
                }
            }
            
            static public func ==(lhs: Capability, rhs: Capability?) -> Bool {
                return rhs != nil && lhs.funcId == rhs!.funcId
            }
            
            var isFunction: Bool {
                switch self {
                case .function:
                    return true
                    
                default:
                    return false
                }
            }
        }
        
        public static func capability(_ funcId: UInt) -> Capability? {
            if funcId >= Capability.post(.none).funcId {
                let post = HttpCapability.Post(rawValue: funcId)
                return post != nil ? .post(post!) : nil
            } else if funcId >= Capability.get(.none).funcId
                && funcId < Capability.post(.none).funcId  {
                let get = HttpCapability.Get(rawValue: funcId)
                return get != nil ? .get(get!) : nil
            } else if funcId >= Capability.function(.none).funcId
                && funcId < Capability.upload(.none).funcId  {
                let function = HttpCapability.Function(rawValue: funcId)
                return function != nil ? .function(function!) : nil
            } else if funcId >= Capability.upload(.none).funcId
                && funcId < Capability.get(.none).funcId {
                let upload = HttpCapability.Upload(rawValue: funcId)
                return upload != nil ? .upload(upload!) : nil
            }
            return nil
        }
    }
}

open class HttpDefine {
    private static var apis: [UInt : String] = [:]
    
    public class func api(_ capability: HttpCapability) -> String? {
        return apis[capability.funcId]
    }
    
    class func add(_ capability: HttpCapability, api: String) {
        apis[capability.funcId] = api
    }
}

public typealias HttpCapability = Manager.Http.Capability

//对HttpManager的请求分类，每个Capacity分配一个唯一的UInt枚举值，枚举值最大不能超过(2^13 - 1) = 8191
//每个分类枚举的第一个UInt枚举值为.none，其值为该分类功能的最小值
//每个分类下后面追加功能的UInt枚举值应该小于下一个分类的.none对应的UInt枚举值
extension HttpCapability {
    //内部功能
    public enum Function: UInt {
        case none = 0,
        
        clearRequests,
        updateToken,
        updateSecurityPolicy
    }
    
    public enum Upload: UInt {
        case none = 100,
        
        simpleUpload
    }
    
    public enum Get: UInt {
        case none = 200,
        
        profile,
        profileDetail,
        getVerificationCode,
        
        messages,
        sinaNewsList,
        newsSuggestions,
        sinaStockList,
        
        simpleData,
        simpleList
    }
    
    public enum Post: UInt {
        case none = 2000,
        
        login,
        logout,
        register,
        resetPassword,
        profileDetail,
        getIMToken,
        
        uploadFaceImage,
        faceImageAnalyze,
        
        simpleSubmit
    }
}

extension HttpDefine {
    public class func initAPIs() {
        //MARK: Profile
        add(.post(.login), api: "/user/login")
        add(.post(.register), api: "/user/register")
        add(.post(.resetPassword), api: "/user/resetPassword")
        add(.get(.profile), api: "/user/profile")
        add(.get(.profileDetail), api: "/user/profileDetail")
        add(.post(.profileDetail), api: "/user/profileDetail")
        add(.get(.getVerificationCode), api: "/getVerificationCode")
        add(.post(.getIMToken), api: "/user/getToken.json")
        
        //MARK: Simple
        add(.get(.simpleData), api: "/data/getSimpleData")
        add(.get(.simpleList), api: "/data/getSimpleList")
        add(.post(.simpleSubmit), api: "/data/simpleSubmit")
        
        //MARK: Message
        add(.get(.messages), api: "/data/getMessages")
        
        //MARK: Sina
        add(.get(.sinaNewsList), api: "/ent/feed.d.json")
        add(.get(.newsSuggestions), api: "/ajax/jsonp/suggestion")
        add(.get(.sinaStockList), api: "")
        
        //MARK: MSXiaoBing
        add(.post(.uploadFaceImage), api: "/Image/UploadBase64")
        add(.post(.faceImageAnalyze), api: "/ImageAnalyze/Process?service=yanzhi")
    }
}
