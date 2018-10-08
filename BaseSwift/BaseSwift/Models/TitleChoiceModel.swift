//
//  TitleChoiceModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/10.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class TitleChoiceModel: BaseModel {
    var id: String?
    var title: String?
    var isSelected = false
    
    override init() {
        super.init()
    }
    
    init?(JSON: [String: Any], context: MapContext? = nil) {
        super.init()
        JSON.forEach {
            id = $0.key
            title = $0.value as? String
        }
    }
    
    required public init?(map: Map) {
        fatalError("init(map:) has not been implemented")
    }
    
    func toJSON() -> [String : Any] {
        var dictionary = [:] as ParamDictionary
        if let id = id {
            dictionary[ParamKey.id] = id
        }
        if let title = title {
            dictionary[ParamKey.title] = title
        }
        return dictionary
    }
}

extension TitleChoiceModel {
    private static var titleChoiceDic: ParamDictionary? //所有的可选择项
    
    class func updatesChoicesDic() {
        titleChoiceDic =
            Common.readJsonFile(ResourceDirectory.appending(pathComponent: "json/debug/title_choices.json")) as? ParamDictionary
    }
    
    class func choices(_ key: String) -> [TitleChoiceModel]? {
        return models(params: titleChoiceDic?[key] as? [ParamDictionary])
    }
    
    class func params(models: [TitleChoiceModel]?) -> [ParamDictionary]? {
        return models?.compactMap { $0.toJSON() }
    }
    
    class func models(params: [ParamDictionary]?) -> [TitleChoiceModel]? {
        return params?.compactMap { TitleChoiceModel(JSON: $0) }
    }
    
    class func title(_ models: [TitleChoiceModel]?, id: String) -> String? {
        return models?.first { id == $0.id }?.title
    }
}
