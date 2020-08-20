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

open class SRBaseBusinessModel: SRBaseModel, SRDBModel {
    override public init() { super.init() }
    
    //MARK: - Mappable
    required public init?(map: Map) { super.init(map: map)}
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
    }
    
    //MARK: - NSCopying
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        return SRBaseBusinessModel(JSON: toJSON()) ?? SRBaseBusinessModel()
    }
    
    //MARK: - SRDBModel
    
    open func modelMapping(map: Map) -> SRDBModel {
        if let model = SRBaseBusinessModel(map: map) {
            return model
        } else {
            return SRBaseBusinessModel()
        }
    }

    open func mappingDB(map: Map) {
        if let context = map.context as SRDBMapContext {
            if context.contains(.selectMain) { ///只获取主要字段
                mapping(map: map)
            } else if context.contains(.updateMain) { ///只更新主要字段
                timestamp <- map[Param.Key.timestamp]
            } else if (context.contains(.whereInSQL)) {
                id <- map[Param.Key.id]
            }
        } else {
            mapping(map: map)
        }
    }

    open var tableName: String {
        get {
            return ""
        }
        set {
            
        }
    }
    
    open var createTableSQL: String {
        return createTableSQL("`id` integer primary key autoincrement, 'timestamp' integer default 0")
    }
    
    open func createTableSQL(_ addSQL: String) -> String {
        var columns = "`id` integer primary key autoincrement, 'timestamp' integer default 0"
        if !addSQL.isEmpty {
            columns.append(", " + addSQL)
        }
        return "create table if not exists \(tableName) \(columns));"
    }
    
    open func insertSQL(_ columns: String, values: String) -> String {
        var columnsSQL = "timestamp"
        var valuesSQL = "0"
        if !columns.trim.isEmpty && !values.trim.isEmpty {
            columnsSQL.append(", \(columns)")
            valuesSQL.append(", \(values)")
        }
        return "insert into \(tableName) \(columnsSQL) values (\(valuesSQL));"
    }
    
    open func selectSQL(_ columns: String, where whereSQL: String) -> String {
        let columnsSQL = !columns.trim.isEmpty ? columns : "*"
        let newWhereSQL = !whereSQL.trim.isEmpty ? whereSQL : "id = \(id)"
        return "select \(columnsSQL) from \(tableName) where \(newWhereSQL);"
    }
    
    open func updateSQL(_ setSQL: String, where whereSQL: String) -> String {
        let newSetSQL = !setSQL.trim.isEmpty ? setSQL : "timestamp = \(NSDate().timeIntervalSince1970)"
        let newWhereSQL = !whereSQL.trim.isEmpty ? whereSQL : "id = \(id)"
        return "update \(tableName) set \(newSetSQL) where \(newWhereSQL);"
    }
    
    open func deleteSQL(_ whereSQL: String) -> String {
        let newWhereSQL = !whereSQL.trim.isEmpty ? whereSQL : "id = \(id)"
        return "delete from \(tableName) where \(newWhereSQL);"
    }
}
