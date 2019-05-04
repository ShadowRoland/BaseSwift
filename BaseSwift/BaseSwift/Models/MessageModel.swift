//
//  MessageModel.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

public class MessageModel: BaseBusinessModel {
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
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        userId <- map[Param.Key.userId]
        userName <- map[Param.Key.userName]
        headPortrait <- map[Param.Key.headPortrait]
        text <- map[Param.Key.text]
        badge <- map[Param.Key.badge]
        blogType <- map[Param.Key.blogType]
        images <- map[Param.Key.images]
        videos <- map[Param.Key.videos]
        thumbnail <- map[Param.Key.thumbnail]
        shareText <- map[Param.Key.share + "." + Param.Key.text]
        shareUrl <- map[Param.Key.share + "." + Param.Key.url]
        like <- map[Param.Key.like]
        liked <- map[Param.Key.liked]
        comment <- map[Param.Key.comment]
    }
}
