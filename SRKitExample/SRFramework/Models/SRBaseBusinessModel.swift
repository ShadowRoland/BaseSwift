//
//  SRBaseBusinessModel.swift
//  SRFramework
//
//  Created by Gary on 2020/8/17.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import ObjectMapper

open class SRBaseBusinessModel: NSObject, Mappable {
    open var id: String?
    open var timestamp: Int?
    
    override public init() { }
    
    required public init?(map: Map) { }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
        
        id <- map[Param.Key.id]
        timestamp <- map[Param.Key.timestamp]
    }
    
    public static func == (lhs: BaseBusinessModel, rhs: BaseBusinessModel) -> Bool {
        if lhs === rhs {
            return true
        } else if let id = lhs.id, id == rhs.id {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - 数据库相关
    
    open var tableName: String {
        return ""
    }
    
    open func createTableSQL(tableName: String, sql: String) {
        return "create table if not exists \(tableName) `id` integer primary key autoincrement"
    }
    
    open var createTableSQL: String {
        
    }
}
