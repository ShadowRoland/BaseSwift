//
//  CollectionHeader.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/6.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class CollectionHeader: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        editButton.layer.borderColor = NavigartionBar.backgroundColor.cgColor
        editButton.layer.borderWidth = 1.0
        editButton.layer.cornerRadius = 5.0
        editButton.clipsToBounds = true
    }
}
