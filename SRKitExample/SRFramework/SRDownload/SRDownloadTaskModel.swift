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
    public struct `Type`: RawRepresentable {
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
    
    public struct Status: RawRepresentable {
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
    
    public struct Way: RawRepresentable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///rawValue: 0
        public static let `default` = Way(0)
        ///rawValue: 1
        public static let http = Way(1)
    }
    
    public struct Usage: RawRepresentable {
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
    
    open var type: Type = .default
    open var status: Status = .default
    open var way: Way = .default
    open var usage: Usage = .default

    open var startTime = 0
    open var endTime = 0
    open var updateTime = 0

    open var name = ""
    open var Description = ""
    open var remark = ""
    open var errorMessage = ""

    open var url = ""
    open var fileName = ""
    open var relativePath = ""

    open var completed = 0
    open var total = 0
    
    override public init() { super.init() }
    
    //MARK: - Mappable
    
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
        type <- map[Param.Key.type]
        status <- map[Param.Key.status]
        way <- map["way"]
        usage <- map["usage"]
        
        startTime <- map["startTime"]
        endTime <- map["endTime"]
        updateTime <- map["updateTime"]
        
        name <- map["name"]
        Description <- map[Param.Key.description]
        remark <- map["remark"]
        errorMessage <- map["errorMessage"]
        
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
