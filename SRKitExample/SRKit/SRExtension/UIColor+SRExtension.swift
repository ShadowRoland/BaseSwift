//
//  UIColor+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Foundation

public extension UIColor {
    convenience init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) {
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }
    
    convenience init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        self.init(hue: hue / 360.0,
                  saturation: saturation / 360.0,
                  brightness: brightness / 360.0,
                  alpha: 1.0)
    }
    
    convenience init(white: CGFloat) {
        self.init(white: white, alpha: 1.0)
    }
}

public extension UIColor {
    var rgba: [CGFloat] {
        guard let space = cgColor.colorSpace else { return [0, 0, 0, 1.0] }
        
        let spaceModel = space.model
        let count = cgColor.numberOfComponents
        
        switch (spaceModel) {
        case .monochrome:
            if count == 2, let components = cgColor.components {
                return [components[0], components[0], components[0], components[1]]
            }
        
        case .rgb:
            if count == 4, let components = cgColor.components {
                return [components[0], components[1], components[2], components[3]]
            }
        
        default:
            break
        }
        return [0, 0, 0, 1.0]
    }
    
    //图片是否透明
    var isTranslucent: Bool {
        return rgba.last! < 1.0
    }
}
