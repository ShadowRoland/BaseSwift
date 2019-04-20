//
//  FindCell.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/23.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

protocol FindCellDelegate: class {
    func showImage(_ model: MessageModel?, index: Int)
    func showShareWebpage(_ model: MessageModel?)
    func reloadTableView()
}

extension FindCellDelegate {
    func showImage(_ model: MessageModel?, index: Int) { }
    func showShareWebpage(_ model: MessageModel?) { }
    func reloadTableView() { }
}

class FindCell: UITableViewCell {
    weak var delegate: FindCellDelegate?
    var model: MessageModel? {
        didSet {
            let url = URL(string: NonNull.string(model?.headPortrait))
            headPortraitImageView.contentMode = .scaleToFill
            headPortraitImageView.sd_setImage(with: url,
                                              placeholderImage: Configs.Resource.defaultHeadPortrait(.min),
                                              options: [],
                                              completed:
                { [weak headPortraitImageView] (image, error, cacheType, url) in
                    if error != nil {
                        return
                    }
                    headPortraitImageView?.contentMode = .scaleAspectFit
            })
            nameLabel.text = model?.userName
            messageLabel.text = model?.text
            timeLabel.text =
                model?.timestamp != nil ? String(timestamp: TimeInterval((model?.timestamp)!),
                                                   format: "MM-dd HH:mm") : nil
            if let like = model?.like {
                likeLabel.text = isZhHans ? like.tenThousands(2) : like.thousands(2)
            } else {
                likeLabel.text = "0"
            }
            if let comment = model?.comment {
                commentLabel.text = isZhHans ? comment.tenThousands(2) : comment.thousands(2)
            } else {
                commentLabel.text = "0"
            }
            if let liked = model?.liked, liked {
                likeButton.setImage(UIImage(named: "heart_solid_red"), for: .normal)
                likeButton.setImage(UIImage(named: "heart_gray"), for: .highlighted)
            } else {
                likeButton.setImage(UIImage(named: "heart_gray"), for: .normal)
                likeButton.setImage(UIImage(named: "heart_solid_red"), for: .highlighted)
            }
            layout()
        }
    }
    var headPortraitImageView: UIImageView!
    var nameLabel: UILabel!
    var messageLabel: UILabel!
    var messageBottomOriginY = 0 as CGFloat
    
    var imagesView: UIView!
    var images: [UIButton] = []
    
    var shareView: UIView!
    var shareThumbnail: UIImageView!
    var shareLabel: UILabel!
    var shareButton: UIButton!
    
    var timeLabel: UILabel!
    
    var bottomView: UIView!
    var bottomOriginY: CGFloat = 0
    var likeButton: UIButton!
    var likeLabel: UILabel!
    var commentButton: UIButton!
    var commentLabel: UILabel!
    var bottomShareButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    struct Const {
        static let headPortraitSide = 60.0 as CGFloat
        public static let headPortraitMargin = 10.0 as CGFloat
        static let nameHeight = LabelHeight
        static let nameMarginTop = 15.0 as CGFloat
        static let nameMarginBottom = 10.0 as CGFloat
        static let nameMarginRight = 10.0 as CGFloat
        static let nameFont = UIFont.system(16.0)
        static let nameTextColor = UIColor(hue: 6.0, saturation: 74.0, brightness: 91.0)
        static let messageTopOringY = nameHeight + nameMarginTop + nameMarginBottom
        static let messageMarginBottom = nameMarginBottom
        static let messageFont = UIFont.text
        
        static var signalImageSide = 0 as CGFloat
        static let groupImageMaxCount = 9 //图片最大数目为9
        static let groupImageMaxColumn = 3 //图片最多为3列
        static var groupImageSide = 0 as CGFloat
        static let groupImageMargin = 5.0 as CGFloat
        static var imageDefaultRatio = (16.0 / 9.0) as CGFloat
        
        static let shareThumbnailSide = 40.0 as CGFloat
        static let shareThumbnailMargin = 10.0 as CGFloat
        static var shareMaskImage: UIImage? //添加点击效果
        static let shareLabelFont = UIFont.system(14.0)
        
        static let timeWidth = 80.0 as CGFloat
        static let timeFont = UIFont.system(11.0)
        static let timeTextColor = UIColor.gray
        
        static let bottomHeight = 30.0 as CGFloat
        static let bottomWidth = 2.0 * (likeButtonWidth + likeMarginRight) + bottomShareButtonWidth
        static let bottomShareButtonWidth = 30.0 as CGFloat
        static let bottomShareButtonEdgeInsets = UIEdgeInsets(5.0, 0, 10.0, 15.0)
        static let likeMarginRight = 5.0 as CGFloat
        static let likeButtonWidth = 50.0 as CGFloat
        static let likeButtonEdgeInsets = UIEdgeInsets(7.0, 0, 8.0, 35.0)
        static let likeLabelWidth = 30.0 as CGFloat
        static let likeLabelFont = UIFont.system(10.0)
        static let likeLabelTextColor = UIColor(100.0, 50.0, 5.0)
    }
    
