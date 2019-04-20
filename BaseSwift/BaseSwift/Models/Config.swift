//
//  Config.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/7.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

public class Config: SRModel {
    var isProduction: Bool = true
    var apiBaseUrl: String = Configs.BaseServerURLProduction
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
    
    required public init?(map: ObjectMapper.Map) { super.init() }
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        apiBaseUrl <- map["apiBaseUrl"]
        httpsCer <- map["httpsCer"]
    }
    
    public class func reload() {
        sharedInstance = Config()
        guard Environment != .production,
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
                if let version = config[Param.Key.version] as? String,
                    let newestConfig = (Configs.configFilePath.fileJsonObject) as? ParamDictionary,
                    let newestVersion = newestConfig[Param.Key.version] as? String,
                    version != newestVersion {
                    UserStandard[USKey.config] = newestConfig
                    return newestConfig
                }
                return config
            }
            
            return Common.readJsonFile(Configs.configFilePath) as? ParamDictionary
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
