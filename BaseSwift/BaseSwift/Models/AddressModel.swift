//
//  AddressModel.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/20.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

class AddressModel: BaseModel {
    var country: String? //国家
    var province: String? //省/直辖市
    var city: String? //市
    var region: String? //区/县
    var street: String? //街巷道
    var roomNo: String? //门牌号/楼层/房室
    var postcode: String? //邮编
    var areaCode: String? //区号
    var countryCode: Int? //手机的国家码
    var phone: String? //电话号码
    
    public override func mapping(map: Map) {
        super.mapping(map: map)

        country <- map[Param.Key.country]
        province <- map[Param.Key.province]
        city <- map[Param.Key.city]
        region <- map[Param.Key.region]
        street <- map[Param.Key.street]
        roomNo <- map[Param.Key.roomNo]
        postcode <- map[Param.Key.postcode]
        areaCode <- map[Param.Key.areaCode]
        countryCode <- map[Param.Key.countryCode]
        phone <- map[Param.Key.phone]
    }
}
