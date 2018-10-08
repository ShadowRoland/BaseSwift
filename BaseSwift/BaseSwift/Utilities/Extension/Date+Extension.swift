//
//  Date+Extension.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/11.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

public extension Date {
    func components(_ identifier: Calendar.Identifier = .gregorian) -> DateComponents {
        return Calendar(identifier: identifier).dateComponents([.era,
                                                                .year,
                                                                .month,
                                                                .day,
                                                                .hour,
                                                                .minute,
                                                                .second,
                                                                .weekday,
                                                                .weekdayOrdinal,
                                                                .calendar,
                                                                .timeZone],
                                                               from: self)
    }
    
    static func dayCount(_ year: Int, month: Int) -> Int {
        switch month {
        case 2:
            if (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) {
                return 29
            } else {
                return 28
            }
        case 4, 6, 9, 11:
            return 30;
        default:
            return 31;
        }
    }
}
