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
    
    public var style: SRSimplePromptViewStyle = .default {
        didSet {
            if style != oldValue {
                layout()
            }
        }
    }
    
    lazy var contentView: UIView = {
        let contentView = UIView()
        addSubview(contentView)
        constrain(contentView) {
            $0.center == $0.superview!.center
            $0.top >= $0.superview!.top + margin  ~ .defaultLow
            $0.bottom <= $0.superview!.bottom - margin ~ .defaultLow
            $0.left >= $0.superview!.left + margin ~ .defaultLow
            $0.right <= $0.superview!.right - margin ~ .defaultLow
        }
        return contentView
    }()
    
    var _isTextLabelHidden: Bool = false
    var isTextLabelHidden: Bool {
        if textLabel.isHidden {
            return true
        } else {
            let size = textLabel.intrinsicContentSize
            return size.width == 0 || size.height == 0
        }
    }
    
    lazy public var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textAlignment = NSTextAlignment.center
        textLabel.textColor = UIColor.darkText
        textLabel.font = UIFont.preferred.body
        return textLabel
    }()
    
    var _isImageViewHidden: Bool = false
    var isImageViewHidden: Bool {
        if imageView.isHidden {
            return true
        } else {
            let size = imageView.intrinsicContentSize
            return size.width == 0 || size.height == 0
        }
    }
    lazy public var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    var margin: CGFloat = 15.0
    var padding: CGFloat = 20.0
    
    lazy var button: UIButton =  {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(clickButton(_:)), for: .touchUpInside)
        addSubview(button)
        constrain(button) { $0.edges == inset($0.superview!.edges, 0) }
        return button
    }()
    
    public convenience init(_ text: String?,
                            image: UIImage? = nil,
                            margin: CGFloat = 15.0,
                            padding: CGFloat = 20.0) {
        self.init(frame: CGRect())
        textLabel.text = text
        imageView.image = image
        self.margin = max(0, margin)
        self.padding = max(0, padding)
        layout()
    }
    
    public convenience init() {
        self.init(frame: CGRect())
        layout()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        NotifyDefault.add(self,
                          selector: #selector(contentSizeCategoryDidChange),
                          name: UIContentSizeCategory.didChangeNotification)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    func layout() {
        _isImageViewHidden = isImageViewHidden
        if _isImageViewHidden {
            imageView.isHidden = true
        }
        _isTextLabelHidden = isTextLabelHidden
        if _isTextLabelHidden {
            textLabel.isHidden = true
        }
        
        var centerViews: [UIView] = []
        switch style {
        case .default, .vertically:
            if !imageView.isHidden {
                if !textLabel.isHidden {
                    imageView.removeFromSuperview()
                    contentView.insertSubview(imageView, at: 0)
                    constrain(imageView) {
                        $0.centerX == $0.superview!.centerX
                        $0.top == $0.superview!.top
                        $0.left <= $0.superview!.left //~ .defaultLow
                        $0.right <= $0.superview!.right //~ .defaultLow
                    }
                } else {
                    centerViews.append(imageView)
                }
            }
            
            if !textLabel.isHidden {
                if !imageView.isHidden {
                    textLabel.removeFromSuperview()
                    contentView.addSubview(textLabel)
                    constrain(textLabel, imageView) {
                        $0.centerX == $0.superview!.centerX
                        $0.top == $1.bottom + padding
                        $0.bottom == $0.superview!.bottom
                        $0.left <= $0.superview!.left //~ .defaultLow
                        $0.right <= $0.superview!.right //~ .defaultLow
                    }
                } else {
                    centerViews.append(textLabel)
                }
            }
            
        case .horizontal:
            if !imageView.isHidden {
                if !textLabel.isHidden {
                    imageView.removeFromSuperview()
                    contentView.insertSubview(imageView, at: 0)
                    constrain(imageView) {
                        $0.centerY == $0.superview!.centerY
                        $0.left == $0.superview!.left
                        $0.top <= $0.superview!.top //~ .defaultLow
                        $0.bottom <= $0.superview!.bottom //~ .defaultLow
                    }
                } else {
                    centerViews.append(imageView)
                }
            }
            
            if !textLabel.isHidden {
                if !imageView.isHidden {
                    textLabel.removeFromSuperview()
                    contentView.addSubview(textLabel)
                    constrain(textLabel, imageView) {
                        $0.centerY == $0.superview!.centerY
                        $0.left == $1.right + padding
                        $0.top <= $0.superview!.top //~ .defaultLow
                        $0.bottom <= $0.superview!.bottom //~ .defaultLow
                        $0.right <= $0.superview!.right //~ .defaultLow
                    }
                } else {
                    centerViews.append(textLabel)
                }
            }
            
        case .allCenter:
            if !imageView.isHidden {
                centerViews.append(imageView)
            }
            if !textLabel.isHidden {
                centerViews.append(textLabel)
            }
        }
        
        centerViews.forEach { view in
            view.removeFromSuperview()
            if view === imageView {
                contentView.insertSubview(view, at: 0)
            } else {
                contentView.addSubview(view)
            }
            constrain(view) {
                $0.center == $0.superview!.center
                $0.top <= $0.superview!.top ~ .defaultLow
                $0.bottom <= $0.superview!.bottom ~ .defaultLow
                $0.left <= $0.superview!.left ~ .defaultLow
                $0.right <= $0.superview!.right ~ .defaultLow
            }
        }
        
        bringSubviewToFront(button)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if _isTextLabelHidden != isTextLabelHidden || _isImageViewHidden != isImageViewHidden {
            layout()
        }
    }
    
    @objc func clickButton(_ sender: Any) {
        guard MutexTouch else { return }
        if let delegate = delegate {
            delegate.didClickSimplePromptView(self)
        }
    }
    
    @objc func contentSizeCategoryDidChange() {
        if superview != nil {
            layout()
        }
    }
}

