//
//  ProfileDetailModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class ProfileDetailModel: ProfileModel {
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
    var sexualOrientation: IntForBool? //性取向
    var transvestism: IntForBool = .True //是否有异(女)装癖
    var tofuCurdTaste: Taste? //豆腐脑口味
    var loveGames: [Int]? //沉迷游戏
    var stayWebs: [Int]? //常驻网站
    var preferredTopics: [Int]? //偏爱话题
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        nativePlace <- map[ParamKey.nativePlace]
        faceValue <- map[ParamKey.faceValue]
        height <- map[ParamKey.height]
        weight <- map[ParamKey.weight]
        dickLength <- map[ParamKey.dickLength]
        fuckDuration <- map[ParamKey.fuckDuration]
        houseArea <- map[ParamKey.houseArea]
        bust <- map[ParamKey.bust]
        waistline <- map[ParamKey.waistline]
        hipline <- map[ParamKey.hipline]
        annualIncome <- map[ParamKey.annualIncome]
        sexualOrientation <- map[ParamKey.sexualOrientation]
        transvestism <- map[ParamKey.transvestism]
        tofuCurdTaste <- map[ParamKey.transvestism]
        loveGames <- map[ParamKey.loveGames]
        stayWebs <- map[ParamKey.stayWebs]
        preferredTopics <- map[ParamKey.preferredTopics]
    }
}
