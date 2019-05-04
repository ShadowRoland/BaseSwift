//
//  CountryCodeModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/17.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

class CountryCodeModel: BaseBusinessModel {
    var name: String?
    var code: String?
    var letter: String? = "#"
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        name <- map[Param.Key.name]
        code <- map[Param.Key.code]
        letter <- map[Param.Key.letter]
    }
}
