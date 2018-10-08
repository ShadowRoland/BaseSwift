//
//  ChannelModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/4.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

class ChannelModel: BusinessModel {
    var name: String? {
        var name = base
        if let localLang = localLang, NSLocale.preferredLanguages[0].hasPrefix(localLang) {
            name = localValue
        }
        return name
    }
    var cellWidth: CGFloat = 0
    
    private var base: String?
    private var langs: [ParamDictionary]?
    private var localLang: String? //只存在base和唯一一种本地化的语言
    private var localValue: String? //只存在base和唯一一种本地化的语言
    
    override init() {
        super.init()
    }
    
    init(id: String) {
        super.init()
        self.id = id
    }
    
    init?(JSON: [String: Any], context: MapContext? = nil) {
        super.init()
        if let id = JSON[ParamKey.id] as? String {
            self.id = id
        }
        
        guard let name = JSON[ParamKey.name] as? ParamDictionary else {
            return
        }
        
        if let base = name[ParamKey.base] as? String {
            self.base = base
        }
        langs = []
        name.forEach { (key, value) in
            if !Common.isEmptyString(key) && ParamKey.base != key {
                langs?.append([key : value])
                if let string = value as? String {
                    localLang = key
                    localValue = string
                }
            }
        }
    }
    
    required init?(map: Map) {
        fatalError("init(map:) has not been implemented")
    }
    
    func toJSON() -> [String : Any] {
        var dictionary = [:] as ParamDictionary
        if let id = id {
            dictionary[ParamKey.id] = id
        }
        
        var names = [:] as ParamDictionary
        if let langs = langs {
            langs.forEach { $0.forEach { names[$0.key] = $0.value } }
        }
        if let base = base {
            names[ParamKey.base] = base
        }
        dictionary[ParamKey.name] = names

        return dictionary
    }
}
