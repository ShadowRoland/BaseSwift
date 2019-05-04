//
//  BaseBusinessModel.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

open class BaseBusinessModel: BaseModel {
    open var id: String?
    open var timestamp: Int?
    
    open var cellHeight: CGFloat = 0 //屏幕为纵向方向时的UITableCell高度，Portrait
    open var cellHeightLandscape: CGFloat = 0 //屏幕为横向方向时的UITableCell高度

    open override func mapping(map: Map) {
        super.mapping(map: map)
        
        id <- map[Param.Key.id]
        timestamp <- map[Param.Key.timestamp]
    }
    
    public static func == (lhs: BaseBusinessModel, rhs: BaseBusinessModel) -> Bool {
        if lhs === rhs {
            return true
        } else if let id = lhs.id, id == rhs.id {
            return true
        } else {
            return false
        }
    }
}
