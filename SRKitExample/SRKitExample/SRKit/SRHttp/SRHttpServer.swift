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
    public init() {
        webServer = GCDWebServer()
        
        webServer.addDefaultHandler(forMethod: "GET",
                                    request: GCDWebServerURLEncodedFormRequest.self)
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
    }
    
    open var isRunning: Bool { return webServer.isRunning }
    var webServer: GCDWebServer!
    
    open var responseResult: GCDWebServerResponseResult? //为nil时按正常流程返回，否则强制设置网络返回的结果
    
    public struct GCDWebServerResponseResult: RawRepresentable {
        public typealias RawValue = BFResult<Any>
        public var rawValue: BFResult<Any>
        public var description: String?
        public var result: BFResult<Any> { return rawValue }
        
        public init(rawValue: BFResult<Any>) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: BFResult<Any>, description: String?) {
            self.init(rawValue: rawValue)
            self.description = description
        }
        
        public static let success =
            GCDWebServerResponseResult(.success(nil), description: "Allways success".srLocalized)
        public static var bfail =
            GCDWebServerResponseResult(.bfailure([HTTP.Key.Response.errorCode : -1,
                                                  HTTP.Key.Response.errorMessage : "[GCDWebServer]Business fail"]),
                                       description: "Allways business fail".srLocalized)
        public static var fail =
            GCDWebServerResponseResult(.failure(BFError.http(.other("Server boom shakalaka".srLocalized))),
                                       description: "Allways http fail".srLocalized)
    }
    
    open var responseTimeInterval: GCDWebServerResponseTimeInterval = .normal
    
    public struct GCDWebServerResponseTimeInterval: RawRepresentable {
        public typealias RawValue = TimeInterval
        public var rawValue: TimeInterval
        public var _description: String?
        public var description: String {
            var string = "\(interval)" + "second\(interval > 1 ? "s" : "")".srLocalized
            if !isEmptyString(_description) {
                string = _description!.srLocalized + " (\(string))"
            }
            return string
        }
        public var interval: TimeInterval { return rawValue }
        
        public init(rawValue: TimeInterval) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: TimeInterval, description: String?) {
            self.init(rawValue: rawValue)
            _description = description
        }
        
        public static let immediately = GCDWebServerResponseTimeInterval(0, description: "No delay")
        public static var speediness = GCDWebServerResponseTimeInterval(0.3, description: "Fast")
        public static var normal = GCDWebServerResponseTimeInterval(1, description: "Normal")
        public static var long = GCDWebServerResponseTimeInterval(10, description: "Long")
        public static var timeout = GCDWebServerResponseTimeInterval(10, description: "Timeout")
    }
    
    public struct Const {
        public static let htmlBaseFormat = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head><body>%@</body></html>"
        static let logfileTailLength = 10000
    }
    
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
    
    open func response(_ result: BFResult<Any>) -> GCDWebServerResponse? {
        if responseTimeInterval.interval > 0 {
            usleep(useconds_t(responseTimeInterval.interval * 1000000))
        }
        
        if let responseResult = responseResult {
            if responseResult.result.isSuccess {
                let r = result.isSuccess ? result : responseResult.result
                return GCDWebServerDataResponse(jsonObject: r.gcdWebServerResponse)
            } else if responseResult.result.isBFailure {
                let r = result.isBFailure ? result : responseResult.result
                return GCDWebServerDataResponse(jsonObject: r.gcdWebServerResponse)
            } else if responseResult.result.isFailure {
                let r = result.isFailure ? result : responseResult.result
                let message = r.error?.localizedDescription ?? "Invalid request"
                return
                    GCDWebServerErrorResponse.responseWithServerError(.httpStatusCode_InternalServerError,
                                                                      message)
            }
        }
        
        return GCDWebServerDataResponse(jsonObject: result.gcdWebServerResponse)
    }
    
    //MARK: - Request Handler
    
    open func handleRequest(_ method: String,
                            request: GCDWebServerRequest) -> GCDWebServerResponse? {
        if method == "GET" {
            let path = format(request.url.path)
            if isEmptyString(path) {
                var body = ""
                if 0 == request.query?.count {//默认是访问手机的日志文件列表
                    body = self.logFiles()
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
        return  response(.failure(BFError.http(.other(nil))))
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
        var contents: [Any]?
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
        var sortedContents: [Any]? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory.appending(pathComponent: obj1 as? String)
            var properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory.appending(pathComponent: obj2 as? String)
            var properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
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
        var contents: [Any]?
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: logsDirectory)
        } catch {
            return body.appendingFormat("<h2>获取日志文件列表失败</h2><p>%@</p>", error.localizedDescription)
        }
        
        if index >= (contents?.count)! {
            return body.appending("<h2>无法获取日志文件，请刷新日志文件列表</h2>")
        }
        
        var sortedContents: [Any]? = contents?.sorted(by: { (obj1, obj2) -> Bool in
            let path1 = logsDirectory.appending(pathComponent: obj1 as? String)
            var properties1 = try! FileManager.default.attributesOfItem(atPath: path1)
            let date1 = properties1[FileAttributeKey.modificationDate] as! Date
            
            let path2 = logsDirectory.appending(pathComponent: obj2 as? String)
            var properties2 = try! FileManager.default.attributesOfItem(atPath: path2)
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
        let dir = ResourceDirectory.appending(pathComponent: "html")
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

extension BFResult where Value : Any {
    public var gcdWebServerResponse: [AnyHashable : Any] {
        switch self {
        case .success(let value):
            var dictionary: ParamDictionary = [Param.Key.timestamp : CLong(Date().timeIntervalSince1970)]
            dictionary[HTTP.Key.Response.errorCode] = 0
            dictionary[HTTP.Key.Response.errorMessage] = "The request completed successfully".srLocalized
            dictionary[HTTP.Key.Response.data] = NonNull.dictionary(value)
            return dictionary
            
        case .bfailure(let value):
            var dictionary: ParamDictionary = [Param.Key.timestamp : CLong(Date().timeIntervalSince1970)]
            dictionary[HTTP.Key.Response.errorCode] = 1
            dictionary[HTTP.Key.Response.errorMessage] = "The request failed with business".srLocalized
            if let errorCode = value as? Int {
                dictionary[HTTP.Key.Response.errorCode] = errorCode
            } else if let errorMessage = value as? String {
                dictionary[HTTP.Key.Response.errorMessage] = errorMessage
            } else if let respondDictionary = value as? ParamDictionary {
                dictionary += respondDictionary
            }
            return dictionary
            
        default:
            break
        }
        return [:] as [AnyHashable : Any]
    }
}

extension GCDWebServerErrorResponse {
    public class func responseWithServerError(_ errorCode: GCDWebServerServerErrorHTTPStatusCode,
                                              _ message: String) -> GCDWebServerErrorResponse {
        let title = String(format:"HTTP Error %i", errorCode.rawValue)
        let html = String.init(format: "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>%@</title></head><body><h1>%@</h1><h3>%@</h3></body></html>", title, message, "")
        let response = GCDWebServerErrorResponse(html: html)
        response?.statusCode = errorCode.rawValue
        return response!
    }
}
