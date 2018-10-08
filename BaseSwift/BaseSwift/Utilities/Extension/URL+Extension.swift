//
//  UIView+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension URL {
    var queryDictionary: ParamDictionary {
        var params = EmptyParams()
        query?.components(separatedBy: "&").forEach {
            let components = $0.components(separatedBy: "=")
            if let key = components.first?.removingPercentEncoding,
                let value = components.last?.removingPercentEncoding {
                params[key] = value
            }
        }
        return params
    }
    
    func appending(url: URL?) -> URL {
        guard let url = url else {
            return self
        }
        
        return URL(string: absoluteString.appending(urlComponent: url.absoluteString)) ?? self
    }
    
    func appending(string: String?) -> URL {
        guard let string = string else {
            return self
        }
        
        return URL(string: absoluteString.appending(urlComponent: string)) ?? self
    }
}
