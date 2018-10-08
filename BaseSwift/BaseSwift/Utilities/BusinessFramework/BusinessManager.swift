//
//  BusinessManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/2.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

open class BusinessManager: BusinessModule, BusinessListenerProtocol {
    public init(_ module: ManagerModule) {
        super.init()
        moduleId = module.rawValue
        BF.add(module: self)
        BF.add(self)
    }
    
    private override init() {
        super.init()
    }
    
    //MARK: BusinessListenerProtocol
    
    public func onBusinessNotify(_ notifyId: UInt, params: Any?) { }
}
