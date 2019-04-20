//
//  SinaNewsModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/2.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

class SinaNewsModel: SRBusinessModel {
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
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        id <- map[Param.Key.docID]
        title <- map[Param.Key.title]
        link <- map[Param.Key.link]
        mediaType <- map[Param.Key.mediaTypes]
        image <- map[Param.Key.img]
        date <- map[Param.Key.date]
        source <- map[Param.Key.source]
        comment <- map[Param.Key.comment]
    }
}
