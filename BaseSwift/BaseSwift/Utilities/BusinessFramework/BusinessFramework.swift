//
//  BusinessFramework.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/2.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

public struct BusinessNotification {
    static let name = Notification.Name("name")
    static let businessId = "id"
    static let params = "params"
}

fileprivate class BusinessObject {
    init(_ module: BusinessModule) {
        self.module = module
    }
    
    init(_ listener: BusinessListenerProtocol) {
        self.listener = listener
        BF.notiCenter.addObserver(self,
                                  selector: #selector(BusinessObject.onBusinessNotify(_:)),
                                  name: BusinessNotification.name,
                                  object: nil)
    }
    
    var module: BusinessModule?
    weak var listener: BusinessListenerProtocol?
    
    @objc func onBusinessNotify(_ notification: Notification) {
        if let dictionary = notification.object as? ParamDictionary,
            let businessId = dictionary[BusinessNotification.businessId] as? UInt {
            listener?.onBusinessNotify(businessId, params: dictionary[BusinessNotification.params])
        }
    }
}

public class BusinessFramework {
    private var modules: [UInt : BusinessObject] = [:]
    private var listeners: [BusinessObject] = []
    fileprivate var notiCenter = NotificationCenter()
    
    public class var shared: BusinessFramework {
        return sharedInstance
    }
    
    private static let sharedInstance = BusinessFramework()
    
    private init() { }
    
    //MARK: - Tool Function
    
    //由业务模块id与相应模块的某个能力id组合成一个唯一的业务调用id
    //32位业务调用id = 模块id（高16位）＋ 能力id（低16位）
    //y最大不能超过(2^13 - 1) = 8191，即每个模块不应超过8191个业务，如不能有超过8191种的http请求
    
    public func businessId(_ moduleId: Manager.Module, _ funcId: UInt) -> UInt {
        return (moduleId.rawValue << 16) + funcId
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
    
    public func add(module: BusinessModule) {
        objc_sync_enter(modules)
        modules = modules.drop { $0.value.module == nil }.base
        modules[module.moduleId] = BusinessObject(module)
        objc_sync_exit(modules)
    }
    
    public func remove(module: BusinessModule) {
        objc_sync_enter(modules)
        modules = modules.drop { $0.value.module == nil }.base
        modules.removeValue(forKey: module.moduleId)
        objc_sync_exit(modules)
    }
    
    public func add(_ listener: BusinessListenerProtocol) {
        objc_sync_enter(listeners)
        listeners = Array<BusinessObject>(listeners.drop { $0.listener == nil })
        listeners.append(BusinessObject(listener))
        objc_sync_exit(listeners)
    }
    
    public func remove(_ listener: BusinessListenerProtocol) {
        objc_sync_enter(listeners)
        listeners = Array<BusinessObject>(listeners.drop { $0.listener == nil })
        if let index = listeners.firstIndex(where: {
            String(pointer: $0.listener as AnyObject) == String(pointer: listener as AnyObject)
        }) {
            listeners.remove(at: index)
            notiCenter.removeObserver(listener)
        }
        objc_sync_exit(listeners)
    }
    
    public func listener(_ pointer: String) -> BusinessListenerProtocol? {
        return listeners.first { String(pointer: $0.listener as AnyObject) == pointer }?.listener
    }
    
    public func subListeners(of: AnyClass) -> [BusinessListenerProtocol] {
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
        var dictionary: ParamDictionary = [BusinessNotification.businessId : businessId]
        dictionary[BusinessNotification.params] = params
        notiCenter.post(name: BusinessNotification.name, object: dictionary)
    }
}
