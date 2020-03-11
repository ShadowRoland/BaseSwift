//
//  ProfileManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

public class ProfileManager {
    public static var currentProfile: ProfileModel?
    
    public static var isLogin: Bool {
        if let profile = currentProfile {
            return profile.isLogin
        }
        return false
    }
    
    //输入参数nil意味着清空当前所有数据
    class func updateProfile(_ dictionary: ParamDictionary?) {
        var model: ProfileModel?
        if let profile = currentProfile, let dictionary = dictionary {
            model = ProfileModel(JSON: profile.toJSON().extend(dictionary))!
        } else {
            model = ProfileModel(JSON: dictionary ?? [:])!
        }
        
        if let model = model {
            if let profile = currentProfile {
                model.imToken = profile.imToken
                model.isLogin = profile.isLogin
            }
            currentProfile = model
        }
    }
    
    class func getContacts(_ type: UserModel.SNSType) -> [UserModel] {
        var pathComponent = "json/debug/single_contacts.json"
        if type == .officialAccount {
            pathComponent = "json/debug/official_accounts_contacts.json"
        }
        let jsonFile = C.resourceDirectory.appending(pathComponent: pathComponent)
        return NonNull.array(jsonFile.fileJsonObject).compactMap {
            if let json = $0 as? ParamDictionary, let model = UserModel(JSON: json) {
                return model
            }
            return nil
        }
    }
}
