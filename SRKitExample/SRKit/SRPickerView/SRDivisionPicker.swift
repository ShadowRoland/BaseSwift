//
//  SRDivisionPicker.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/19.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON
import Gzip

public class SRDivisionPicker: SRPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    private var _chinaLocations: [String : String] = [:]
    public var chinaLocations: [String : String] {
        get {
            if _chinaLocations.isEmpty {
                let filePath = Bundle.sr.resourcePath!.appending(pathComponent: "china_locations.json.zip")
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: filePath)).gunzipped()
                    _chinaLocations = try JSON(data: data).rawValue as? [String : String] ?? [:]
                } catch {
                    LogError("Unzip and transfer china locations file failed: \(filePath), error.localizedDescription")
                }
            }
            return _chinaLocations
        }
        set {
            _chinaLocations = newValue
            _firstLocations.removeAll()
            _provinces.removeAll()
            _cities.removeAll()
            _regions.removeAll()
            _chinaLocations.sorted { $0.key < $1.key }.forEach {
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
                _firstLocations.append(contentsOf: division.firstLocations)
            }
        }
    }
    public var firstLocations: [SRDivision]! { return _provinces }
    public var provinces: [SRDivision]! { return _provinces }
    public var cities: [SRDivision]! { return _cities }
    public var regions: [SRDivision]! { return _regions }
    
    private var _firstLocations: [SRDivision] = []
    private var _provinces: [SRDivision] = []
    private var _cities: [SRDivision] = []
    private var _regions: [SRDivision] = []
    
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
    
    public var currentDivisions: [SRDivision] = []

    public func show() {
        let window = UIApplication.shared.windows.last ?? UIApplication.shared.keyWindow!
        window.addSubview(self)
        frame = window.bounds
        
        var text = ""
        currentDivisions.forEach { text.append($0.name) }
        title = text
        pickerView.reloadAllComponents()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            for i in 0 ..< strongSelf.currentDivisions.count {
                strongSelf.pickerView.selectRow(strongSelf.currentDivisions[i].index,
                                                inComponent: i,
                                                animated: false)
            }
        }
    }
    
    //MARK: - UIPickerViewDelegate
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return currentDivisions.count
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           numberOfRowsInComponent component: Int) -> Int {
        if 0 == component {
            return provinces.count
        } else if currentDivisions.count >= component {
            return currentDivisions[component - 1].children.count
        }
        return 0
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if 0 == component, row < provinces.count {
            return provinces[row].name
        } else if component <= currentDivisions.count
            && currentDivisions[component - 1].children.count > row {
            return currentDivisions[component - 1].children[row].name
        }
        return ""
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        guard component < currentDivisions.count && currentDivisions[component].index != row else {
            return
        }
        
        //更新选择的区域
        //将左边不变的保留下来
        let division = currentDivisions[component] //原先的division
        var array: [SRDivision]! //将要被更新的self.divisions
        let list: [SRDivision]! //备选的division列表
        if division.parent == nil { //选择了最左边
            array = [] as [SRDivision]
            list = provinces
        } else {
            array = Array(currentDivisions[0 ..< component])
            list = division.parent!.children
        }
        let selectedDivision = list[row] //更新后的division
        array.append(selectedDivision)
        array.append(contentsOf: selectedDivision.firstLocations) //更新默认选择的下级区域
        if array.count != currentDivisions.count {
            DispatchQueue.main.async { [weak self] in
                self?.pickerView.reloadAllComponents()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.pickerView.reloadAllComponents()
                for i in component + 1 ..< strongSelf.currentDivisions.count {
                    strongSelf.pickerView.selectRow(0, inComponent: i, animated: true) //添加动画
                }
            }
        }
        currentDivisions = array
        
        var text = ""
        currentDivisions.forEach { text.append($0.name) }
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
    
    public var firstLocations: [SRDivision] {
        var divisions = [] as [SRDivision]
        divisions.append(self)
        var division = children.first
        while division != nil {
            divisions.append(division!)
            division = division!.children.first
        }
        return divisions
    }
    
    public class func divisions(codes: [String], from divisions: [SRDivision]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = codes.count
        var list: [SRDivision]!
        for i in 0 ..< count {
            if i == 0 {
                list = divisions
            }
            if let division = list.first(where: { codes[i] == $0.code }) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
    
    public class func divisions(names: [String], from divisions: [SRDivision]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = names.count
        var list: [SRDivision]!
        for i in 0 ..< count {
            if i == 0 {
                list = divisions
            }
            if let division = list.first(where: { names[i] == $0.name }) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
    
    public class func divisions(indexes: [Int], from divisions: [SRDivision]) -> [SRDivision] {
        var array = [] as [SRDivision]
        let count = indexes.count
        var list: [SRDivision]!
        for i in 0 ..< count {
            if i == 0 {
                list = divisions
            }
            if let division = list.first(where: { indexes[i] == $0.index }) {
                array.append(division)
                list = division.children
            } else {
                break
            }
        }
        return array
    }
}
