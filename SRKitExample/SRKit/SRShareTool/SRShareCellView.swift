//
//  SRShareCellView.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/13.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class SRShareCellView: UIView {
    
    struct Const {
        static let labelMarginTop = 8.0 as CGFloat
    }
    
    var button = UIButton()
    var label = UILabel()
    var type: SRShareTool.CellType!
    
    init(type: SRShareTool.CellType!) {
        super.init(frame: CGRect())
        self.type = type
        button.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.tag = Int(type.rawValue)
        initView()
    }
    
    private init() {
        super.init(frame: CGRect())
        initView()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
        addSubview(button)
        addSubview(label)
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = .darkGray
        label.textAlignment = .center
    }
    
    func layout(frame: CGRect!, image: UIImage?, title: String?) {
        self.frame = frame
        let buttonSide = frame.width
        button.frame = CGRect(0, 0, buttonSide, buttonSide)
        button.image = image
        
        let originY = button.frame.minY + button.frame.height + Const.labelMarginTop
        label.frame = CGRect(0, originY, buttonSide, label.frame.height)
        if label.text != title {
            var height = frame.height - originY
            label.text = title
            label.sizeToFit()
            height = min(height, label.frame.height)
            label.frame = CGRect(CGFloat(0), originY, buttonSide, height)
        }
    }
}
