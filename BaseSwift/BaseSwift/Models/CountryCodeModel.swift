//
//  CountryCodeModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/17.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

class CountryCodeModel: BusinessModel {
    var name: String?
    var code: String?
    var letter: String? = "#"
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        name <- map[ParamKey.name]
        code <- map[ParamKey.code]
        letter <- map[ParamKey.letter]
    }
}
