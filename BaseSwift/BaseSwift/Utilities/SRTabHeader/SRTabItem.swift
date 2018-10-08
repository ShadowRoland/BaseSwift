//
//  SRTabItem.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/30.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

open class SRTabItem: UIView {
    public var selectedTextColor = UIColor.blue
    public var unselectedTextColor = UIColor.gray {
        didSet {
            titleLabel.textColor = unselectedTextColor
        }
    }
    
    public var isSelected = false {
        didSet {
            if oldValue == isSelected {
                return
            }
            
            titleLabel.textColor = isSelected ? selectedTextColor : unselectedTextColor
        }
    }
    public var titleLabel = UILabel()
    
    init() {
        super.init(frame: CGRect())
        addSubview(titleLabel)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
