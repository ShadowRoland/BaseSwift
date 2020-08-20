//
//  SRDBManager.swift
//  SRFramework
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import FMDB
import ObjectMapper
import SRKit
import UIKit

open class SRDBManager {
    public init() { }

    open var filePath = ""

    open func open(_ filePath: String = "") throws -> FMDatabase {
        let path = filePath.trim.isEmpty ? self.filePath : filePath
        let db = FMDatabase(path: path)
        if !db.open() {
            throw BFError("open database file failed: \(path)")
        } else {
            return db
        }
    }

    open func open(db: FMDatabase?) throws -> FMDatabase {
        if let db = db {
            return db
        } else {
            return try open()
        }
    }

    open func closeIfNeed(_ db: FMDatabase?, _ inDb: FMDatabase?) {
        if db !== inDb {
            db?.close()
        }
    }

    open func executeQuery(_ sql: String, db inDb: FMDatabase? = nil) throws -> FMResultSet {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        do {
            let resultSet = try db.executeQuery(sql, values: nil)
            closeIfNeed(db, inDb)
            return resultSet
        } catch {
            throw BFError(error: error)
        }
    }

    open func executeUpdate(_ sql: String, db inDb: FMDatabase? = nil) throws {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        do {
            try db.executeUpdate(sql, values: nil)
            closeIfNeed(db, inDb)
        } catch {
            throw BFError(error: error)
        }
    }

    // MARK: -

    open func insertModels(_ model: SRDBModel,
                           columnsContext: SRDBMapContext? = nil,
                           addColumns: String = "",
                           valuesContext: SRDBMapContext? = nil,
                           addValues: String = "",
                           db inDb: FMDatabase? = nil) throws {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        do {
            try executeUpdate(model.insertSQL(addColumns, values: addValues), db: db)
            closeIfNeed(db, inDb)
        } catch {
            throw BFError(error: error)
        }
    }

    open func selectModels(_ model: SRDBModel,
                           columns: String = "",
                           columnsContext: SRDBMapContext? = nil,
                           where whereSQL: String = "",
                           whereContext: SRDBMapContext? = nil,
                           db inDb: FMDatabase? = nil) throws -> [SRDBModel] {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        let resultSet = try executeQuery(model.selectSQL(columns, where: whereSQL), db: db)
        var models = [] as [SRDBModel]
        while resultSet.next() {
            models.append(model.modelMapping(map: Map(mappingType: .fromJSON,
                                                      JSON: resultSet.resultDictionary as? ParamDictionary ?? [:],
                                                      context: context)))
        }
        return models
    }

    open func updateModels(_ model: SRDBModel,
                           columns: String = "",
                           columnsContext: SRDBMapContext? = nil,
                           where whereSQL: String = "",
                           whereContext: SRDBMapContext? = nil,
                           db inDb: FMDatabase? = nil) throws {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        if let whereContext = whereContext {
            
        }
        try executeUpdate(model.updateSQL(columns, where: whereSQL), db: db)
    }

    open func deleteModels(_ model: SRDBModel,
                           where whereSQL: String = "",
                           context: SRDBMapContext? = nil,
                           db inDb: FMDatabase? = nil) throws {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        try executeUpdate(model.deleteSQL(whereSQL), db: db)
    }
}
