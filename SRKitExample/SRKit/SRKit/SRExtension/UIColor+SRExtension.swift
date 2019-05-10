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
