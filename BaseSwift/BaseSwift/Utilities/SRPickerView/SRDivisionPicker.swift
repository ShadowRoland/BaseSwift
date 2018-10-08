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
    
    var currentDivisions: [Division] = Division.default //当前被编辑的行政区域划分，前一个成员是后一个成员的parent

    public func show() {
        let window = UIApplication.shared.windows.last ?? UIApplication.shared.keyWindow!
        window.addSubview(self)
        frame = window.bounds
        
        var text = EmptyString
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
            return Division.provinces.count
        } else if currentDivisions.count >= component {
            return currentDivisions[component - 1].children.count
        }
        return 0
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if 0 == component {
            return Division.provinces[row].name
        } else if currentDivisions.count >= component
            && currentDivisions[component - 1].children.count > row {
            return currentDivisions[component - 1].children[row].name
        }
        return EmptyString
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
        var array: [Division]! //将要被更新的self.divisions
        let list: [Division]! //备选的division列表
        if division.parent == nil { //选择了最左边
            array = [] as [Division]
            list = Division.provinces
        } else {
            array = Array(currentDivisions[0 ..< component])
            list = division.parent!.children
        }
        let selectedDivision = list[row] //更新后的division
        array.append(selectedDivision)
        array.append(contentsOf: selectedDivision.defaultSub) //更新默认选择的下级区域
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
        
        var text = EmptyString
        currentDivisions.forEach { text.append($0.name) }
        title = text
    }
}
