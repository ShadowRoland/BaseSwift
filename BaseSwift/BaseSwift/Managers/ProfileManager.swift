//
//  ProfileManager.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

public class ProfileManager {
    //输入参数nil意味着清空当前所有数据
    class func updateProfile(_ dictionary: ParamDictionary?) {
        let profile = Common.currentProfile()
        var model: ProfileModel?
        if let profile = profile, let dictionary = dictionary {
            model = ProfileModel(JSON: profile.toJSON().extend(dictionary))!
        } else {
            model = ProfileModel(JSON: dictionary ?? [:])!
        }
        
        if let model = model {
            if let profile = profile {
                model.imToken = profile.imToken
                model.isLogin = profile.isLogin
            }
            Common.updateCurrentProfile(model)
        }
    }
    
    class func getContacts(_ type: UserModel.SNSType) -> [UserModel] {
        var pathComponent = "json/debug/single_contacts.json"
        if type == .officialAccount {
            pathComponent = "json/debug/official_accounts_contacts.json"
        }
        let jsonFile = ResourceDirectory.appending(pathComponent: pathComponent)
        return NonNull.array(jsonFile.fileJsonObject).compactMap {
            if let json = $0 as? ParamDictionary, let model = UserModel(JSON: json) {
                return model
            }
            return nil
        }
    }
}
