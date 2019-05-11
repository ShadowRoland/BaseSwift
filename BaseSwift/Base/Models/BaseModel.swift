//
//  BaseModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

open class BaseModel: NSObject, Mappable {
    override public init() { }
    
    required public init?(map: Map) { }
    
    open func mapping(map: Map) { }
}
