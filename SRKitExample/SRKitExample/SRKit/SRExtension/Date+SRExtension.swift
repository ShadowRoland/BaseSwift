//
//  Date+SRExtension.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/11.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON

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
            if (year.isMultiple(of: 400) || (year.isMultiple(of: 4) && !year.isMultiple(of: 100))) {
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

public extension Date {
    static func dataFromJsonObject(_ jsonObject: Any?) -> Data? {
        guard let jsonObject = jsonObject else { return nil }
        
        var data: Data?
        do {
            //try data = JSONSerialization.data(withJSONObject: jsonObject,
            //                                  options: .prettyPrinted)
            try data = JSON(jsonObject).rawData()
        } catch {
            LogError(String(format: "JSON object to data by SwiftyJSON failed! \nError: %@\nJSON object: %@",
                            error.localizedDescription,
                            jsonObject as? CVarArg ?? ""))
            return nil
        }
        
        return data
    }
}
