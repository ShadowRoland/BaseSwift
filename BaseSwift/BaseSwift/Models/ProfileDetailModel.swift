//
//  ProfileDetailModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

class ProfileDetailModel: ProfileModel {
    enum Taste: EnumInt {
        case sweet = 0
        case salty = 1
        case spicy = 2
        case durian = 3
    }

    var nativePlace: AddressModel? //籍贯
    var faceValue: Double? //颜值
    var height: Double? //身高
    var weight: Double? //体重
    var dickLength: Double? //XX长度
    var fuckDuration: Double? //OO持久时间
    var houseArea: Double? //名下房子面积
    var bust: Double? //胸围
    var waistline: Double? //腰围
    var hipline: Double? //胸围
    var annualIncome: Double? //年收入
    var sexualOrientation: Int? //性取向
    var transvestism: Int = 0 //是否有异(女)装癖
    var tofuCurdTaste: Taste? //豆腐脑口味
    var loveGames: [Int]? //沉迷游戏
    var stayWebs: [Int]? //常驻网站
    var preferredTopics: [Int]? //偏爱话题
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        nativePlace <- map[Param.Key.nativePlace]
        faceValue <- map[Param.Key.faceValue]
        height <- map[Param.Key.height]
        weight <- map[Param.Key.weight]
        dickLength <- map[Param.Key.dickLength]
        fuckDuration <- map[Param.Key.fuckDuration]
        houseArea <- map[Param.Key.houseArea]
        bust <- map[Param.Key.bust]
        waistline <- map[Param.Key.waistline]
        hipline <- map[Param.Key.hipline]
        annualIncome <- map[Param.Key.annualIncome]
        sexualOrientation <- map[Param.Key.sexualOrientation]
        transvestism <- map[Param.Key.transvestism]
        tofuCurdTaste <- map[Param.Key.transvestism]
        loveGames <- map[Param.Key.loveGames]
        stayWebs <- map[Param.Key.stayWebs]
        preferredTopics <- map[Param.Key.preferredTopics]
    }
}
