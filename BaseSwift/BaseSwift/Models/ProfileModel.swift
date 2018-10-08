//
//  ProfileModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import ObjectMapper

open class ProfileModel: UserModel {
    var countryCode: Int? //手机号码的国家码
    var phone: String? //手机号
    var name: NameModel?
    var signature: String? //签名
    var birthDate: String? //出生年月日
    var location: AddressModel? //所在地
    var deviceToken: String?
    var token: String?
    var balance: Double?
    var isLogin: Bool = false
    
    var imToken: String?
    var isIMLogin: Bool = false
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        countryCode <- map[ParamKey.countryCode]
        phone <- map[ParamKey.phone]
        name <- map[ParamKey.name]
        signature <- map[ParamKey.signature]
        birthDate <- map[ParamKey.birthDate]
        location <- map[ParamKey.location]
        deviceToken <- map[ParamKey.deviceToken]
        token <- map[ParamKey.token]
        balance <- map[ParamKey.balance]
    }
    
    //MARK: Directory
    
    enum DirectoryType {
        case root
        case download
        case upload
        
        static let allValues = [root, download, upload]
    }
    
    func directory(_ type: DirectoryType) -> String? {
        guard let userId = userId else {
            return nil
        }
        
        let root = UserDirectory.appending(pathComponent: userId)
        switch type {
        case .root:
            return root
        case .download:
            return root.appending(pathComponent: "Download")
        case .upload:
            return root.appending(pathComponent: "Upload")
        }
    }
    
    func createDirectories() {
        for type in DirectoryType.allValues {
            guard let directory = directory(type) else {
                continue
            }
            
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory) {
                if !isDirectory.boolValue {
                    do {
                        try FileManager.default.removeItem(atPath: directory)
                    } catch {
                        LogError("remove file fail: \(directory)")
                        continue
                    }
                    
                    do {
                        try FileManager.default.createDirectory(at: URL(fileURLWithPath: directory),
                                                                withIntermediateDirectories: true,
                                                                attributes: nil)
                    } catch {
                        LogError("create directory fail: \(directory)")
                    }
                }
            } else {
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: directory),
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                } catch {
                    LogError("create directory fail: \(directory)")
                }
            }
        }
    }
}

//MARK: -

open class NameModel: BaseModel {
    var first: String?
    var middle: String?
    var last: String?
    var fullName: String {
        return NonNull.string(first) + NonNull.string(middle) + NonNull.string(last)
    }
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        first <- map[ParamKey.first]
        middle <- map[ParamKey.middle]
        last <- map[ParamKey.last]
    }
}

