//
//  SRHttpTool.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/23.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import Alamofire

public class SRHttpTool {
    public var queue: DispatchQueue!
    public var retryCount = 0
    public var manager: Alamofire.SessionManager!
    
    public init(_ timeout: TimeInterval, retryCount: Int = 0, sessionDelegate: SessionDelegate) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeout
        manager = SessionManager(configuration: configuration, delegate: sessionDelegate)
        self.retryCount = retryCount
    }
    
    //MARK: GET
    
    public func get(_ url: URL,
                    params: ParamDictionary,
                    encoding: ParamEncoding,
                    headers: [String: String],
                    completion: (@escaping (DefaultDataResponse) -> Void)) -> DataRequest {
        return manager.request(url,
                               method: .get,
                               parameters: params,
                               encoding: encoding,
                               headers: headers)
            .response(queue: queue, completionHandler: completion)
    }
    
    //MARK: POST
    
    public func post(_ url: URL,
                     params: ParamDictionary,
                     encoding: ParamEncoding,
                     headers: [String: String],
                     completion: (@escaping (DefaultDataResponse) -> Void)) -> DataRequest {
        return manager.request(url,
                               method: .post,
                               parameters: params,
                               encoding: encoding,
                               headers: headers)
            .response(queue: queue, completionHandler: completion)
    }
    
    //MARK: UPLOAD
    
    public func upload(_ url: URL,
                       files: Array<ParamDictionary>?,
                       params: ParamDictionary,
                       encoding: ParamEncoding,
                       headers: [String: String],
                       completion: (@escaping (DataResponse<Data>) -> Void)) {
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
                request.responseData(completionHandler: completion)

            case .failure(let error):
                completion(.init(request: nil, response: nil, data: nil, result: .failure(error)))
            }
        }
    }
}
