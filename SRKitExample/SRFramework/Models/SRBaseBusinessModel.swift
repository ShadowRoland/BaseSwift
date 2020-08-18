//
//  SRBaseBusinessModel.swift
//  SRFramework
//
//  Created by Gary on 2020/8/17.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import ObjectMapper

open class SRBaseBusinessModel: SRBaseModel, SRDBMappable {
    override public init() { }
    
    required public init?(map: Map) { }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
    }
    
    //MARK: - 数据库相关

    //数据库中存储对应的表名
    open var tableName: String {
        return ""
    }
    
    //创建数据库中表的SQL语句
    open var createTableSQL: String {
        return createTableSQL("`id` integer primary key autoincrement, 'timestamp' integer default 0")
    }
    
    //创建数据库中表的SQL语句，parm sql: 创建其他字段及索引等可追加的sql语句
    open func createTableSQL(_ addSQL: String) -> String {
        var columns = "`id` integer primary key autoincrement, 'timestamp' integer default 0"
        if !addSQL.isEmpty {
            columns.append(", " + addSQL)
        }
        return "create table if not exists \(tableName) \(columns));"
    }
    
    //创建数据库中表的SQL语句，parm sql: 创建其他字段及索引等可追加的sql语句
    open func insertSQL(_ columns: String, values: String) -> String {
        return String(format: "insert into %@ %@ values (%@);",
                      tableName,
                      String(format: "timestamp%@", !columns.isEmpty ? ", \(columns)" : ""),
                      String(format: "0%@", !values.isEmpty ? ", \(values)" : ""))
    }    
}
