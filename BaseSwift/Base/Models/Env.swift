//
//  Env.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/7.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

public class Env: BaseModel {
    var isProduction: Bool = true
    var apiBaseUrl: String = Config.BaseServerURLProduction
    var httpsCer: String = "" //https证书
    
    public class var shared: Env {
        if sharedInstance == nil {
            Env.reload()
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: Env?
    
    private override init() {
        super.init()
        #if PRODUCTION
        Environment = .production
        #elseif TEST
        Environment = .test
        #else
        Environment = .develop
        #endif
    }
    
    required public init?(map: ObjectMapper.Map) { super.init() }
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        apiBaseUrl <- map["apiBaseUrl"]
        httpsCer <- map["httpsCer"]
    }
    
    public class func reload() {
        sharedInstance = Env()
        guard Environment != .production,
            let local = Env.local,
            let current = local["current"] as? Int,
            current >= 0,
            let envs = local["envs"] as? [ParamDictionary],
            current < envs.count else {
                BaseHttpURL = sharedInstance!.apiBaseUrl
                return
        }
        
        print(envs[current])
        sharedInstance = Env(JSON: envs[current])
        sharedInstance?.isProduction = false
        BaseHttpURL = sharedInstance!.apiBaseUrl
    }
    
    public static var local: ParamDictionary? {
        get {
            if let env = UserStandard[UDKey.env] as? ParamDictionary {
                if let version = env[Param.Key.version] as? String,
                    let newestEnv = (Config.envFilePath.fileJsonObject) as? ParamDictionary,
                    let newestVersion = newestEnv[Param.Key.version] as? String,
                    version != newestVersion {
                    UserStandard[UDKey.env] = newestEnv
                    return newestEnv
                }
                return env
            }
            
            return Config.envFilePath.fileJsonObject as? ParamDictionary
        }
        
        set {
            guard let local = local else {
                UserStandard[UDKey.env] = nil
                return
            }
            UserStandard[UDKey.env] = local
        }
    }
}
