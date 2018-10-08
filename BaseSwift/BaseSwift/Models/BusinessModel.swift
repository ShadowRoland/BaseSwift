//
//  BusinessModel.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class BusinessModel: BaseModel {
    var id: String?
    var timestamp: Int?
    
    var cellHeight: CGFloat = 0 //屏幕为纵向方向时的UITableCell高度，Portrait
    var cellHeightLandscape: CGFloat = 0 //屏幕为横向方向时的UITableCell高度

    override public func mapping(map: Map) {
        super.mapping(map: map)

        id <- map[ParamKey.id]
        timestamp <- map[ParamKey.timestamp]
    }
    
    static public func == (lhs: BusinessModel, rhs: BusinessModel) -> Bool {
        if let id = lhs.id, id == rhs.id {
            return true
        }
        return false
    }
}
