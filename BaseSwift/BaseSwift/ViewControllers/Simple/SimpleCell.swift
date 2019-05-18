//
//  SimpleCell.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/2.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class SimpleCell: UITableViewCell {
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    struct Const {
        static let height = 70.0 as CGFloat
        static let headerImageWidthShowing = 80.0 as CGFloat
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
    
    public func update(_ dictionary: ParamDictionary) {
        let image = NonNull.string(dictionary[Param.Key.image])
        if isEmptyString(image)
            || (Config.shared.isOnlyShowImageInWLAN
                && HttpManager.shared.networkStatus != .reachable(.ethernetOrWiFi)) { //服务器没返回图片或者只在WILAN下显示图片设置已打开并且当前网络状态在非WILAN下
            headerImageWidthConstraint.constant = 0
        } else {
            headerImageWidthConstraint.constant = Const.headerImageWidthShowing
            headerImageView.sd_setImage(with: URL(string: image),
                                        placeholderImage: Config.Resource.defaultImage(.min))
        }
        titleLabel.attributedText = NSAttributedString(string: NonNull.string(dictionary[Param.Key.title]))
        var string: String?
        if let date = dictionary[Param.Key.date] as? String, !date.isEmpty {
            string = date
        }
        if let source = dictionary[Param.Key.source] as? String, !source.isEmpty {
            string = string! + " " + source
        }
        sourceLabel.text = string
        let comment = NonNull.number(dictionary[Param.Key.comment]).intValue
        commentLabel.text = isZhHans ? comment.tenThousands(2) : comment.thousands(2)
    }
}
