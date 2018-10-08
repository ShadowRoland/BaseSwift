//
//  BusinessListenerProtocol.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/10.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import Foundation

public protocol BusinessListenerProtocol : class {
    func onBusinessNotify(_ notifyId: UInt, params: Any?)
}