    class func updateCellHeight() {
        let width = screenSize().width
        Const.signalImageSide = width * 2.0 / 3.0 //单个图片的最长边长
        Const.groupImageSide = (width
            - (2.0 * Const.headPortraitMargin + Const.headPortraitSide)
            - Const.nameMarginRight
            - 2 * Const.groupImageMargin) / 3.0
        if Const.shareMaskImage == nil {
            Const.shareMaskImage =
                UIImage.rect(MaskBackgroundColor,
                             size: CGSize(width - Const.headPortraitSide - 2.0 * Const.headPortraitMargin,
                                          Const.shareThumbnailSide + 2.0 * Const.shareThumbnailSide))
        }
    }
    
    //根据数据模型以计算所需要的单元高度
    class func cellHeight(_ model: MessageModel,
                          interfaceOrientation: UIInterfaceOrientationMask = .portrait) -> CGFloat {
        let width = screenSize(interfaceOrientation).width - Const.headPortraitSide - 2.0 * Const.headPortraitMargin
            - Const.nameMarginRight
        var cellHeight = Const.messageTopOringY //初始高度从文字上方开始算
        
        if let text = model.text, text != "" {
            //计算文字高度
            let height =
                max(Const.nameHeight, ceil(text.textSize(Const.nameFont, maxWidth: width).height))
            cellHeight += height + Const.messageMarginBottom
        }
        
        switch model.blogType {
        case .image:
            var count = 0
            if let images = model.images, !images.isEmpty {
                count = min(Const.groupImageMaxCount, images.count)
                if count == 1 {
                    cellHeight +=
                        model.singleImageHeight > 0 ? model.singleImageHeight : Const.signalImageSide
                } else {
                    var row = 0
                    if count == 4 {
                        row = 2
                    } else {
                        row = count / Const.groupImageMaxColumn
                        if count % Const.groupImageMaxColumn > 0 {
                            row += 1
                        }
                    }
                    cellHeight += CGFloat(row) * Const.groupImageSide
                        + CGFloat(row - 1) * Const.groupImageMargin
                }
            }
            
        case .share:
            //文字内容宽度
            let shareTextwidth = width - Const.shareThumbnailSide - 3.0 * Const.shareThumbnailMargin
            //计算高度
            let height = max(Const.shareThumbnailSide,
                             ceil((model.shareText ?? "").textSize(Const.shareLabelFont,
                                                                   maxWidth: shareTextwidth).height))
            cellHeight += height + 2.0 * Const.shareThumbnailMargin
            
        default:
            break
        }
        
        cellHeight += Const.bottomHeight
        return cellHeight
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        selectionStyle = .none
        backgroundColor = UIColor.white
        
        headPortraitImageView = UIImageView(frame: CGRect(Const.headPortraitMargin,
                                                          Const.headPortraitMargin,
                                                          Const.headPortraitSide,
                                                          Const.headPortraitSide))
        contentView.addSubview(headPortraitImageView)
        
        var x = headPortraitImageView.right + Const.headPortraitMargin
        nameLabel = UILabel(frame: CGRect(x,
                                          Const.nameMarginTop,
                                          ScreenWidth - x - Const.nameMarginRight,
                                          Const.nameHeight))
        nameLabel.font = Const.nameFont
        nameLabel.textColor = Const.nameTextColor
        contentView.addSubview(nameLabel)
        
        messageLabel =
            UILabel(frame: CGRect(x,
                                  nameLabel.bottom + Const.nameMarginBottom,
                                  nameLabel.width,
                                  Const.nameHeight))
        messageLabel.font = Const.messageFont
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)
        
