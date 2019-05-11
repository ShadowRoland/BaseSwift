//
//  SRBusinessManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/2.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

public class SRBusinessManager: SRBusinessModule, SRBusinessListenerProtocol {
    public init(_ manager: SRManager) {
        super.init()
        moduleId = manager.rawValue
        BF.add(module: self)
        BF.add(listener: self)
    }
    
    private override init() {
        super.init()
    }
    
    //MARK: SRBusinessListenerProtocol
    
    public func onBusinessNotify(_ notifyId: UInt, params: Any?) { }
}
