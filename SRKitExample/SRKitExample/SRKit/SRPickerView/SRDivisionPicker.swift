//
//  SRDivisionPicker.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/19.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

public class SRDivisionPicker: SRPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    override public weak var delegate: SRPickerViewDelegate? {
        get {
            return super.delegate
        }
        set {
            super.delegate = newValue
            pickerView.delegate = self
        }
    }
    
    override public weak var dataSource: UIPickerViewDataSource? {
        get {
            return super.dataSource
        }
        set {
            super.dataSource = newValue
            pickerView.dataSource = self
        }
    }
    
    public var currentDivisions: [SRDivision] { return _currentDivisions }
    
    private(set) var _currentDivisions: [SRDivision] = SRDivision.default //当前被编辑的行政区域划分，前一个成员是后一个成员的parent

    public func show() {
        let window = UIApplication.shared.windows.last ?? UIApplication.shared.keyWindow!
        window.addSubview(self)
        frame = window.bounds
        
        var text = ""
        _currentDivisions.forEach { text.append($0.name) }
        title = text
        pickerView.reloadAllComponents()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            for i in 0 ..< strongSelf._currentDivisions.count {
                strongSelf.pickerView.selectRow(strongSelf._currentDivisions[i].index,
                                                inComponent: i,
                                                animated: false)
            }
        }
    }
    //MARK: - UIPickerViewDelegate
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return _currentDivisions.count
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           numberOfRowsInComponent component: Int) -> Int {
        if 0 == component {
            return SRDivision.provinces.count
        } else if _currentDivisions.count >= component {
            return _currentDivisions[component - 1].children.count
        }
        return 0
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if 0 == component {
            return SRDivision.provinces[row].name
        } else if _currentDivisions.count >= component
            && _currentDivisions[component - 1].children.count > row {
            return _currentDivisions[component - 1].children[row].name
        }
        return ""
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        guard component < _currentDivisions.count && _currentDivisions[component].index != row else {
            return
        }
        
        //更新选择的区域
        //将左边不变的保留下来
        let division = _currentDivisions[component] //原先的division
        var array: [SRDivision]! //将要被更新的self.divisions
        let list: [SRDivision]! //备选的division列表
        if division.parent == nil { //选择了最左边
            array = [] as [SRDivision]
            list = SRDivision.provinces
        } else {
            array = Array(_currentDivisions[0 ..< component])
            list = division.parent!.children
        }
        let selectedDivision = list[row] //更新后的division
        array.append(selectedDivision)
        array.append(contentsOf: selectedDivision.defaultSub) //更新默认选择的下级区域
        if array.count != _currentDivisions.count {
            DispatchQueue.main.async { [weak self] in
                self?.pickerView.reloadAllComponents()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.pickerView.reloadAllComponents()
                for i in component + 1 ..< strongSelf._currentDivisions.count {
                    strongSelf.pickerView.selectRow(0, inComponent: i, animated: true) //添加动画
                }
            }
        }
        _currentDivisions = array
        
        var text = ""
        _currentDivisions.forEach { text.append($0.name) }
        title = text
    }
}

//MARK: - 行政地区划分(中国)

public class SRDivision {
    public enum Level {
        case province
        case city
        case region
    }
    
    public var index = 0
    public var code = ""
    public var name = ""
    public var parent: SRDivision?
    public var children: [SRDivision] = []
    public var level: SRDivision.Level = .province
    
    static var `default`: [SRDivision]! { return _default }
    public static var provinces: [SRDivision]! { return _provinces }
    public static var cities: [SRDivision]! { return _cities }
    public static var regions: [SRDivision]! { return _regions }
    
    private static var _default: [SRDivision] = []
    private static var _provinces: [SRDivision] = []
    private static var _cities: [SRDivision] = []
    private static var _regions: [SRDivision] = []
    
    public var defaultSub: [SRDivision] {
        var divisions = [] as [SRDivision]
        var division = children.first
        while division != nil {
            divisions.append(division!)
            division = division!.children.first
        }
        return divisions
    }
    
    public class func update() {
        var locations: [String : String]!
        if let array = DocumentsDirectory.appending(pathComponent: "china_locations.json").fileJsonObject as? [String : String] {
            locations = array
        } else {
            locations = ResourceDirectory.appending(pathComponent: "json/debug/china_locations.json").fileJsonObject as? [String : String]
        }
        _default.removeAll()
        _provinces.removeAll()
        _cities.removeAll()
        _regions.removeAll()
        locations.sorted { $0.key < $1.key }.forEach {
            let division = SRDivision()
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
    
    public class func divisions(codes: [String]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = codes.count
        var list: [SRDivision]!
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
    
    private class func division(code: String, list: [SRDivision]) -> SRDivision? {
        return list.first { code == $0.code }
    }
    
    public class func divisions(names: [String]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = names.count
        var list: [SRDivision]!
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
    
    private class func division(name: String, list: [SRDivision]) -> SRDivision? {
        return list.first { name == $0.name }
    }
    
    public class func divisions(indexes: [Int]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = indexes.count
        var list: [SRDivision]!
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
    
    private class func division(index: Int, list: [SRDivision]) -> SRDivision? {
        return list.first { index == $0.index }
    }
}
