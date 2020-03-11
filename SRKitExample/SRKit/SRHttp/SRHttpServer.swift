//
//  SRHttpServer.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/10.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import GCDWebServer
import SwiftyJSON

open class SRHttpServer {
    public init() { }
    
    open var isRunning: Bool { return webServer.isRunning }
    
    open func start() {
        if !webServer.isRunning {
            LogInfo("GCDWebServer is starting ...")
            if webServer.start(withPort: 9999, bonjourName: "") {
                LogInfo("GCDWebServer is started")
            } else {
                LogInfo("GCDWebServer failed to start")
            }
        } else {
            LogInfo("GCDWebServer is started")
        }
    }
    
    open func stop() {
        if webServer.isRunning {
            webServer.stop()
        }
        LogInfo("GCDWebServer is stopped")
    }
    
    lazy var webServer: GCDWebServer = {
        let webServer = GCDWebServer()
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerURLEncodedFormRequest.self)
        { (request) -> GCDWebServerResponse? in
            if let query = request.query {
                print("get query: \n\(String(jsonObject: query))")
            }
            
            return self.handleRequest("GET", request: request)
        }
        webServer.addDefaultHandler(forMethod: "POST",
                                    request: GCDWebServerURLEncodedFormRequest.self)
        { (request) -> GCDWebServerResponse? in
            if let jsonRequest = request as? GCDWebServerURLEncodedFormRequest,
                let json = try? JSON(data: jsonRequest.data) {
                print("post data: \n\(json.rawString() ?? "")")
            }
            
            return self.handleRequest("POST", request: request)
        }
        return webServer
    }()
    
    open var responseResult: GCDWebServerResponseResult? //为nil时按正常流程返回，否则强制设置网络返回的结果
    
    public struct GCDWebServerResponseResult: RawRepresentable {
        public typealias RawValue = SRHTTP.Result<Any>
        public var rawValue: SRHTTP.Result<Any>
        public var description: String?
        public var result: SRHTTP.Result<Any> { return rawValue }
        
        public init(rawValue: SRHTTP.Result<Any>) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: SRHTTP.Result<Any>, description: String?) {
            self.init(rawValue: rawValue)
            self.description = description
        }
        
        public static let success =
            GCDWebServerResponseResult(.success(nil), description: "[SRHttpServer]Allways success".srLocalized)
        public static var failure =
            GCDWebServerResponseResult(.failure(.business([SRHTTP.Key.Response.code : -1,
                                                           SRHTTP.Key.Response.message : "[SRHttpServer]Business fail".srLocalized])),
                                       description: "[SRHttpServer]Allways business fail".srLocalized)
        public static let error =
            GCDWebServerResponseResult(.failure(.http(.init("Server boom shakalaka".srLocalized, code: GCDWebServerServerErrorHTTPStatusCode.httpStatusCode_InternalServerError.rawValue))),
                                       description: "[SRHttpServer]Allways http fail".srLocalized)
    }
    
    open var responseSpeed: GCDWebServerResponseSpeed = .normal
    
    public struct GCDWebServerResponseSpeed: RawRepresentable {
        public typealias RawValue = TimeInterval
        public var rawValue: TimeInterval
        private var _description: String?
        public var description: String {
            var string = "\(timeInterval)" + "[SRHttpServer]second".srLocalized + "\(timeInterval > 1 ? "[SRHttpServer]s".srLocalized : "")"
            if !isEmptyString(_description) {
                string = _description! + " (\(string))"
            }
            return string
        }
        public var timeInterval: TimeInterval { return rawValue }
        
        public init(rawValue: TimeInterval) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: TimeInterval, description: String?) {
            self.init(rawValue: rawValue)
            _description = description
        }
        
        public static let immediately = GCDWebServerResponseSpeed(0, description: "[SRHttpServer]No delay".srLocalized)
        public static var rapid = GCDWebServerResponseSpeed(0.3, description: "[SRHttpServer]Fast".srLocalized)
        public static var normal = GCDWebServerResponseSpeed(1, description: "[SRHttpServer]Normal".srLocalized)
        public static var long = GCDWebServerResponseSpeed(10, description: "[SRHttpServer]Long".srLocalized)
        public static var timeout = GCDWebServerResponseSpeed(10, description: "[SRHttpServer]Timeout".srLocalized)
    }
    
    public struct Const {
        public static let htmlBaseFormat = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head><body>%@</body></html>"
        static let logfileTailLength = 10000
    }
    
    open func response(_ result: BFResult<Any>) -> GCDWebServerResponse? {
        if responseSpeed.timeInterval > 0 {
            usleep(useconds_t(responseSpeed.timeInterval * 1000000))
        }
        
        if let responseResult = responseResult {
            switch responseResult.result {
            case .success:
                return GCDWebServerDataResponse(jsonObject: result.isSuccess ? jsonObjectWithBFResult(result) : jsonObjectWithHTTPResult(responseResult.result))
                
            case .failure(let failure):
                switch failure {
                case .business:
                    return GCDWebServerDataResponse(jsonObject: !result.isSuccess ? jsonObjectWithBFResult(result) : jsonObjectWithHTTPResult(responseResult.result))
                    
                case .http:
                    let statusCode = GCDWebServerServerErrorHTTPStatusCode.httpStatusCode_InternalServerError.rawValue
                    let title = "HTTP Error \(statusCode)/"
                    let message = "Server booooooooooom!"
                    let response = GCDWebServerErrorResponse(html: "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>\(title)/</title></head><body><h1>\(message)/</h1><h3></h3></body></html>")
                    response?.statusCode = statusCode
                    return response!
                }
            }
        }
        
        return GCDWebServerDataResponse(jsonObject: jsonObjectWithBFResult(result))
    }
    
    open func jsonObjectWithBFResult(_ result: BFResult<Any>) -> ParamDictionary {
        var dictionary: ParamDictionary = [Param.Key.timestamp : CLong(Date().timeIntervalSince1970)]
        switch result {
        case .success(let value):
            dictionary[SRHTTP.Key.Response.code] = SRHTTP.Code.Response.success
            dictionary[SRHTTP.Key.Response.message] = "[SRHttpServer]The request completed successfully".srLocalized
            if let code = value as? Int {
                dictionary[SRHTTP.Key.Response.code] = code
            } else if let message = value as? String {
                dictionary[SRHTTP.Key.Response.message] = message
            } else if let respondDictionary = value as? ParamDictionary {
                if let code = respondDictionary[SRHTTP.Key.Response.code] as? Int {
                    dictionary[SRHTTP.Key.Response.code] = code
                }
                if let message = respondDictionary[SRHTTP.Key.Response.message] as? String {
                    dictionary[SRHTTP.Key.Response.message] = message
                }
            }
            dictionary[SRHTTP.Key.Response.data] = NonNull.dictionary(value)
            
        case .failure(let error):
            dictionary[SRHTTP.Key.Response.code] = error.errorCode
            if let errorDescription = error.errorDescription {
                dictionary[SRHTTP.Key.Response.message] = errorDescription
            } else {
                dictionary[SRHTTP.Key.Response.message] = "[SRHttpServer]The request failed with business".srLocalized
            }
        }
        
        return dictionary
    }
    
    open func jsonObjectWithHTTPResult(_ result: SRHTTP.Result<Any>) -> ParamDictionary {
        var dictionary: ParamDictionary = [Param.Key.timestamp : CLong(Date().timeIntervalSince1970)]
        dictionary[SRHTTP.Key.Response.code] = SRHTTP.Code.Response.success
        switch result {
        case .success(let value):
            dictionary[SRHTTP.Key.Response.message] = "[SRHttpServer]The request completed successfully".srLocalized
            if let code = value as? Int {
                dictionary[SRHTTP.Key.Response.code] = code
            } else if let message = value as? String {
                dictionary[SRHTTP.Key.Response.message] = message
            } else if let respondDictionary = value as? ParamDictionary {
                dictionary += respondDictionary
            }
            dictionary[SRHTTP.Key.Response.data] = NonNull.dictionary(value)
            
        case .failure(let failure):
            switch failure {
            case .business(let value):
                dictionary[SRHTTP.Key.Response.code] = SRHTTP.Code.Response.success + 1
                dictionary[SRHTTP.Key.Response.message] = "[SRHttpServer]The request failed with business".srLocalized
                if let errorCode = value as? Int {
                    dictionary[SRHTTP.Key.Response.code] = errorCode
                } else if let errorMessage = value as? String {
                    dictionary[SRHTTP.Key.Response.message] = errorMessage
                } else if let respondDictionary = value as? ParamDictionary {
                    dictionary += respondDictionary
                }
                dictionary[SRHTTP.Key.Response.data] = NonNull.dictionary(value)
                
            default: break
            }
            
        }
        return dictionary
    }
    
    //MARK: - Request Handler
    
    open func handleRequest(_ method: String,
                            request: GCDWebServerRequest) -> GCDWebServerResponse? {
        if method == "GET" {
            let path = format(request.url.path)
            if isEmptyString(path) {
                var body = ""
                if 0 == request.query?.count {//默认是访问手机的日志文件列表
                    body = logFiles()
                } else {
                    if let index = request.query!["index"] {
                        if let length = request.query!["length"] {
                            body = logFileContents((index as AnyObject).intValue,
                                                   length: (length as AnyObject).intValue)
                        } else {
                            body = logFileContents((index as AnyObject).intValue)
                        }
                        return GCDWebServerDataResponse(text: body)
                    }
                }
                return GCDWebServerDataResponse(html: String(format: Const.htmlBaseFormat, body))
            } else if path.hasSuffix(".html") {
                return getLocalHtml(request, path: path)
            }
        }
        return nil
    }
    
    open func format(_ path: String?) -> String {
        var pathStr = NSString(string: path ?? "")
        pathStr = pathStr.replacingOccurrences(of: "/",
                                               with: "",
                                               options: .caseInsensitive,
                                               range: NSMakeRange(0, 1)) as NSString
        return String(pathStr)
    }
    
    //MARK: Log Reader
    
    func logFiles() -> String {
        LogInfo("接收请求：获取所有的日志文件列表")
        
        var body = ""
        var contents: AnyArray?
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: logsDirectory)
        } catch {
            return body.appendingFormat("<h2>获取日志文件列表失败</h2><p>%@</p>", error.localizedDescription)
        }
        
        if contents!.isEmpty {
            return body.appending("<h2>日志文件列表为空</h2>")
        }
        
        body.append("<h2>日志文件列表</h2>")
        body.append("<ul>")
        let sortedContents: AnyArray? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory.appending(pathComponent: obj1 as? String)
            let properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory.appending(pathComponent: obj2 as? String)
            let properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
            let date2 = properties2[FileAttributeKey.modificationDate] as! Date
            
            return date2.compare(date1) == .orderedAscending
        })
        let list = (0 ..< (sortedContents?.count)!).map {
            String(format: "<li><a href=\"javascript:window.location.href=window.location.href + '?index=%d&length=%d'\">%@</a> <a href=\"javascript:window.location.href=window.location.href + '?index=%d'\">[全部]</a></li>",
                   $0,
                   Const.logfileTailLength,
                   sortedContents?[$0] as! CVarArg, $0)
        }
        body.append(list.joined(separator: ""))
        body.append("</ul>")
        return body
    }
    
    func logFileContents(_ index: Int, length: Int = 0) -> String {
        if length > 0 {
            LogInfo(String(format: "接收请求：获取顺序为%d的日志文件内容最后%d字", index, length))
        } else {
            LogInfo(String(format: "接收请求：获取顺序为%d的日志全部文件内容", index))
        }
        
        var body = ""
        var contents: AnyArray?
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: logsDirectory)
        } catch {
            return body.appendingFormat("<h2>获取日志文件列表失败</h2><p>%@</p>", error.localizedDescription)
        }
        
        if index >= (contents?.count)! {
            return body.appending("<h2>无法获取日志文件，请刷新日志文件列表</h2>")
        }
        
        let sortedContents: AnyArray? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory.appending(pathComponent: obj1 as? String)
            let properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory.appending(pathComponent: obj2 as? String)
            let properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
            let date2 = properties2[FileAttributeKey.modificationDate] as! Date
            
            return date2.compare(date1) == .orderedAscending
        })
        
        let fileName = sortedContents?[index] as? String
        let filePath = logsDirectory.appending(pathComponent: fileName!)
        body = body.appendingFormat("<h2>%@</h2>", fileName!)
        var fileContents: String?
        do {
            try fileContents = String(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            return body.appendingFormat("<p>无法读取文件内容，错误原因: <br>%@</p>",
                                        error.localizedDescription)
        }
        
        let fileLength = fileContents!.count
        if length > 0 && length < fileLength {
            return fileContents!.substring(from: max(fileLength - length, 0))
        }
        return fileContents!
    }
    
    var logsDirectory: String { return SRLog.shared.directory }
    
    func getLocalHtml(_ request: GCDWebServerRequest, path: String) -> GCDWebServerDataResponse? {
        let dir = C.resourceDirectory.appending(pathComponent: "html")
        let filePath = dir.appending(pathComponent: path)
        var fileContents: String?
        do {
            try fileContents = String(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            let description = String(format: "<p>无法读取文件内容，错误原因: <br>%@</p>",
                                     error.localizedDescription)
            return GCDWebServerDataResponse(html: String(format: Const.htmlBaseFormat, description))
        }
        
        return GCDWebServerDataResponse(html: fileContents!)
    }
}
