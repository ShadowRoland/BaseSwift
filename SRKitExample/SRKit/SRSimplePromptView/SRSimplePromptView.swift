//
//  SRSimplePromptView.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Foundation
import Cartography

public enum SRSimplePromptViewStyle {
    case `default`
    case vertically /// 图片文字垂直分离
    case horizontal /// 图片文字水平分离
    case allCenter /// 图片文字均居中，文字覆盖在图片上面
}

public protocol SRSimplePromptDelegate: class {
    func didClickSimplePromptView(_ view: SRSimplePromptView)
}

extension SRSimplePromptDelegate {
    func didClickSimplePromptView(_ view: SRSimplePromptView) { }
}

public class SRSimplePromptView: UIView {
    public weak var delegate: SRSimplePromptDelegate?
    
    private var needRelayout = true
    private var lastLayoutSize = CGSize()

    public var style: SRSimplePromptViewStyle = .default {
        didSet {
            if style != oldValue {
                needRelayout = true
                setNeedsLayout()
            }
        }
    }
    
    public var text: String? {
        return textLabel.text
    }
    
    public var font: UIFont! {
        get {
            return textLabel.font
        }
        set {
            textLabel.font = newValue
            needRelayout = true
            setNeedsLayout()
        }
    }
    
    public var textColor: UIColor! {
        get {
            return textLabel.textColor
        }
        set {
            textLabel.textColor = newValue
            setNeedsLayout()
        }
    }
    
    public var image: UIImage? {
        return imageView.image
    }
    
    public var insets: UIEdgeInsets = UIEdgeInsets(20.0, 15.0) {
        didSet {
            needRelayout = true
            setNeedsLayout()
        }
    }
    
    public var padding: CGFloat = 20.0 {
        didSet {
            needRelayout = true
            setNeedsLayout()
        }
    }
    
    private var isTextLabelHidden: Bool {
        if let text = textLabel.text, text.count > 0 {
            return false
        } else {
            return true
        }
    }
    
    lazy private var textLabel: UILabel = {
        let textLabel = UILabel()
        addSubview(textLabel)
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = .darkText
        textLabel.font = UIFont.preferred.body
        return textLabel
    }()
    
