//
//  SRDownloadTaskModel.swift
//  SRFramework
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import ObjectMapper

open class SRDownloadTaskModel: SRBaseBusinessModel {
    public struct `Type`: RawRepresentable, Equatable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///rawValue: 0
        public static let `default` = Type(0)
        ///rawValue: 1
        public static let download = Type(1)
        ///rawValue: 2
        public static let upload = Type(2)
    }
    
    public struct Status: RawRepresentable, Equatable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///rawValue: 0
        public static let `default` = Status(0)
        ///rawValue: 1
        public static let waitOn = Status(1)
        ///rawValue: 2
        public static let didOn = Status(2)
        ///rawValue: 3
        public static let didSuspend = Status(3)
        ///rawValue: 4
        public static let didCancel = Status(4)
        ///rawValue: 5
        public static let didEnd = Status(5)
        ///rawValue: 6
        public static let didFail = Status(6)
    }
    
    public struct ProcessWway: RawRepresentable, Equatable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///rawValue: 0
        public static let `default` = ProcessWway(0)
        ///rawValue: 1
        public static let http = ProcessWway(1)
    }
    
    public struct Usage: RawRepresentable, Equatable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///rawValue: 0
        public static let `default` = Usage(0)
    }
    
    ///处理类型
    open var type: Type = .default
    ///任务状态
    open var status: Status = .default
    ///处理方式
    open var processWway: ProcessWway = .default
    ///任务用途
    open var usage: Usage = .default
    ///是否支持断点下载/续传续传
    open var breakpoint = false

    ///开始时间
    open var startTime = 0
    ///结束时间
    open var endTime = 0
    ///更新时间
    open var updateTime = 0

    open var name = ""
    open var Description = ""
    open var remark = ""
    open var errorMessage = ""
    
    ///可以存放http或第三方请求时的一些参数
    open var request = ""
    ///可以存放http或第三方回复后的一些参数
    open var response = ""

    open var url = ""
    ///本地文件名称
    open var fileName = ""
    ///本地文件相对与Documents的路径
    open var relativePath = ""

    open var completed = 0 as Int64
    open var total = 0 as Int64
    
    override public init() { super.init() }
    
    //MARK: - Mappable
    
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
        type <- map[Param.Key.type]
        status <- map[Param.Key.status]
        processWway <- map["processWway"]
        usage <- map["usage"]
        breakpoint <- map["breakpoint"]
        
        startTime <- map["startTime"]
        endTime <- map["endTime"]
        updateTime <- map["updateTime"]
        
        name <- map["name"]
        Description <- map[Param.Key.description]
        remark <- map["remark"]
        errorMessage <- map["errorMessage"]
        
        request <- map["request"]
        response <- map["response"]
            
        url <- map["url"]
        fileName <- map["fileName"]
        relativePath <- map["relativePath"]
        
        completed <- map["completed"]
        total <- map["total"]
    }
    
    //MARK: - SRDBModel
    
    open override func modelMapping(map: Map) -> SRDBModel {
        if let model = SRDownloadTaskModel(map: map) {
            return model
        } else {
            return SRDownloadTaskModel()
        }
    }
    
    private var _tableName = ""
    open override var tableName: String {
        get {
            return _tableName
        }
        set {
            _tableName = newValue
        }
    }
}
