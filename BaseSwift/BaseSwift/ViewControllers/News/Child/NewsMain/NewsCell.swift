//
//  NewsCell.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/2.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class NewsCell: UITableViewCell {
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var isPreviewRegistered = false //3d Touch
    
    struct Const {
        static let height = 70.0 as CGFloat
        static let headerImageWidthShowing = 80.0 as CGFloat
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.backgroundColor = UIColor.white
        sourceLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = nil
        sourceLabel.text = nil
        commentLabel.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - 业务处理
    
    public func update(_ model: SinaNewsModel) {
        let image = NonNull.string(model.image)
        //服务器没返回图片或者只在WILAN下显示图片设置已打开并且当前网络状态在非WILAN下
        if Common.isEmptyString(image)
            || (isOnlyShowImageInWLAN && CommonShare.networkStatus != .reachable(.ethernetOrWiFi)) {
            headerImageWidthConstraint.constant = 0
            playImageView.isHidden = true
        } else {
            headerImageWidthConstraint.constant = Const.headerImageWidthShowing
            headerImageView.sd_setImage(with: URL(string: image),
                                        placeholderImage: Configs.Resource.defaultImage(.min))
            playImageView.isHidden = model.mediaType != .video
        }
        titleLabel.attributedText = NSAttributedString(string: NonNull.string(model.title))
        var source: String?
        if !Common.isEmptyString(model.date) {
            source = model.date
        }
        if !Common.isEmptyString(model.source) {
            source = source != nil ? source! + " " + model.source! : model.source
        }
        sourceLabel.text = source
        let comment = NonNull.number(model.comment).intValue
        commentLabel.text = isZhHans ? comment.tenThousands(2) : comment.thousands(2)
    }
}
