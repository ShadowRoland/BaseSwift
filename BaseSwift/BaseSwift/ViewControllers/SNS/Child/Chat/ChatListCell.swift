//
//  ChatListCell.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import SDWebImage

class ChatListCell: UITableViewCell {
    var message: MessageModel? {
        didSet {
            initFont()
            let url = URL(string: NonNull.string(message?.headPortrait))
            headerImageView.contentMode = .scaleToFill
            headerImageView.sd_setImage(with: url,
                                        placeholderImage: Configs.Resource.defaultImage(.min),
                                        options: [],
                                        completed:
                { [weak headerImageView] (image, error, cacheType, url) in
                    if error != nil {
                        return
                    }
                    headerImageView?.contentMode = .scaleAspectFit
            })
            badgeNumber = 0
            if let badge = message?.badge {
                badgeNumber = max(min(badge, 99), 0)
            }
            badgeLabel.text = badgeNumber >= 0 ? String(int: badgeNumber) : nil
            titleLabel.text = message?.userName
            descriptionLabel.text = message?.text
            timeLabel.text =
                message?.timestamp != nil ? String(timestamp: TimeInterval((message?.timestamp)!),
                                                format: "MM-dd HH:mm") : nil
            layoutView()
        }
    }
    
    var headerImageView = UIImageView()
    var badgeImageView = UIImageView()
    var badgeLabel = UILabel()
    var badgeNumber = 0
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    var timeLabel = UILabel()
    
    var isPreviewRegistered = false //3d Touch
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    //MARK: - 视图初始化
    
    //MARK: 视图尺寸参数
    
    struct Const {
        static var headerHeight: CGFloat = 0
        static var badgeHeight: CGFloat = 0
        static var titleHeight: CGFloat = 0
        static var timeHeight: CGFloat = 0
        static var descriptionHeight: CGFloat = 0
        
        static let headerMargin: CGFloat = 10.0
        static let badgeMargin: CGFloat = 2.0
        static let titleTopMargin: CGFloat = headerMargin + 5.0
        static let titleBottomMargin: CGFloat = 5.0
        static let titleLeftMargin: CGFloat = titleBottomMargin
        static let descriptionTextColor = UIColor.gray
        static let descriptionBottomMargin: CGFloat = titleTopMargin
        static let timeTextColor = UIColor.gray
        
        static var badgeRoundImage: UIImage?
        static var badgeEllipseImage: UIImage?
    }
    
    func initView() {
        selectionStyle = .default
        contentView.backgroundColor = UIColor.white
        
        contentView.addSubview(headerImageView)
        contentView.addSubview(badgeImageView)
        initBadgeImage()
        badgeImageView.addSubview(badgeLabel)
        badgeLabel.textAlignment = NSTextAlignment.center
        badgeLabel.textColor = UIColor.white
        contentView.addSubview(titleLabel)
        titleLabel.text = EmptyString
        contentView.addSubview(descriptionLabel)
        descriptionLabel.textColor = Const.descriptionTextColor
        descriptionLabel.text = EmptyString
        contentView.addSubview(timeLabel)
        timeLabel.textColor = Const.timeTextColor
        timeLabel.textAlignment = NSTextAlignment.right
        timeLabel.text = EmptyString
        initFont()
    }
    
    public func initFont() {
        badgeLabel.font = UIFont.Preferred.caption2
        titleLabel.font = UIFont.Preferred.body
        descriptionLabel.font = UIFont.Preferred.footnote
        timeLabel.font = UIFont.Preferred.caption1
    }
    
    public class func height() -> CGFloat {
        return Const.titleTopMargin + Const.titleHeight + Const.titleBottomMargin
            + Const.descriptionHeight + Const.descriptionBottomMargin
    }
    
    //处理根据字体变化而变化的约束
    public class func updateCellHeight() {
        Const.titleHeight = UIFont.Preferred.body.lineHeight
        Const.descriptionHeight = UIFont.Preferred.footnote.lineHeight
        Const.timeHeight = UIFont.Preferred.caption1.lineHeight
        Const.headerHeight = ChatListCell.height() - 2 * Const.headerMargin
        Const.badgeHeight = UIFont.Preferred.caption2.lineHeight
    }
    
    func initBadgeImage() {
        guard Const.badgeRoundImage == nil else {
            return
        }
        Const.badgeRoundImage = UIImage.circle("#FF8247".color, radius: 30.0)
        //画圆柱截面
        Const.badgeEllipseImage = UIImage.cylinder("#FF8247".color, size: CGSize(60.0, 40.0))
    }
    
    //MARK: 视图调整位置
    
    func layoutView() {
        headerImageView.frame =
            CGRect(Const.headerMargin, Const.headerMargin, Const.headerHeight, Const.headerHeight)
        var width =
            Common.fitSize(timeLabel.text!, font: timeLabel.font, maxHeight: Const.timeHeight).width
        width = min(ScreenWidth() - headerImageView.right - 3 * Const.headerMargin, ceil(width))
        timeLabel.frame = CGRect(ScreenWidth() - Const.headerMargin - width,
                                 Const.titleTopMargin,
                                 width,
                                 Const.timeHeight)
        width = timeLabel.frame.origin.x - headerImageView.right - 2 * Const.headerMargin
        titleLabel.frame = CGRect(headerImageView.right + Const.headerMargin,
                                  Const.titleTopMargin,
                                  width,
                                  Const.titleHeight)
        width = ScreenWidth() - headerImageView.right - 2 * Const.headerMargin
        descriptionLabel.frame = CGRect(titleLabel.frame.origin.x,
                                        titleLabel.bottom + Const.titleBottomMargin,
                                        width,
                                        Const.descriptionHeight)
        layoutBadge()
    }
    
    func layoutBadge() {
        guard badgeNumber > 0 else {
            badgeImageView.isHidden = true
            return
        }
        
        badgeImageView.isHidden = false
        let height = Const.badgeHeight + 2 * Const.badgeMargin
        var width = height
        if badgeNumber > 9 { //两位数的数字背景使用椭圆
            width *= 1.5
            badgeImageView.image = Const.badgeEllipseImage
        } else {
            badgeImageView.image = Const.badgeRoundImage
        }
        
        //调整位置，使之尽量可以挂在图片的右上角
        var x = headerImageView.right - width / 2.0
        x = min(titleLabel.frame.origin.x - width, x)
        var y = headerImageView.frame.origin.y - height / 2.0
        y = max(0, y)
        badgeImageView.frame = CGRect(x, y, width, height)
        badgeLabel.frame = badgeImageView.bounds
        badgeLabel.text = String(int: badgeNumber)
    }
}
