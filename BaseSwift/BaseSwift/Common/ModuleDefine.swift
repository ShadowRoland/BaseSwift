//
//  ModuleDefine.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

let BF: BusinessFramework = BusinessFramework.shared

public enum ManagerModule: UInt {
    case none = 0,
    profile,
    http,
    im
}

public enum ProfileManagerCapability: UInt {
    case none = 0,
    getProfile,
    updateProfile,
    getSingleContacts,
    getOfficialAccountsContacts
}

public struct Manager {
    public enum Module: UInt {
        case none = 0,
        profile,
        http,
        im
    }
    
    public struct Profile {
        public enum Capability: UInt {
            case none = 0,
            login,
            logout,
            updateProfile,
            getSingleContacts,
            getOfficialAccountsContacts
        }
        
        static public func funcId(_ capability: Capability) -> UInt {
            return capability.rawValue
        }
    }
    
    public struct IM {
        public enum Capability: UInt {
            case none = 0,
            login
        }
        
        static public func funcId(_ capability: Capability) -> UInt {
            return capability.rawValue
        }
    }
}
