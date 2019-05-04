//
//  SRHttpServer.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/10.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import GCDWebServer

open class HttpServer: SRHttpServer {
    public class var shared: SRHttpServer {
        return sharedInstance
    }
    
    private static var sharedInstance = SRHttpServer()
    
    private override init() {
        super.init()
    }
    
    open override func handleRequest(_ method: String,
                                     request: GCDWebServerRequest) -> GCDWebServerResponse? {
        
        return super.handleRequest(method, request: request)
    }
}
