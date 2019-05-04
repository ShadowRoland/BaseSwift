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
                return
        }
        
        print(envs[current])
        sharedInstance = Env(JSON: envs[current])
        sharedInstance?.isProduction = false
    }
    
    public static var local: ParamDictionary? {
        get {
            if let env = UserStandard[USKey.env] as? ParamDictionary {
                if let version = env[Param.Key.version] as? String,
                    let newestEnv = (Config.envFilePath.fileJsonObject) as? ParamDictionary,
                    let newestVersion = newestEnv[Param.Key.version] as? String,
                    version != newestVersion {
                    UserStandard[USKey.env] = newestEnv
                    return newestEnv
                }
                return env
            }
            
            return Config.envFilePath.fileJsonObject as? ParamDictionary
        }
        
        set {
            guard let local = local else {
                 UserStandard[USKey.env] = nil
                return
            }
            UserStandard[USKey.env] = local
        }
    }
}
