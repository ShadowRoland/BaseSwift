//
//  Division.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/20.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

//MARK: - 行政地区划分(中国)

class Division {
    enum Level {
        case province
        case city
        case region
    }
    
    var index = 0
    var code = EmptyString
    var name = EmptyString
    var parent: Division?
    var children: [Division] = []
    var level: Division.Level = .province
    
    static var `default`: [Division]! { return _default }
    static var provinces: [Division]! { return _provinces }
    static var cities: [Division]! { return _cities }
    static var regions: [Division]! { return _regions }
    
    private static var _default: [Division] = []
    private static var _provinces: [Division] = []
    private static var _cities: [Division] = []
    private static var _regions: [Division] = []
    
    var defaultSub: [Division] {
        var divisions = [] as [Division]
        var division = children.first
        while division != nil {
            divisions.append(division!)
            division = division!.children.first
        }
        return divisions
    }
    
    class func update() {
        var locations: [String : String]!
        if let array = Common.readJsonFile(DocumentsDirectory.appending(pathComponent: "china_locations.json")) as? [String : String] {
            locations = array
        } else {
            locations = Common.readJsonFile(ResourceDirectory.appending(pathComponent: "json/debug/china_locations.json")) as? [String : String]
        }
        _default.removeAll()
        _provinces.removeAll()
        _cities.removeAll()
        _regions.removeAll()
        locations.sorted { $0.key < $1.key }.forEach {
            let division = Division()
            division.code = $0.key
            division.name = $0.value
            
            let code = Int(division.code) ?? 0
            if code.isMultiple(of: 10000) { //获取所有的省级行政单位
                division.index = _provinces.count
                division.level = .province
                _provinces.append(division)
            } else if code.isMultiple(of: 100) { //获取所有的市级行政单位
                division.level = .city
                _cities.append(division)
                if let province = _provinces.last(where: {
                    if let pCode = Int($0.code), 0 < code - pCode && code - pCode <= 10000 {
                        return true
                    } else {
                        return false
                    }
                }) {
                    division.index = province.children.count
                    division.parent = province
                    province.children.append(division)
                }
            } else { //获取城市的地区行政单位
                division.level = .region
                _regions.append(division)
                
                if let city = _cities.last(where: {
                    if let pCode = Int($0.code), 0 < code - pCode && code - pCode <= 100 {
                        return true
                    } else {
                        return false
                    }
                }) {
                    division.index = city.children.count
                    division.parent = city
                    city.children.append(division)
                } else {
                    if let province = _provinces.last(where: {
                        if let pCode = Int($0.code), 0 < code - pCode && code - pCode <= 10000 {
                            return true
                        } else {
                            return false
                        }
                    }) {
                        division.index = province.children.count
                        division.parent = province
                        province.children.append(division)
                    }
                }
            }
        }
        
        if let division = _provinces.first {
            _default.append(division)
            _default.append(contentsOf: division.defaultSub)
        }
    }
    
    class func divisions(codes: [String]) -> [Division] {
        var array = [] as [Division]
        let count = codes.count
        var list: [Division]!
        for i in 0 ..< count {
            if i == 0 {
                list = _provinces
            }
            if let division = division(code: codes[i], list: list) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
    
    private class func division(code: String, list: [Division]) -> Division? {
        return list.first { code == $0.code }
    }
    
    class func divisions(names: [String]) -> [Division] {
        var array = [] as [Division]
        let count = names.count
        var list: [Division]!
        for i in 0 ..< count {
            if i == 0 {
                list = _provinces
            }
            if let division = division(name: names[i], list: list) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
    
    private class func division(name: String, list: [Division]) -> Division? {
        return list.first { name == $0.name }
    }
    
    class func divisions(indexes: [Int]) -> [Division] {
        var array = [] as [Division]
        let count = indexes.count
        var list: [Division]!
        for i in 0 ..< count {
            if i == 0 {
                list = _provinces
            }
            if let division = division(index: indexes[i], list: list) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
    
    private class func division(index: Int, list: [Division]) -> Division? {
        return list.first { index == $0.index }
    }
}
