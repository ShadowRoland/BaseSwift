//
//  ContactCell.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class ContactCell: UITableViewCell {
    var contactType: UserModel.SNSType = .single
    var headPortraitImageView = UIImageView()
    var nameLabel = UILabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        selectionStyle = .default
        
        contentView.addSubview(headPortraitImageView)
        headPortraitImageView.clipsToBounds = true
        contentView.addSubview(nameLabel)
        initFont()
    }
    
    public func initFont() {
        nameLabel.font = UIFont.Preferred.body
    }
    
    //MARK: 视图尺寸参数
    
    static var singleHeadPortraitHeight: CGFloat = 0
    static var officialAccountHeadPortraitHeight: CGFloat = 0
    static var nameHeight: CGFloat = 0
    
    public static let headPortraitMargin: CGFloat = 10.0
    static let singleNameOffset: CGFloat = 10.0 //名字和图片的高度差
    static let officialAccountNameOffset: CGFloat = 20.0 //名字和图片的高度差
    static let nameLeftMargin: CGFloat = headPortraitMargin
    
    public class func height(_ contactType: UserModel.SNSType) -> CGFloat {
        var height: CGFloat = singleHeadPortraitHeight
        if contactType == .officialAccount {
            height = officialAccountHeadPortraitHeight
        }
        return 2.0 * headPortraitMargin + height
    }
    
    //处理根据字体变化而变化的约束
    public class func updateCellHeight() {
        nameHeight = UIFont.Preferred.body.lineHeight
        singleHeadPortraitHeight = nameHeight + singleNameOffset
        officialAccountHeadPortraitHeight = nameHeight + officialAccountNameOffset
    }
    
    //MARK: 视图调整位置
    
    func layoutView() {
        var headPortraitHeight = ContactCell.singleHeadPortraitHeight
        if contactType == .officialAccount {
            headPortraitHeight = ContactCell.officialAccountHeadPortraitHeight
        }
        headPortraitImageView.frame = CGRect(ContactCell.headPortraitMargin,
                                              ContactCell.headPortraitMargin,
                                              headPortraitHeight,
                                              headPortraitHeight)
        if contactType == .single {
            headPortraitImageView.layer.cornerRadius = headPortraitHeight / 2.0
        }
        let x = headPortraitImageView.right + ContactCell.nameLeftMargin
        nameLabel.frame =
            CGRect(x,
                      (ContactCell.height(contactType) - ContactCell.nameHeight) / 2.0,
                      ScreenWidth - x - ContactCell.headPortraitMargin,
                      ContactCell.nameHeight)
    }
    
    //MARK: - 业务处理
    
    public func update(_ model: UserModel) {
        initFont()
        let url = URL(string: NonNull.string(model.headPortrait))
        var headPortrait: UIImage?
        if contactType == .officialAccount {
            headPortrait = Config.Resource.defaultImage(.min)
        } else {
            headPortrait = Config.Resource.defaultHeadPortrait(.min)
        }
        headPortraitImageView.contentMode = .scaleToFill
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: headPortrait,
                                          options: [],
                                          completed:
            { [weak headPortraitImageView] (image, error, cacheType, url) in
                if error != nil {
                    return
                }
                headPortraitImageView?.contentMode = .scaleAspectFit
        })
        
        if !isEmptyString(model.remarkName) {
            nameLabel.text = model.remarkName
        } else if !isEmptyString(model.nickname) {
            nameLabel.text = model.nickname
        } else if !isEmptyString(model.userName) {
            nameLabel.text = model.userName
        } else {
            nameLabel.text = ""
        }
        layoutView()
    }
}
