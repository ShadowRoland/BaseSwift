//
//  Config.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/7.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

public class Config: BaseModel {
    var isProduction: Bool = true
    var apiBaseUrl: String = BaseServerURLProduction //服务器api的基础地质
    var httpsCer: String = "" //https证书
    
    public class var shared: Config {
        if sharedInstance == nil {
            Config.reload()
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: Config?
    
    private override init() {
        super.init()
    }
    
    required public init?(map: Map) { super.init() }
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        apiBaseUrl <- map["apiBaseUrl"]
        httpsCer <- map["httpsCer"]
    }
    
    public class func reload() {
        sharedInstance = Config()
        guard RunInEnvironment != .production,
            let local = Config.local,
            let current = local["current"] as? Int,
            current >= 0,
            let envs = local["envs"] as? [ParamDictionary],
            current < envs.count else {
                return
        }
        
        print(envs[current])
        sharedInstance = Config(JSON: envs[current])
        sharedInstance?.isProduction = false
    }
    
    public static var local: ParamDictionary? {
        get {
            if let config = UserStandard[USKey.config] as? ParamDictionary {
                if let version = config[ParamKey.version] as? String,
                    let newestConfig = Common.readJsonFile(ConfigFilePath) as? ParamDictionary,
                    let newestVersion = newestConfig[ParamKey.version] as? String,
                    version != newestVersion {
                    UserStandard[USKey.config] = newestConfig
                    return newestConfig
                }
                return config
            }
            
            return Common.readJsonFile(ConfigFilePath) as? ParamDictionary
        }
        
        set {
            guard let local = local else {
                 UserStandard[USKey.config] = nil
                return
            }
            UserStandard[USKey.config] = local
        }
    }
}
