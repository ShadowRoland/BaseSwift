//
//  ProfileManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit

public class ProfileManager: BusinessManager {
    //输入参数nil意味着清空当前所有数据
    func updateProfile(_ dictionary: ParamDictionary?) {
        let profile = Common.currentProfile()
        var model: ProfileModel?
        if let profile = profile, let dictionary = dictionary {
            model = ProfileModel(JSON: profile.toJSON().extend(dictionary))!
        } else {
            model = ProfileModel(JSON: dictionary ?? EmptyParams())!
        }
        
        if let model = model {
            if let profile = profile {
                model.imToken = profile.imToken
                model.isLogin = profile.isLogin
            }
            Common.updateCurrentProfile(model)
        }
    }
    
    func getContacts(_ type: UserModel.SNSType) -> [UserModel] {
        var pathComponent = "json/debug/single_contacts.json"
        if type == .officialAccount {
            pathComponent = "json/debug/official_accounts_contacts.json"
        }
        let jsonFile = ResourceDirectory.appending(pathComponent: pathComponent)
        return NonNull.array(Common.readJsonFile(jsonFile)).compactMap {
            if let json = $0 as? ParamDictionary, let model = UserModel(JSON: json) {
                return model
            }
            return nil
        }
    }
    
    override public func callBusiness(_ funcId: UInt, params: Any?) -> BFResult<Any> {
        let capability = Manager.Profile.Capability(rawValue: funcId) as Manager.Profile.Capability?
        if capability == nil {
            return .failure(BFError.callModuleFailed(.capabilityNotExist(funcId)))
        }
        
        switch capability! {
        case .login:
            updateProfile(params as? ParamDictionary)
            Common.currentProfile()?.isLogin = true
            Common.currentProfile()?.createDirectories()
            BF.callBusiness(BF.businessId(.http, HttpCapability.function(.updateToken).funcId))
            
        case .logout:
            Common.updateCurrentProfile(nil)
            
        case .updateProfile:
            updateProfile(params as? ParamDictionary)
            
        case .getSingleContacts:
            return .success(getContacts(.single))
            
        case .getOfficialAccountsContacts:
            return .success(getContacts(.officialAccount))
            
        default:
            break
        }
        return .success(nil)
    }
}
