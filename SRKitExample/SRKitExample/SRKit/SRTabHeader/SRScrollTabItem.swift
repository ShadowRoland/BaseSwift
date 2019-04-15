//
//  SRScrollTabItem.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/11.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

public class SRScrollTabItem: SRTabItem {
    var titleScale = 1.0 as CGFloat
    var titleBigScale = 1.3 as CGFloat
    
    override public var isSelected: Bool {
        didSet {
            if oldValue == isSelected {
                return
            }
            
            titleLabel.textColor = isSelected ? selectedTextColor : unselectedTextColor
            if titleBigScale != 1.0 {
                titleScale = isSelected ? titleBigScale : 1.0
                titleLabel.transform = CGAffineTransform(scaleX: titleScale, y: titleScale)
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
