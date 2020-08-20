//
//  SRDBMappable.swift
//  SRFramework
//
//  Created by Gary on 2020/8/18.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import ObjectMapper

///在此定义类属性与数据库集合的对应关系，以便在SRDBModel的mappingDB方法中进行区别甄别
///可通过扩展SRDBMapContext的成员来创建子集以便对部分字段进行查询/修改，如
///extension SRDBMapContext {
///     public static let insertNew = SRElement([elements.)
open class SRDBMapContext: SRNestedElement, MapContext {
    public static let insertNew = SRNestedElement()
    public static let selectAll = SRNestedElement()
    public static let selectMain = SRNestedElement()
    public static let updateMain = SRNestedElement()
    ///适用于SQL语句中where部分
    public static let whereInSQL = SRNestedElement()
}

public protocol SRDBModel {
    ///提供一个仅经过初始化的model
    func modelMapping(map: Map) -> SRDBModel
    
    ///根据map的context是否为SRDBMapContext的某一集合而进行不同字段的获取与赋值
    ///建议在此方法中根据(map.context as> SRDBMapContext).contains(SRDBMapContext.selectAll)
    mutating func mappingDB(map: Map)
    
    ///数据库中存储对应的表名
    var tableName: String { get set }
    
    ///创建数据库中对应表的SQL语句
    var createTableSQL: String { get }
    
    ///创建数据库中表的SQL语句，默认id为自增长的索引
    ///入参addSQL: 创建其他字段及索引等可追加的sql语句
    func createTableSQL(_ addSQL: String) -> String
    
    ///插入数据库中对应表的SQL语句
    ///若入参columns和values均不为空，将以追加列名和列值的方式返回SQL
    ///入参columns： 插入的列名，以,分割
    ///入参values: 对应列的插入值，以,分割，若更新的是字符串，需要两边加上单引号'
    func insertSQL(_ columns: String, values: String) -> String
    
    ///查询数据库中对应表的SQL语句，默认结果集部分为*，以id为条件语句
    ///若入参columns不为空，会替换SQL语句中的结果集部分；若入参whereSQL不为空，会替换SQL语句中的where部分
    ///入参columns: SQL语句的结果集部分
    ///入参whereSQL: SQL语句的where部分，需要更新记录满足的条件，具体参考SQL语句的select语法
    func selectSQL(_ columns: String, where whereSQL: String) -> String

    ///更新数据库中对应表的SQL语句，默认以id为条件语句，并更新timestamp
    ///若入参setSQL不为空，会替换SQL语句中的set部分；若入参whereSQL不为空，会替换SQL语句中的where部分
    ///入参setSQL: SQL语句的set部分，更新的列名和对应的值，形式为name = value，以,分割
    ///入参whereSQL: SQL语句的where部分，需要更新记录满足的条件，具体参考SQL语句的update语法
    func updateSQL(_ setSQL: String, where whereSQL: String) -> String
    
    ///删除数据库中表的SQL语句，默认以id为条件语句
    ///若入参whereSQL不为空，会替换SQL语句中的where部分
    ///入参whereSQL: SQL语句的where部分
    func deleteSQL(_ whereSQL: String) -> String;
}
