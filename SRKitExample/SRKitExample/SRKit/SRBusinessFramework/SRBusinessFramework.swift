//
//  SRBusinessFramework.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/2.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

let BF: SRBusinessFramework = SRBusinessFramework.shared

public struct SRManager: Equatable, Hashable, RawRepresentable {
    public typealias RawValue = UInt
    public var rawValue: UInt
    
    public init(_ rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int { return self.rawValue.hashValue }
}

public class SRBusinessFramework {
    private var modules: [UInt : SRBusinessObject] = [:]
    private var listeners: [SRBusinessObject] = []
    fileprivate var notiCenter = NotificationCenter()
    
    public class var shared: SRBusinessFramework {
        return sharedInstance
    }
    
    private static let sharedInstance = SRBusinessFramework()
    
    private init() { }
    
    static let notification = Notification.Name("SRBusinessFramework.notification")
    
    //MARK: - Tool Function
    
    //由业务模块id与相应模块的某个能力id组合成一个唯一的业务调用id
    //32位业务调用id = 模块id（高16位）＋ 能力id（低16位）
    //能力id最大不能超过(2^13 - 1) = 8191，即每个模块不应超过8191个业务，例如 不能有超过8191种的http请求
    
    public func businessId(_ module: SRBusinessModule, funcId: UInt) -> UInt {
        return (module.moduleId << 16) + funcId
    }
    
    //从32位业务调用id中分离模块id
    public func moduleId(_ businessId: UInt) -> UInt {
        return (businessId & 0xFFFF0000) >> 16
    }
    
    //从32位业务调用id中分离能力id
    public func funcId(_ businessId: UInt) -> UInt {
        return businessId & 0xFFFF
    }
    
    //MARK: - Module & Listener
    
    public func add(module: SRBusinessModule) {
        objc_sync_enter(modules)
        modules = modules.drop { $0.value.module == nil }.base
        modules[module.moduleId] = SRBusinessObject(module)
        objc_sync_exit(modules)
    }
    
    public func remove(module: SRBusinessModule) {
        objc_sync_enter(modules)
        modules = modules.drop { $0.value.module == nil }.base
        modules.removeValue(forKey: module.moduleId)
        objc_sync_exit(modules)
    }
    
    public func add(listener: SRBusinessListenerProtocol) {
        objc_sync_enter(listeners)
        listeners = Array<SRBusinessObject>(listeners.drop { $0.listener == nil })
        listeners.append(SRBusinessObject(listener))
        objc_sync_exit(listeners)
    }
    
    public func remove(listener: SRBusinessListenerProtocol) {
        objc_sync_enter(listeners)
        listeners = Array<SRBusinessObject>(listeners.drop { $0.listener == nil })
        if let index = listeners.firstIndex(where: {
            String(pointer: $0.listener as AnyObject) == String(pointer: listener as AnyObject)
        }) {
            listeners.remove(at: index)
            notiCenter.removeObserver(listener)
        }
        objc_sync_exit(listeners)
    }
    
    public func listener(pointer: String) -> SRBusinessListenerProtocol? {
        return listeners.first { String(pointer: $0.listener as AnyObject) == pointer }?.listener
    }
    
    public func listeners(of: AnyClass) -> [SRBusinessListenerProtocol] {
        return listeners.compactMap {
            if let object = $0.listener as? NSObject, object.isKind(of: of) {
                return $0.listener
            } else {
                return nil
            }
        }
    }
    
    //MARK: - Call & Broadcast
    
    @discardableResult
    public func callBusiness(_ businessId: UInt, params: Any? = nil) -> BFResult<Any> {
        let moduleId = self.moduleId(businessId)
        if let module = modules[moduleId]?.module {
            return module.callBusiness(funcId(businessId), params: params)
        }
        return .failure(BFError.callModuleFailed(.moduleNotExist(moduleId)))
    }
    
    public func notify(_ businessId: UInt, params: Any? = nil) {
        var dictionary: ParamDictionary = ["businessId" : businessId]
        dictionary["params"] = params
        notiCenter.post(name: SRBusinessFramework.notification, object: dictionary)
    }
}

fileprivate class SRBusinessObject {
    init(_ module: SRBusinessModule) {
        self.module = module
    }
    
    init(_ listener: SRBusinessListenerProtocol) {
        self.listener = listener
        BF.notiCenter.addObserver(self,
                                  selector: #selector(SRBusinessObject.onBusinessNotify(_:)),
                                  name: SRBusinessFramework.notification,
                                  object: nil)
    }
    
    deinit {
        BF.notiCenter.remove(self)
    }
    
    var module: SRBusinessModule?
    weak var listener: SRBusinessListenerProtocol?
    
    @objc func onBusinessNotify(_ notification: Notification) {
        if let dictionary = notification.object as? ParamDictionary,
            let businessId = dictionary["businessId"] as? UInt {
            listener?.onBusinessNotify(businessId, params: dictionary["params"])
        }
    }
}
