//
//  SRBusinessModule.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/2.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

open class SRBusinessModule {
    open var moduleId: UInt = 0
    
    @discardableResult
    open func callBusiness(_ funcId: UInt, params: Any?) -> BFResult<Any> {
        return .success(nil)
    }
}