        let y = messageBottomOriginY
        imagesView = UIView(frame: CGRect(x,
                                          y,
                                          Const.signalImageSide,
                                          Const.signalImageSide))
        imagesView.isUserInteractionEnabled = true
        contentView.addSubview(imagesView)
        
        shareView =
            UIView(frame: CGRect(x,
                                 y,
                                 nameLabel.width,
                                 Const.shareThumbnailSide + 2 * Const.shareThumbnailMargin))
        shareView.backgroundColor = UIColor.groupTableViewBackground
        shareView.isUserInteractionEnabled = true
        contentView.addSubview(shareView)
        shareThumbnail = UIImageView(frame: CGRect(Const.shareThumbnailMargin,
                                                   Const.shareThumbnailMargin,
                                                   Const.shareThumbnailSide,
                                                   Const.shareThumbnailSide))
        shareView.addSubview(shareThumbnail)
        x = shareThumbnail.right + Const.shareThumbnailMargin
        shareLabel = UILabel(frame: CGRect(x,
                                           shareThumbnail.frame.origin.y,
                                           shareView.width - x - Const.shareThumbnailMargin,
                                           shareThumbnail.height))
        shareLabel.font = Const.shareLabelFont
        shareLabel.numberOfLines = 0
        shareView.addSubview(shareLabel)
        shareButton = UIButton(type: .custom)
        shareButton.frame = shareView.bounds
        shareButton.setImage(Const.shareMaskImage!, for: .highlighted)
        shareButton.setImage(Const.shareMaskImage!, for: .selected)
        shareButton.clicked(self, action: #selector(clickShareButton(_:)))
        shareView.addSubview(shareButton)
        
        timeLabel = UILabel(frame: CGRect(nameLabel.frame.origin.x,
                                          bottomOriginY,
                                          Const.timeWidth,
                                          Const.bottomHeight))
        timeLabel.font = Const.timeFont
        timeLabel.textColor = Const.timeTextColor
        timeLabel.text = ""
        contentView.addSubview(timeLabel)
        
        bottomView = UIView(frame: CGRect(ScreenWidth - Const.bottomWidth,
                                          bottomOriginY,
                                          Const.bottomWidth,
                                          Const.bottomHeight))
        contentView.addSubview(bottomView)
        bottomShareButton =
            UIButton(frame: CGRect(Const.bottomWidth - Const.bottomShareButtonWidth,
                                   0,
                                   Const.bottomShareButtonWidth,
                                   Const.bottomHeight))
        bottomShareButton.image = UIImage(named: "share_gray")
        bottomShareButton.contentEdgeInsets = Const.bottomShareButtonEdgeInsets
        bottomShareButton.clicked(self, action: #selector(clickBottomShareButton(_:)))
        bottomView.addSubview(bottomShareButton)
        
        commentButton = UIButton(frame: CGRect(bottomShareButton.frame.origin.x
            - Const.likeButtonWidth - Const.likeMarginRight,
                                               0,
                                               Const.likeButtonWidth,
                                               Const.bottomHeight))
        commentButton.image = UIImage(named: "comment_gray")
        commentButton.contentEdgeInsets = Const.likeButtonEdgeInsets
        commentButton.clicked(self, action: #selector(clickCommentButton(_:)))
        bottomView.addSubview(commentButton)
        commentLabel = UILabel(frame: CGRect(commentButton.right - Const.likeLabelWidth,
                                             0,
                                             Const.likeLabelWidth,
                                             Const.bottomHeight))
        commentLabel.font = Const.likeLabelFont
        commentLabel.textColor = Const.likeLabelTextColor
        commentLabel.adjustsFontSizeToFitWidth = true
        commentLabel.textAlignment = .center
        bottomView.insertSubview(commentLabel, belowSubview: commentButton)
        
        likeButton = UIButton(frame: CGRect(commentButton.frame.origin.x
            - Const.likeButtonWidth - Const.likeMarginRight,
                                            0,
                                            Const.likeButtonWidth,
                                            Const.bottomHeight))
        likeButton.image = UIImage(named: "heart_gray")
        likeButton.setImage(UIImage(named: "heart_solid_red"), for: .highlighted)
        likeButton.contentEdgeInsets = Const.likeButtonEdgeInsets
        likeButton.clicked(self, action: #selector(clickLikeButton(_:)))
        bottomView.addSubview(likeButton)
        likeLabel = UILabel(frame: CGRect(likeButton.right - Const.likeLabelWidth,
                                          0,
                                          Const.likeLabelWidth,
                                          Const.bottomHeight))
        likeLabel.font = Const.likeLabelFont
        likeLabel.textColor = Const.likeLabelTextColor
        likeLabel.adjustsFontSizeToFitWidth = true
        likeLabel.textAlignment = .center
        bottomView.insertSubview(likeLabel, belowSubview: likeButton)
    }
    
    //MARK: - 业务处理
    
    func layout() {
        guard let model = model else { return }
        
        let width = ScreenWidth - nameLabel.frame.origin.x - Const.nameMarginRight
        var frame = nameLabel.frame
        frame.size.width = width
        nameLabel.frame = frame
        
        if let text = messageLabel.text, !text.isEmpty {
            contentView.insertSubview(messageLabel, aboveSubview: nameLabel)
            frame = messageLabel.frame
            frame.size.width = width
            frame.size.height = max(Const.nameHeight,
                                    ceil(text.textSize(messageLabel.font, maxWidth: width).height))
            messageLabel.frame = frame
            messageBottomOriginY = messageLabel.bottom + Const.messageMarginBottom
        } else {
            messageLabel.removeFromSuperview()
            messageBottomOriginY = messageLabel.frame.origin.y
        }
        bottomOriginY = messageBottomOriginY
        
        switch model.blogType {
        case .text:
            imagesView.removeFromSuperview()
            shareView.removeFromSuperview()
            
        case .image:
            layoutImages(width)
            
        case .share:
            layoutShare(width)
            
        default:
            break
        }
        
        frame = timeLabel.frame
        frame.origin.y = bottomOriginY
        timeLabel.frame = frame
        
        frame = bottomView.frame
        frame.origin.x = ScreenWidth - Const.bottomWidth
        frame.origin.y = bottomOriginY
        bottomView.frame = frame
    }
    
    func layoutImages(_ width: CGFloat) {
        guard let model = model else { return }
        
        contentView.insertSubview(imagesView, belowSubview: bottomView)
        shareView.removeFromSuperview()
        var frame = imagesView.frame
        frame.origin.y = messageBottomOriginY
        var count = model.images != nil ? model.images!.count : 0
        count = min(Const.groupImageMaxCount, count)
        let imagesCount = images.count
        if imagesCount < count { //当前imageView的数目不够，需要增加视图
            for i in 0 ..< count - imagesCount {
                let imageButton = UIButton()
                imageButton.tag = imagesCount + i
                //imageButton.imageView?.contentMode = .scaleAspectFill
                imageButton.contentHorizontalAlignment = .fill
                imageButton.contentVerticalAlignment = .fill
                imageButton.clipsToBounds = true
                imageButton.clicked(self, action: #selector(clickImageButton(_:)))
                images.append(imageButton)
            }
        }
        
        //加载图片
        for i in 0 ..< imagesCount {
            if i >= count {
                images[i].image = nil
                images[i].removeFromSuperview()
                continue
            }
            let url = URL(string: model.images![i])
            let imageButton = images[i]
            imageButton.imageView?.contentMode = .scaleToFill
            imageButton.showProgress(.clear,
                                     progressType: .infinite,
                                     progress: nil,
                                     options: [.imageProgressSize : SRProgressHUD.ImageProgressSize.normal])
            weak var weakSelf = self
            imageButton.sd_setImage(with: url,
                                    for: .normal,
                                    placeholderImage: Configs.Resource.defaultImage(imagesCount > 1 ? .min : .normal),
                                    options: [],
                                    completed:
                { [weak imageButton] (image, error, cacheType, url) in
                    imageButton?.progressComponent.dismiss(true)
                    if error != nil {
                        return
                    }
                    if let model = weakSelf?.model,
                        let images = model.images,
                        images.count == 1,
                        model.singleImageHeight == 0,
                        url?.absoluteString == images.first {
                        if let size = image?.size.fitSize(maxSize: CGSize(Const.signalImageSide,
                                                                          Const.signalImageSide)) {
                            weakSelf?.model?.singleImageWidth = size.width
                            weakSelf?.model?.singleImageHeight = size.height
                            weakSelf?.model?.cellHeight = FindCell.cellHeight(model)
                            weakSelf?.model?.cellHeightLandscape =
                                FindCell.cellHeight(model, interfaceOrientation: .landscape)
                            DispatchQueue.main.async {
                                weakSelf?.delegate?.reloadTableView()
                            }
                        }
                    }
                    imageButton?.imageView?.contentMode = .scaleAspectFill
            })
            imagesView.addSubview(imageButton)
        }
        
        //图片布局
        if count == 0 { //无图片
            imagesView.removeFromSuperview()
            return
        } else if count == 1 { //单张图片
            if model.singleImageHeight > 0 {
                frame.size.width = model.singleImageWidth
                frame.size.height = model.singleImageHeight
            } else {
                frame.size.width = Const.signalImageSide
                frame.size.height = Const.signalImageSide
            }
            images[0].frame = CGRect(0, 0, frame.size)
        } else { //多张图片
            var rows = 1
            var columns = 1
            if count == 4 { //4张图片的时候正方排列
                rows = 2
                columns = 2
            } else { //其他按照普世规则排列
                rows = count / Const.groupImageMaxColumn
                if count % Const.groupImageMaxColumn != 0 {
                    rows += 1
                }
                columns = min(Const.groupImageMaxColumn, count)
            }
            let side = Const.groupImageSide
            let margin = Const.groupImageMargin
            for i in 0 ..< count { //调整图片位置
                images[i].frame = CGRect(CGFloat(i % columns) * (side + margin),
                                         CGFloat(i / columns) * (side + margin),
                                         side,
                                         side)
            }
            frame.size.width = CGFloat(columns) * side + CGFloat(columns - 1) * margin
            frame.size.height = CGFloat(rows) * side + CGFloat(rows - 1) * margin
        }
        imagesView.frame = frame
        bottomOriginY = imagesView.bottom
    }
    
    func layoutShare(_ width: CGFloat) {
        guard let model = model else { return }
        
        contentView.insertSubview(shareView, belowSubview: bottomView)
        imagesView.removeFromSuperview()
        
        let url = URL(string: NonNull.string(model.thumbnail))
        shareThumbnail.sd_setImage(with: url, placeholderImage: Configs.Resource.defaultImage(.normal))
        shareLabel.text = model.shareText
        //文字内容宽度
        let shareTextwidth = width - Const.shareThumbnailSide - 3.0 * Const.shareThumbnailMargin
        //计算高度
        let height = max(Const.shareThumbnailSide,
                         ceil((shareLabel.text ?? "").textSize(Const.shareLabelFont,
                                                               maxWidth: shareTextwidth).height))
        
        var frame = shareView.frame
        frame.origin.y = messageBottomOriginY
        frame.size.width = width
        frame.size.height = height + 2.0 * Const.shareThumbnailMargin
        shareView.frame = frame
        
        frame = shareThumbnail.frame
        frame.origin.y = (shareView.height - Const.shareThumbnailSide) / 2.0
        shareThumbnail.frame = frame
        
        frame = shareLabel.frame
        frame.size.width = shareTextwidth
        frame.size.height = height
        shareLabel.frame = frame
        shareButton.frame = shareView.bounds
        bottomOriginY = shareView.bottom
    }
    
    //MARK: - 事件响应
    
    @objc func clickImageButton(_ sender: Any) {
        guard MutexTouch else { return }
        let imageButton = sender as! UIButton
        if let delegate = delegate {
            delegate.showImage(model, index: imageButton.tag)
        }
    }
    
    @objc func clickShareButton(_ sender: Any) {
        guard MutexTouch else { return }
        if let delegate = delegate {
            delegate.showShareWebpage(model)
        }
    }
    
    @objc func clickLikeButton(_ sender: Any) {
        guard MutexTouch else { return }
    }
    
    @objc func clickCommentButton(_ sender: Any) {
        guard MutexTouch else { return }
    }
    
    @objc func clickBottomShareButton(_ sender: Any) {
        guard MutexTouch else { return }
    }
}
