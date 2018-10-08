//
//  SinaNewsModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/2.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

class SinaNewsModel: BusinessModel {
    enum MediaType: Int {
        case normal
        case video
    }
    
    var title: String?
    var link: String?
    var mediaType: MediaType = .normal
    var image: String?
    var date: String?
    var source: String?
    var comment: Int?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        id <- map[ParamKey.docID]
        title <- map[ParamKey.title]
        link <- map[ParamKey.link]
        mediaType <- map[ParamKey.mediaTypes]
        image <- map[ParamKey.img]
        date <- map[ParamKey.date]
        source <- map[ParamKey.source]
        comment <- map[ParamKey.comment]
    }
}
