//
//  SRPopover.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/17.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import DTCoreText
import Popover

public protocol SRPopoverDelegate: NSObjectProtocol {
    func popover(_ popover: SRPopover, didClick text: String?, url: URL?)
}

extension SRPopoverDelegate {
    func popover(_ popover: SRPopover, didClick text: String?, url: URL?) {}
}

public class SRPopover: Popover, DTAttributedTextContentViewDelegate {
    weak var delegate: SRPopoverDelegate?
    
    @discardableResult
    open class func show(_ text: String?,
                         forView: UIView? = nil,
                         delegate: SRPopoverDelegate? = nil) -> SRPopover? {
        guard let text = text, !text.isEmpty else {
            return nil
        }
        return showPopView(htmlText: text.htmlText, forView: forView, delegate: delegate)
    }
    
    @discardableResult
    open class func showPopView(htmlText: String?,
                                forView: UIView? = nil,
                                delegate: SRPopoverDelegate? = nil) -> SRPopover? {
        guard let htmlText = htmlText, !htmlText.isEmpty else {
            return nil
        }
        
        //文字控件的尺寸
        let minTextHeight = LabelHeight
        let popViewMargin = SubviewMargin
        let textMargin = 8.0 as CGFloat
        let labelMarginHorizontal = 2.0 * (popViewMargin + textMargin)
        let arrowHeight = 10.0 as CGFloat //default value of Popover.arrowSize.height
        let labelMarginVertical = labelMarginHorizontal + arrowHeight
        var width = ScreenWidth() - labelMarginHorizontal
        var height = ScreenHeight() - labelMarginVertical
        let label = DTAttributedLabel(frame: CGRect(0, 0, width, height))
        label.attributedString = htmlText.attributedString
        let size = label.intrinsicContentSize()
        width = min(width, size.width)
        height = max(minTextHeight, size.height)
        label.frame = CGRect(0, 0, width, height)
        let contentWidth = width + 2.0 * textMargin
        var contentHeight = min(height + 2.0 * textMargin + arrowHeight,
                                ScreenHeight() - 2.0 * popViewMargin + arrowHeight) //居中时，不需要展示箭头
        
        //定位
        var startPoint: CGPoint? //获取起点
        var type: PopoverType = .down //弹出框位置
        let window = UIApplication.shared.windows.last ?? UIApplication.shared.keyWindow!
        if let forView = forView, let superView = forView.superview {
            let rectInWindow = window.convert(forView.frame, from: superView)
            let displayRect = CGRect(popViewMargin,
                                      0,
                                      ScreenWidth() - 2.0 * popViewMargin,
                                      ScreenHeight())
            let intersection = displayRect.intersection(rectInWindow)
            if !intersection.isEmpty { //视图当前窗口显示全部或部分
                let spaceTop: CGFloat = intersection.origin.y
                let spaceBottom: CGFloat =
                    displayRect.size.height - intersection.origin.y - intersection.size.height
                let minContentHeight = LabelHeight + popViewMargin + 2.0 * textMargin + arrowHeight
                if spaceTop >= minContentHeight || spaceBottom >= minContentHeight { //上下预留的间距满足显示弹出框的尺寸
                    //判断弹出框显示在上面下面
                    if spaceTop >= spaceBottom {
                        type = .up
                    }
                    let space = type == .up ? spaceTop : spaceBottom
                    contentHeight = min(contentHeight, space - popViewMargin - arrowHeight)
                    startPoint =
                        CGPoint(intersection.origin.x + intersection.size.width / 2.0,
                                 type == .up
                                    ? intersection.origin.y
                                    : intersection.origin.y + intersection.size.height)
                }
            }
        }
        
        var options = [] as [PopoverOption]
        options.append(.type(type))
        if startPoint == nil { //居中
            startPoint = CGPoint(ScreenWidth() / 2.0,
                                  (ScreenHeight() - contentHeight + arrowHeight) / 2.0)
            options.append(.arrowSize(CGSize.zero))
        }
        
        //为文字控件添加可以上下滑动的父视图
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.backgroundColor = UIColor.clear
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.frame = CGRect(0, 0, width, contentHeight - 2.0 * textMargin - arrowHeight)
        scrollView.addSubview(label)
        scrollView.contentSize = CGSize(label.width, label.height)
        
        let contentView = UIView(frame: CGRect(0, 0, contentWidth , contentHeight - arrowHeight))
        contentView.backgroundColor = UIColor.clear
        contentView.isUserInteractionEnabled = true
        contentView.addSubview(scrollView)
        scrollView.frame = scrollView.frame.offsetBy(dx: textMargin, dy: textMargin)
        
        let popover = SRPopover(options: options, showHandler: nil, dismissHandler: nil)
        popover.delegate = delegate
        popover.show(contentView, point: startPoint!, inView: window)
        
        return popover
    }
    
    private var dtLinkDic = [:] as [String : Int] // DTLinkButton [linkText : button.tag]
    
    private func dtLinkButtonTag(_ dtLinkText: String) -> Int {
        if let tag = dtLinkDic[dtLinkText] {
            return tag
        }
        
        var tag = 0
        dtLinkDic.forEach { tag = max(tag, $0.value) }
        tag += 1
        dtLinkDic[dtLinkText] = tag
        return tag
    }
    
    //MARK: - DTAttributedTextContentViewDelegate
    
    public func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!,
                                          viewFor string: NSAttributedString!,
                                          frame: CGRect) -> UIView! {
        let attributes = string.attributes(at: 0, effectiveRange: nil)
        let url = attributes[NSAttributedString.Key(DTLinkAttribute)]
        let identifier = attributes[NSAttributedString.Key(DTGUIDAttribute)]
        
        let button = DTLinkButton(frame: frame)
        button.url = url as? URL
        button.minimumHitSize = CGSize(25.0, 25.0) // adjusts it's bounds so that button is always large enough
        button.guid = identifier as? String
        
        // get image with normal link text
        var image = attributedTextContentView.contentImage(withBounds: frame, options: .default)
        button.setImage(image, for: .normal)
        
        // get image for highlighted link text
        image = attributedTextContentView.contentImage(withBounds: frame,
                                                       options: .drawLinksHighlighted)
        button.setImage(image, for: .highlighted)
        
        // use normal push action for opening URL
        button.tag = dtLinkButtonTag(string.string)
        button.addTarget(self, action: #selector(handleDTLinkButtonClick(_:)), for: .touchUpInside)
        
        return button;
    }
    
    @objc fileprivate func handleDTLinkButtonClick(_ sender: Any) {
        let button = sender as? DTLinkButton
        if let string = dtLinkDic.first(where: { $0.value == button?.tag })?.key {
            delegate?.popover(self, didClick: string, url: button?.url)
        }
    }
}
