//
//  LoadDataStateView.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

public enum LoadDataState {
    case none,
    loading,
    empty,
    fail
}

public protocol LoadDataStateDelegate: class {
    func retryLoadData()
}

extension LoadDataStateDelegate {
    func retryLoadData() {
        
    }
}

public class LoadDataStateView: UIView {
    public weak var delegate: LoadDataStateDelegate?
    private var state: LoadDataState = .empty
    var mainView: UIView!
    var imageSize: CGSize!
    var imageView: UIImageView!
    public var text: String?
    var textLabel: UILabel!
    var button: UIButton?
    
    public init(_ state: LoadDataState) {
        super.init(frame: CGRect())
        NotifyDefault.add(self,
                          selector: #selector(contentSizeCategoryDidChange),
                          name: UIContentSizeCategory.didChangeNotification)
        initView(state)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    func initView(_ state: LoadDataState) {
        mainView = UIView()
        addSubview(mainView)
        
        let titleImage: UIImage!
        if state == .none {
            titleImage = UIImage(named: "beauty_face_6")
            imageSize = CGSize(262 / 2.0, 337.0 / 2.0)
            text = "I guess there are something wrong. You should never see me".localized
        } else if state == .loading {
            titleImage = UIImage(named: "beauty_face_1")
            imageSize = CGSize(253.0 / 2.0, 337.0 / 2.0)
            text = "Loading ...".localized
        } else if state == .empty {
            titleImage = UIImage(named: "beauty_face_4")
            imageSize = CGSize(333.0 / 2.0, 337.0 / 2.0)
            text = "No record".localized
        } else {
            titleImage = UIImage(named: "beauty_face_7")
            imageSize = CGSize(369.0 / 2.0, 337.0 / 2.0)
        }
        self.state = state
        
        imageView = UIImageView(image: titleImage)
        mainView.addSubview(imageView)
        
        textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textAlignment = NSTextAlignment.center
        textLabel.textColor = "6".color
        textLabel.font = UIFont.Preferred.body
        mainView.addSubview(textLabel)
        
        if state == .empty || state == .loading {
            return
        }
        
        let title = "Click Retry".localized
        button = Common.submitButton(title)
        let width =
            Common.fitSize(title, font: SubmitButton.font, maxHeight: TableCellHeight).width
        button?.frame = CGRect(0, 0, ceil(width) + 16.0, TableCellHeight)
        button?.clicked(self, action: #selector(clickButton(_:)))
        mainView.addSubview(button!)
        
        isUserInteractionEnabled = true
        mainView.isUserInteractionEnabled = true
    }
    
    //计算需要展示完全的最小高度
    public func minHeight(_ width: CGFloat? = nil) -> CGFloat {
        //图片高度
        let imageHeight = 337.0 / 2.0 as CGFloat
        
        //文字高度
        let textWidth = (width != nil ? width! : ScreenWidth()) - 2 * SubviewMargin
        let textSize = Common.fitSize(text!, font: SubmitButton.font, maxWidth: textWidth)
        let textHeight = ceil(textSize.height)
        
        if state == .empty {
            return imageHeight + 10.0 + textHeight
        }
        
        //按钮高度
        return imageHeight + 10.0 + textHeight + 20.0 + TableCellHeight
    }
    
    public func layout() {
        //计算中间文字的宽度和高度
        var textWidth = self.width - 2 * SubviewMargin
        let textSize = Common.fitSize(text!, font: SubmitButton.font, maxWidth: textWidth)
        let textHeight = ceil(textSize.height)
        if textHeight >= 1.5 * textLabel.font.lineHeight
            && ceil(textSize.width) < textWidth { //多行的话尝试缩小文字宽度并更改文字排版
            textWidth = ceil(textSize.width)
            textLabel.textAlignment = NSTextAlignment.left
        } else {
            textLabel.textAlignment = NSTextAlignment.center
        }
        textLabel.font = UIFont.Preferred.body
        textLabel.text = text
        
        let mainWidth = self.width
        var mainHeight = imageSize.height + 10.0 + textHeight
        if let button = button {
            mainHeight += 20.0 + button.height
        }
        mainView.frame =
            CGRect(0, (self.height - mainHeight) / 2.0, self.width, mainHeight)
        imageView.frame = CGRect((mainWidth - imageSize.width) / 2.0, 0, imageSize)
        
        textLabel.frame = CGRect((mainWidth - textWidth) / 2.0,
                                 imageView.bottom + 10.0,
                                 textWidth,
                                 textHeight)
        
        if let button = button {
            var frame = button.frame
            frame.origin.x = (mainWidth - button.width) / 2.0
            frame.origin.y = textLabel.bottom + 20.0
            button.frame = frame
        }
    }
    
    public func show(_ superview: UIView, text: String?) {
        superview.addSubview(self)
        if state != .none {
            self.text = text
            if let text = self.text, text.count > 100 {
                self.text = text.substring(to: 99)
            }
        }
        frame = superview.bounds
        let width = superview.bounds.width
        let height = max(minHeight(width), superview.bounds.height)
        frame = CGRect(0, (superview.bounds.height - height) / 2.0, width, height)
        layout()
    }
    
    @objc func clickButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        if let delegate = delegate {
            delegate.retryLoadData()
        }
    }
    
    @objc func contentSizeCategoryDidChange() {
        if superview != nil {
            layout()
        }
    }
}

