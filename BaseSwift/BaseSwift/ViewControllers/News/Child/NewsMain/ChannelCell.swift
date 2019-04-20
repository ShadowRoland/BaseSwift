//
//  ChannelCell.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/5.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class ChannelCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    var cellSize = CGSize()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.adjustsFontSizeToFitWidth = true
    }
}
