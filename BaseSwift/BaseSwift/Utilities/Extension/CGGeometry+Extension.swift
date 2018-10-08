//
//  CGPoint+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
}

public extension CGSize {
    init(_ width: CGFloat, _ height: CGFloat) {
        self.init(width: width, height: height)
    }
    
    //等比例适配范围
    func fitSize(maxSize: CGSize) ->CGSize {
        guard width > 0 && height > 0 && maxSize.width > 0 && maxSize.height > 0 else {
            return self
        }
        
        var fitSize: CGSize!
        if (max(width, height) <= max(maxSize.width, maxSize.height))
            && (min(width, height) >= min(maxSize.width, maxSize.height)) {
            fitSize = self
        } else {
            let ratio = width / height
            let maxRatio = maxSize.width / maxSize.height
            if width >= height {
                if ratio >= maxRatio { //更扁，优先取宽度，然后再计算高度
                    fitSize = CGSize(maxSize.width, maxSize.width / ratio)
                } else { //更高，优先取高度，然后再计算宽度
                    fitSize = CGSize(maxSize.height * ratio, maxSize.height)
                }
            } else {
                if ratio <= maxRatio { //更瘦，优先取高度，然后再计算宽度
                    fitSize = CGSize(maxSize.height * ratio, maxSize.height)
                } else { //更“胖”，优先取高度，然后再计算宽度
                    fitSize = CGSize(maxSize.width, maxSize.width / ratio)
                }
            }
        }
        
        return fitSize
    }
}

public extension CGRect {
    init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self.init(x: x, y: y, width: width, height: height)
    }
    
    init(_ x: CGFloat, _ y: CGFloat, _ size: CGSize) {
        self.init(x: x, y: y, width: size.width, height: size.height)
    }
}