    private var isImageViewHidden: Bool {
        if let image = imageView.image, image.size.width > 0 && image.size.height > 0 {
            return false
        } else {
            return true
        }
    }
    
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        addSubview(imageView)
        return imageView
    }()
    
    public convenience init(_ text: String?,
                            image: UIImage? = nil,
                            width: CGFloat? = nil,
                            insets: UIEdgeInsets = UIEdgeInsets(20.0, 15.0),
                            padding: CGFloat = 20.0) {
        self.init(frame: CGRect(0, 0, width ?? 0, 0))
        textLabel.text = text
        imageView.image = image
        self.insets = insets
        self.padding = max(0, padding)
    }
    
    public convenience init() {
        self.init(frame: CGRect())
        contentMode = .redraw
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickSelf(_:))))
        NotifyDefault.add(self,
                          selector: #selector(contentSizeCategoryDidChange),
                          name: UIContentSizeCategory.didChangeNotification)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        #endif
        NotifyDefault.remove(self)
    }
    
    public override func layoutSubviews() {
        guard needRelayout || frame.size != lastLayoutSize else {
            return
        }
        
        needRelayout = false
        lastLayoutSize = frame.size
        
        imageView.isHidden = isImageViewHidden
        textLabel.isHidden = isTextLabelHidden
        
        if imageView.isHidden && textLabel.isHidden {
            return
        }
        
        let contentSize = sizeThatFits(frame.size)
        
        switch style {
        case .default, .vertically:
            if !imageView.isHidden {
                let imageSize = imageView.image!.size
                if !textLabel.isHidden {
                    textLabel.textAlignment = .center
                    imageView.frame = CGRect((frame.width - imageSize.width) / 2.0,
                                             (frame.height - contentSize.height) / 2.0 + insets.top,
                                             imageSize.width,
                                             imageSize.height)
                    textLabel.frame = CGRect((frame.width - textSize.width) / 2.0,
                                             imageView.frame.maxY + padding,
                                             textSize.width,
                                             textSize.height)
                    insertSubview(textLabel, aboveSubview: imageView)
                } else {
                    imageView.frame = CGRect((frame.width - imageSize.width) / 2.0,
                                             (frame.height - imageSize.height) / 2.0,
                                             imageSize.width,
                                             imageSize.height)
                }
            } else {
                textLabel.textAlignment = .center
                textLabel.frame = CGRect((frame.width - textSize.width) / 2.0,
                                         (frame.height - textSize.height) / 2.0,
                                         textSize.width,
                                         textSize.height)
            }
            
        case .horizontal:
            if !imageView.isHidden {
                let imageSize = imageView.image!.size
                if !textLabel.isHidden {
                    textLabel.textAlignment = .left
                    imageView.frame = CGRect((frame.width - contentSize.width) / 2.0 + insets.left,
                                             (frame.height - imageSize.height) / 2.0,
                                             imageSize.width,
                                             imageSize.height)
                    textLabel.frame = CGRect(imageView.frame.maxX + padding,
                                             (frame.height - textSize.height) / 2.0,
                                             textSize.width,
                                             textSize.height)
                    insertSubview(textLabel, aboveSubview: imageView)
                } else {
                    imageView.frame = CGRect((frame.width - imageSize.width) / 2.0,
                                             (frame.height - imageSize.height) / 2.0,
                                             imageSize.width,
                                             imageSize.height)
                }
            } else {
                textLabel.textAlignment = .center
                textLabel.frame = CGRect((frame.width - textSize.width) / 2.0,
                                         (frame.height - textSize.height) / 2.0,
                                         textSize.width,
                                         textSize.height)
            }
            
        case .allCenter:
            if !imageView.isHidden {
                let imageSize = imageView.image!.size
                imageView.frame = CGRect((frame.width - imageSize.width) / 2.0,
                                         (frame.height - imageSize.height) / 2.0,
                                         imageSize.width,
                                         imageSize.height)
            }
            if !textLabel.isHidden {
                textLabel.textAlignment = .center
                textLabel.frame = CGRect((frame.width - textSize.width) / 2.0,
                                         (frame.height - textSize.height) / 2.0,
                                         textSize.width,
                                         textSize.height)
                insertSubview(textLabel, aboveSubview: imageView)
            }
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        return sizeThatFits(frame.size)
    }
    
    private var textSize = CGSize()
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let willWidth = size.width
        let imageViewHidden = isImageViewHidden
        let textLabelHidden = isTextLabelHidden
        if imageViewHidden && textLabelHidden {
            return CGSize()
        }
        
        switch style {
        case .default, .vertically:
            if !imageViewHidden {
                let imageSize = imageView.image!.size
                if !textLabelHidden {
                    var width = max(willWidth - insets.left - insets.right, imageSize.width)
                    let textSize = textLabel.text!.textSize(textLabel.font, maxWidth: width)
                    let textWidth = ceil(textSize.width)
                    let textHeight = ceil(textSize.height)
                    self.textSize = CGSize(textWidth, textHeight)
                    width = textWidth < imageSize.width ? imageSize.width : width
                    return CGSize(width + insets.left + insets.right,
                                  imageSize.height + textHeight + insets.top + insets.bottom + padding)
                } else {
                    return CGSize(imageSize.width + insets.left + insets.right,
                                  imageSize.height + insets.top + insets.bottom)
                }
            } else {
                var width = willWidth - insets.left - insets.right
                width = width <= 0 ? .greatestFiniteMagnitude : width
                let textSize = textLabel.text!.textSize(textLabel.font, maxWidth: width)
                let textWidth = ceil(textSize.width)
                let textHeight = ceil(textSize.height)
                self.textSize = CGSize(textWidth, textHeight)
                return CGSize(textWidth + insets.left + insets.right,
                              textHeight + insets.top + insets.bottom)
            }
            
        case .horizontal:
            if !imageViewHidden {
                let imageSize = imageView.image!.size
                if !textLabelHidden {
                    var width = willWidth - insets.left - insets.right - imageSize.width - padding
                    width = width <= 0 ? .greatestFiniteMagnitude : width
                    let textSize = textLabel.text!.textSize(textLabel.font, maxWidth: width)
                    let textWidth = ceil(textSize.width)
                    let textHeight = ceil(textSize.height)
                    self.textSize = CGSize(textWidth, textHeight)
                    let height = textHeight <= imageSize.height ? imageSize.height : textHeight
                    return CGSize(imageSize.width + textWidth + insets.left + insets.right + padding,
                                  height + textHeight + insets.top + insets.bottom)
                } else {
                    return CGSize(imageSize.width + insets.left + insets.right,
                                  imageSize.height + insets.top + insets.bottom)
                }
            } else {
                var width = willWidth - insets.left - insets.right
                width = width <= 0 ? .greatestFiniteMagnitude : width
                let textSize = textLabel.text!.textSize(textLabel.font, maxWidth: width)
                let textWidth = ceil(textSize.width)
                let textHeight = ceil(textSize.height)
                self.textSize = CGSize(textWidth, textHeight)
                return CGSize(textWidth + insets.left + insets.right,
                              textHeight + insets.top + insets.bottom)
            }
            
        case .allCenter:
            let imageSize = !imageViewHidden ? imageView.image!.size : CGSize()
            if !textLabelHidden {
                var width = willWidth - insets.left - insets.right
                width = width <= 0 ? .greatestFiniteMagnitude : width
                let textSize = textLabel.text!.textSize(textLabel.font, maxWidth: width)
                let textWidth = ceil(textSize.width)
                let textHeight = ceil(textSize.height)
                self.textSize = CGSize(textWidth, textHeight)
                return CGSize(max(imageSize.width, textWidth) + insets.left + insets.right,
                              max(imageSize.height, textHeight) + insets.top + insets.bottom)
            } else {
                return imageSize
            }
        }
    }
    
    @objc func clickSelf(_ sender: Any) {
        guard MutexTouch else { return }
        if let delegate = delegate {
            delegate.didClickSimplePromptView(self)
        }
    }
    
    @objc func contentSizeCategoryDidChange() {
        if superview != nil {
//            needRedraw = true
            setNeedsLayout()
        }
    }
}

