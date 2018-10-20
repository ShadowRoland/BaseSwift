//
//  SRHttpManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/23.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import Alamofire

public extension DataRequest {
    fileprivate struct AssociatedKeys {
        static var requestSender = "DataRequest.requestSender"
    }
    
    public var sender: String? {
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

public class SRHttpManager {
    public var tag = 0
    var queue: DispatchQueue!
    var retryCount = 0
    var manager: Alamofire.SessionManager!
    var serverHttpsCredential: URLCredential?
    var clientHttpsCredential: URLCredential?
    
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
        manager.delegate.sessionDidReceiveChallenge = {session, challenge in //认证服务器证书
            if challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust {
                print("server certificate")
                let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
                let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
                let remoteCertificateData
                    = CFBridgingRetain(SecCertificateCopyData(certificate))!
                let localCertificateData = Common.httpsCer(true)
                if (remoteCertificateData.isEqual(localCertificateData) == true) {
                    let credential = URLCredential(trust: serverTrust)
                    challenge.sender?.use(credential, for: challenge)
                    return (URLSession.AuthChallengeDisposition.useCredential,
                            URLCredential(trust: challenge.protectionSpace.serverTrust!))
                } else {
                    return (URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
                }
            } else {// 其它情况（不接受认证）
                print("reject")
                return (URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            }
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
                
                if let rsp = response.response, rsp.statusCode >= 400, let failure = failure {//状态码超过400仍然判断为失败
                    let error =
                        NSError(domain: NSCocoaErrorDomain,
                                code: rsp.statusCode,
                                userInfo: [NSLocalizedDescriptionKey : "Server booooom shakalaka!"])
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
                
                if let rsp = response.response, rsp.statusCode >= 400, let failure = failure {//状态码超过400仍然判断为失败
                    let error =
                        NSError(domain: NSCocoaErrorDomain,
                                code: rsp.statusCode,
                                userInfo: [NSLocalizedDescriptionKey : "Server booooom shakalaka!"])
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
                       params: ParamDictionary,
                       encoding: ParamEncoding,
                       headers: [String: String],
                       success: ((URLRequest?, Any?) -> Void)? = nil,
                       failure: ((URLRequest?, Error) -> Void)? = nil) {
        manager.upload(multipartFormData: { formData in
            guard let array = params[HttpKey.Upload.files] as? [ParamDictionary] else {
                return
            }
            
            array.forEach { dictionary in
                let name = NonNull.string(dictionary[HttpKey.Upload.name])
                if let data = dictionary[HttpKey.Upload.data] as? Data {
                    formData.append(data, withName: name)
                } else if let path = dictionary[HttpKey.Upload.path] as? String {
                    formData.append(URL(fileURLWithPath: path), withName: name)
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
