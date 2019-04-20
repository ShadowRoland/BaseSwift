//
//  SRBusinessModel.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class SRBusinessModel: SRModel {
    open var id: String?
    open var timestamp: Int?
    
    open var cellHeight: CGFloat = 0 //屏幕为纵向方向时的UITableCell高度，Portrait
    open var cellHeightLandscape: CGFloat = 0 //屏幕为横向方向时的UITableCell高度

    override public func mapping(map: Map) {
        super.mapping(map: map)

        id <- map[Param.Key.id]
        timestamp <- map[Param.Key.timestamp]
    }
    
    public static func == (lhs: SRBusinessModel, rhs: SRBusinessModel) -> Bool {
        if let id = lhs.id, id == rhs.id {
            return true
        }
        return false
    }
}
