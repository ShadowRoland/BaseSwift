//
//  ProfileModel.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import ObjectMapper

public class ProfileModel: UserModel {
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
    
    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)
        
        countryCode <- map[Param.Key.countryCode]
        phone <- map[Param.Key.phone]
        name <- map[Param.Key.name]
        signature <- map[Param.Key.signature]
        birthDate <- map[Param.Key.birthDate]
        location <- map[Param.Key.location]
        deviceToken <- map[Param.Key.deviceToken]
        token <- map[Param.Key.token]
        balance <- map[Param.Key.balance]
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
        
        let root = C.userDirectory.appending(pathComponent: userId)
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

class NameModel: BaseModel {
    var first: String?
    var middle: String?
    var last: String?
    var fullName: String {
        return NonNull.string(first) + NonNull.string(middle) + NonNull.string(last)
    }

    override public func mapping(map: ObjectMapper.Map) {
        super.mapping(map: map)

        first <- map[Param.Key.first]
        middle <- map[Param.Key.middle]
        last <- map[Param.Key.last]
    }
}

