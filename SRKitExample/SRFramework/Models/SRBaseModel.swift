//
//  SRBaseModel.swift
//  SRFramework
//
//  Created by Gary on 2020/8/18.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import ObjectMapper

open class SRBaseModel: NSObject, Mappable {
    open var id: CLongLong = 0
    open var timestamp: Int?
    
    override public init() { }
    
    required public init?(map: Map) { }
    
    open func mapping(map: Map) {
        id <- map[Param.Key.id]
        timestamp <- map[Param.Key.timestamp]
    }
    
    public static func == (lhs: SRBaseModel, rhs: SRBaseModel) -> Bool {
        if lhs === rhs {
            return true
        } else if lhs.id == rhs.id {
            return true
        } else {
            return false
        }
    }
}

