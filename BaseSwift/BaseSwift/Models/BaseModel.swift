//
//  BaseModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class BaseModel: NSObject, Mappable {
    override init() { }
    
    required public init?(map: Map) { }
    
    public func mapping(map: Map) { }
    
}
