//
//  SRDatePicker.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/19.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

public class SRDatePicker: SRPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
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
    
    public var minDate = "1926-08-26T00:00:00.000GMT+08:00".date(DateFormat.full)!
    public var maxDate = Date()
    public var currentDate = Date()
    
    private var minDateComponents: DateComponents!
    private var maxDateComponents: DateComponents!
    private var alternativeYears: [Int]! //候选的年
    private var alternativeMonths: [Int]! //候选的月
    private var alternativeDays: [Int]! //候选的日
    
    public func show() {
        maxDate = maxDate < minDate ? minDate : maxDate
        minDateComponents = minDate.components()
        maxDateComponents = maxDate.components()
        alternativeYears = alternativeArray(minDateComponents.year!, to: maxDateComponents.year!)
        currentDate = currentDate < maxDate ? currentDate : maxDate
        
        let dateComponents = currentDate.components()
        let selectedYearIndex = alternativeYears.index(of: dateComponents.year!)!
        
        let monthRange = self.monthRange(dateComponents.year!)
        alternativeMonths = alternativeArray(monthRange.first!, to: monthRange.last!)
        let selectedMonthIndex = alternativeMonths.index(of: dateComponents.month!)!
        
        let dayRange = self.dayRange(dateComponents.year!, month: dateComponents.month!)
        alternativeDays = alternativeArray(dayRange.first!, to: dayRange.last!)
        let selectedDayIndex = alternativeDays.index(of: dateComponents.day!)!
        
        let window = UIApplication.shared.windows.last ?? UIApplication.shared.keyWindow!
        window.addSubview(self)
        frame = window.bounds
        title = String(date: currentDate, format: DateFormat.localDate)
        pickerView.reloadAllComponents()
        DispatchQueue.main.async { [weak self] in
            self?.pickerView.selectRow(selectedYearIndex,
                                       inComponent: 0,
                                       animated: false)
            self?.pickerView.selectRow(selectedMonthIndex,
                                       inComponent: 1,
                                       animated: false)
            self?.pickerView.selectRow(selectedDayIndex,
                                       inComponent: 2,
                                       animated: false)
        }
    }
    
    //MARK: - Pick date
    
    private func updateAlternativeMonthsAndDays() {
        let dateComponents = currentDate.components()
        if dateComponents.year == minDateComponents.year {
            if dateComponents.month == minDateComponents.month {
                if minDateComponents.year == maxDateComponents.year { //最大最小在同一年
                    alternativeMonths = alternativeArray(minDateComponents.month!,
                                                         to: maxDateComponents.month!)
                    if minDateComponents.month! == maxDateComponents.month! { //最大最小在同一年的同一个月
                        alternativeDays = alternativeArray(minDateComponents.day!,
                                                           to: maxDateComponents.day!)
                    } else {
                        //拿最小日期当月的总天数减去所在的天数
                        alternativeDays =
                            alternativeArray(minDateComponents.day!,
                                             to: Date.dayCount(dateComponents.year!,
                                                               month: dateComponents.month!))
                    }
                    return
                }
                alternativeMonths = alternativeArray(minDateComponents.month!, to: 12)
                alternativeDays =
                    alternativeArray(minDateComponents.day!,
                                     to: Date.dayCount(dateComponents.year!,
                                                       month: dateComponents.month!))
                return
            }
        } else if dateComponents.year == maxDateComponents.year {
            if dateComponents.month == maxDateComponents.month {
                alternativeMonths = alternativeArray(1, to: maxDateComponents.month!)
                alternativeDays = alternativeArray(1, to: maxDateComponents.day!)
                return
            }
        }
        alternativeMonths = alternativeArray(1, to: 12)
        alternativeDays = alternativeArray(1, to: Date.dayCount(dateComponents.year!,
                                                                month: dateComponents.month!))
    }
    
    private func monthRange(_ year: Int) -> CountableClosedRange<Int> {
        if year == minDateComponents.year {
            if minDateComponents.year == maxDateComponents.year { //最大最小在同一年
                return minDateComponents.month! ... maxDateComponents.month!
            }
            return minDateComponents.month! ... 12
        } else if year == maxDateComponents.year {
            return 1 ... maxDateComponents.month!
        }
        return 1 ... 12
    }
    
    //year和month需要之前已经判断了合理性，即year和month已在最大日期和最小日期之间
    private func dayRange(_ year: Int, month: Int) -> CountableClosedRange<Int> {
        if year == minDateComponents.year {
            if minDateComponents.year == maxDateComponents.year { //最大最小在同一年
                if month == minDateComponents.month {
                    if minDateComponents.month == maxDateComponents.month { //最大最小在同一年的同一个月
                        return minDateComponents.day! ... maxDateComponents.day!
                    }
                }
            }
            return minDateComponents.day! ... Date.dayCount(year, month: month)
        } else if year == maxDateComponents.year {
            if month == maxDateComponents.month {
                return 1 ... maxDateComponents.day!
            }
        }
        return 1 ... Date.dayCount(year, month: month)
    }
    
    func alternativeArray(_ from: Int, to: Int) -> [Int] {
        var array = [] as [Int]
        var i = from
        while i <= to {
            array.append(i)
            i += 1
        }
        return array
    }
    
    //MARK: - UIPickerViewDelegate
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           numberOfRowsInComponent component: Int) -> Int {
        if 0 == component {
            return alternativeYears.count
        } else if 1 == component {
            return alternativeMonths.count
        } else {
            return alternativeDays.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           titleForRow row: Int,
                           forComponent component: Int) -> String? {
        if 0 == component {
            return String(int: alternativeYears[row])
        } else if 1 == component {
            return String(int: alternativeMonths[row])
        } else {
            return String(int: alternativeDays[row])
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           didSelectRow row: Int,
                           inComponent component: Int) {
        var selectedYear: Int!
        
        var selectedMonth: Int!
        var selectedDay: Int!
        if 0 == component { //变更的是年
            selectedYear = alternativeYears[row]
            
            selectedMonth = alternativeMonths[pickerView.selectedRow(inComponent: 1)]
            let monthRange = self.monthRange(selectedYear)
            if !monthRange.contains(selectedMonth) { //原先的月在新的年中不存在，前后找最近的
                let offsetFirst = fabs(Double(monthRange.first! - selectedMonth))
                let offsetLast = fabs(Double(monthRange.last! - selectedMonth))
                selectedMonth =  offsetFirst < offsetLast ? monthRange.first! : monthRange.last!
            }
            alternativeMonths = alternativeArray(monthRange.first!, to: monthRange.last!)
            let selectedMonthIndex = alternativeMonths.index(of: selectedMonth)!
            
            selectedDay = alternativeDays[pickerView.selectedRow(inComponent: 2)]
            let dayRange = self.dayRange(selectedYear, month: selectedMonth)
            if !dayRange.contains(selectedDay) { //原先的日在新的年月中不存在，前后找最近的
                let offsetFirst = fabs(Double(dayRange.first! - selectedDay))
                let offsetLast = fabs(Double(dayRange.last! - selectedDay))
                selectedDay = offsetFirst < offsetLast ? dayRange.first! : dayRange.last!
            }
            alternativeDays = alternativeArray(dayRange.first!, to: dayRange.last!)
            let selectedDayIndex = alternativeDays.index(of: selectedDay)!
            
            DispatchQueue.main.async { [weak self] in
                self?.pickerView.reloadComponent(1)
                self?.pickerView.reloadComponent(2)
                self?.pickerView.selectRow(selectedMonthIndex,
                                           inComponent: 1,
                                           animated: true)
                self?.pickerView.selectRow(selectedDayIndex,
                                           inComponent: 2,
                                           animated: true)
            }
        } else if 1 == component { //变更的是月
            selectedYear = alternativeYears[pickerView.selectedRow(inComponent: 0)]
            selectedMonth = alternativeMonths[row]
            selectedDay = alternativeDays[pickerView.selectedRow(inComponent: 2)]
            let dayRange = self.dayRange(selectedYear, month: selectedMonth)
            if !dayRange.contains(selectedDay) { //原先的日在新的年月中不存在，前后找最近的
                let offsetFirst = fabs(Double(dayRange.first! - selectedDay))
                let offsetLast = fabs(Double(dayRange.last! - selectedDay))
                selectedDay = offsetFirst < offsetLast ? dayRange.first! : dayRange.last!
            }
            alternativeDays = alternativeArray(dayRange.first!, to: dayRange.last!)
            let selectedDayIndex = alternativeDays.index(of: selectedDay)!
            
            DispatchQueue.main.async { [weak self] in
                self?.pickerView.reloadComponent(2)
                self?.pickerView.selectRow(selectedDayIndex,
                                           inComponent: 2,
                                           animated: true)
            }
        } else {
            selectedYear = alternativeYears[pickerView.selectedRow(inComponent: 0)]
            selectedMonth = alternativeMonths[pickerView.selectedRow(inComponent: 1)]
            selectedDay = alternativeDays[row]
        }
        
        var dateComponents = Date().components()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth
        dateComponents.day = selectedDay
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        currentDate = dateComponents.date!
        title = String(date: currentDate, format: DateFormat.localDate)
    }
}
