//
//   UserModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

public class UserModel: BaseBusinessModel {
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
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        userId <- map[Param.Key.userId]
        userName <- map[Param.Key.userName]
        headPortrait <- map[Param.Key.headPortrait]
        nickname <- map[Param.Key.nickname]
        letter <- map[Param.Key.letter]
        userName <- map[Param.Key.userName]
        type <- map[Param.Key.type]
        status <- map[Param.Key.status]
        gender <- map[Param.Key.gender]
    }
}
