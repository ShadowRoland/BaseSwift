//
//  JSON+SRExtension.swift
//  SRKit
//
//  Created by Gary on 2019/12/28.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit
import SwiftyJSON

extension JSON {
    ///根据给定的位置做值的替换替换，如positions为：
    ///{"body" :
    ///    { "contact" :
    ///        [
    ///            {
    ///                "phone" : "***",
    ///                "idNo" : "3403*****"
    ///             }
    ///        ]
    ///     }
    ///}
    ///在self的三层位置上的phone和idNo将会被替换为"***"和"3403*****"
    ///具体的做法：
    ///1、遍历positions中value为字符串类型（必须是字符串）的键值对（body和contact的value为字典），记录位置和键值对
    ///2、根据这些键值对的信息先在self中找到相同的位置的
    ///3、在同样的位置上进行key的查找，然后进行value的替换，
    ///   无论self中同样位置同样key对应的值是什么类型（字符串，数值，对象），都会被替换为positions中同样位置同样key对应的value
    ///PS: 数组只遍历第一个成员
    public func replacingOccurrences(positions: JSON) {
        
    }
}
