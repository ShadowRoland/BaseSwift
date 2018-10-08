//
//   UserModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class UserModel: BusinessModel {
    enum UserStatus: EnumInt {
        case normal = 0
        case vip = 1
        case closed = 9999
    }
    
    enum SNSType: EnumInt {
        case single = 0
        case officialAccount = 1
    }
    
    enum Gender: EnumInt {
        case male = 0
        case female = 1
    }
    
    var userId: String?
    var userName: String?
    var headPortrait: String?
    var nickname: String?
    var remarkName: String?
    var letter: String? = "#"
    var type: SNSType = .single
    var status: UserStatus = .normal
    var gender: Gender? //性别，0为男性，非0为女性，nil为未知
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        userId <- map[ParamKey.userId]
        userName <- map[ParamKey.userName]
        headPortrait <- map[ParamKey.headPortrait]
        nickname <- map[ParamKey.nickname]
        letter <- map[ParamKey.letter]
        userName <- map[ParamKey.userName]
        type <- map[ParamKey.type]
        status <- map[ParamKey.status]
        gender <- map[ParamKey.gender]
    }
}
