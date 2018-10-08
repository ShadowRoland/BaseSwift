//
//  MessageModel.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class MessageModel: BusinessModel { 
    enum BlogType: Int {
        case text = 0,
        image,
        video,
        share
    }
   
    //MARK: Message
    var userId: String?
    var userName: String?
    var headPortrait: String?
    var text: String?
    var badge: Int?
    
    //MARK: Blog
    var blogType: BlogType = .text
    var images: [String]?
    var videos: [String]?
    var thumbnail: String?
    var shareText: String?
    var shareUrl: String?
    var like: Int?
    var liked: Bool?
    var comment: Int?
    
    var singleImageWidth: CGFloat = 0
    var singleImageHeight: CGFloat = 0
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        userId <- map[ParamKey.userId]
        userName <- map[ParamKey.userName]
        headPortrait <- map[ParamKey.headPortrait]
        text <- map[ParamKey.text]
        badge <- map[ParamKey.badge]
        blogType <- map[ParamKey.blogType]
        images <- map[ParamKey.images]
        videos <- map[ParamKey.videos]
        thumbnail <- map[ParamKey.thumbnail]
        shareText <- map[ParamKey.share + "." + ParamKey.text]
        shareUrl <- map[ParamKey.share + "." + ParamKey.url]
        like <- map[ParamKey.like]
        liked <- map[ParamKey.liked]
        comment <- map[ParamKey.comment]
    }
}
