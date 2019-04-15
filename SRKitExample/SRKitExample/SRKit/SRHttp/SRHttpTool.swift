//
//  SRHttpTool.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/23.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import Alamofire

public class HTTP {
    static var timeout = 15.0 as TimeInterval //http请求超时时间
    
    public enum Method<Value> {
        case get(Value?)
        case post(Value?)
        case upload(Value?)
        
        public var url: String? {
            switch self {
            case .get(let value):
                if let url = value as? String {
                    return url
                } else if let dictionary = value as? Dictionary<Key.Request, Any>,
                    let url = dictionary[.url] as? String {
                    return url
                }
                
            case .post(let value):
                if let url = value as? String {
                    return url
                } else if let dictionary = value as? Dictionary<Key.Request, Any>,
                    let url = dictionary[.url] as? String {
                    return url
                }
                
            case .upload(let value):
                if let url = value as? String {
                    return url
                } else if let dictionary = value as? Dictionary<Key.Request, Any>,
                    let url = dictionary[.url] as? String {
                    return url
                }
            }
            
            return nil
        }
        
        public var files: Array<ParamDictionary>? {
            switch self {
            case .upload(let value):
                if let dictionary = value as? Dictionary<Key.Request, Any>,
                    let files = dictionary[.files] as? Array<ParamDictionary> {
                    return files
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }
    
    public struct Key {
        public struct Request: Equatable, Hashable, RawRepresentable {
            public typealias RawValue = String
            public var rawValue: String
            
            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public var hashValue: Int { return self.rawValue.hashValue }
        }
        
        public struct Response { //需要和服务器端的返回字段保持一致，可定制
            public static var data = "data" //http请求返回的数据
            public static var errorCode = "code"  //http请求返回的错误码，非stateCode
            public static var errorMessage = "message"  //http请求返回的错误信息
        }
    }
    
    public struct ErrorCode {
        public static var success = 0  //http请求完全成功时的错误码
    }
}

extension HTTP.Key.Request {
    public static let url = HTTP.Key.Request("request.url")
    public static let files = HTTP.Key.Request("request.files")
    public static let sender = HTTP.Key.Request("request.sender")
    public static let retryLeft = HTTP.Key.Request("request.retryLeft")
}

public extension DataRequest {
    fileprivate struct AssociatedKeys {
        static var requestSender = "DataRequest.requestSender"
    }
    
    var sender: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.requestSender) as? String
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.requestSender,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public class SRHttpTool {
    public var tag = 0
    public var queue: DispatchQueue!
    public var retryCount = 0
    public var manager: Alamofire.SessionManager!
    public var httpsServerCer: Data? {
        didSet {
            loadSecurityPolicy()
        }
    }
    public var httpsClientP12: Array<ParamDictionary>? {
        didSet {
            loadSecurityPolicy()
        }
    }
    
    public init(_ timeout: TimeInterval, retryCount: Int = 0) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeout
        manager = SessionManager(configuration: configuration)
        self.retryCount = retryCount
    }
    
    //设置
    public func loadSecurityPolicy() {
        //详见参考http://www.hangge.com/blog/cache/detail_1052.html
        manager.delegate.sessionDidReceiveChallenge = {[weak self] session, challenge in
            let method = challenge.protectionSpace.authenticationMethod
            if method == NSURLAuthenticationMethodServerTrust, //认证服务器端证书
                let httpsServerCer = self?.httpsServerCer,
                let serverTrust = challenge.protectionSpace.serverTrust,
                let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                let remoteCertificateData = CFBridgingRetain(SecCertificateCopyData(certificate)),
                remoteCertificateData.isEqual(httpsServerCer) {
                //print("server certificate")
                let credential = URLCredential(trust: serverTrust)
                challenge.sender?.use(credential, for: challenge)
                return (.useCredential, URLCredential(trust: serverTrust))
            } else if method == NSURLAuthenticationMethodClientCertificate, //认证客户端证书
                //print("client certificate")
                let item = self?.httpsClientP12?.first {
                return (.useCredential,
                        URLCredential(identity: item["identity"] as! SecIdentity,
                                      certificates: item["chain"] as? [Any],
                                      persistence: .forSession))
                
            }
            //print("reject")
            return (.cancelAuthenticationChallenge, nil)
        }
    }
    
    //MARK: GET
    
    public func get(_ url: URL,
                    params: ParamDictionary,
                    encoding: ParamEncoding,
                    headers: [String: String],
                    success: ((URLRequest?, Any?) -> Void)? = nil,
                    failure: ((URLRequest?, Error) -> Void)? = nil) -> DataRequest {
        return manager.request(url,
                               method: .get,
                               parameters: params,
                               encoding: encoding,
                               headers: headers)
            .response(queue: queue) { response in
                if let error = response.error, let failure = failure {
                    if let localizedDescription = response.error?.localizedDescription {
                        LogError(localizedDescription)
                    }
                    failure(response.request, error)
                    return
                }
                
                if let success = success {
                    success(response.request, response.data)
                }
        }
    }
    
    //MARK: POST
    
    public func post(_ url: URL,
                     params: ParamDictionary,
                     encoding: ParamEncoding,
                     headers: [String: String],
                     success: ((URLRequest?, Any?) -> Void)? = nil,
                     failure: ((URLRequest?, Error) -> Void)? = nil) -> DataRequest {
        return manager.request(url,
                               method: .post,
                               parameters: params,
                               encoding: encoding,
                               headers: headers)
            .response(queue: queue) { response in
                if let error = response.error, let failure = failure {
                    if let localizedDescription = response.error?.localizedDescription {
                        LogError(localizedDescription)
                    }
                    failure(response.request, error)
                    return
                }
                
                if let success = success {
                    success(response.request, response.data)
                }
        }
    }
    
    //MARK: UPLOAD
    
    public func upload(_ url: URL,
                       files: Array<ParamDictionary>?,
                       params: ParamDictionary,
                       encoding: ParamEncoding,
                       headers: [String: String],
                       success: ((URLRequest?, Any?) -> Void)? = nil,
                       failure: ((URLRequest?, Error) -> Void)? = nil) {
        manager.upload(multipartFormData: { formData in
            guard let files = files else {
                return
            }
            
            files.forEach { dictionary in
                dictionary.forEach {
                    let name = $0.key
                    let value = $0.value
                    if let data = value as? Data {
                        formData.append(data, withName: name)
                    } else if let path = value as? String {
                        formData.append(URL(fileURLWithPath: path), withName: name)
                    }
                }
            }
        },
                       to: url)
        { encodingResult in
            switch encodingResult {
            case .success(request: let request,
                          streamingFromDisk: _,
                          streamFileURL: _):
                if let success = success {
                    request.responseData(completionHandler: { response in
                        success(response.request, response.data)
                    })
                }
                
            case .failure(let error):
                if let failure = failure {
                    failure(nil, error)
                }
            }
        }
    }
}
