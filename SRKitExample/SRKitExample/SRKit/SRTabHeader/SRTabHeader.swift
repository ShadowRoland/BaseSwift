//
//  SRTabHeader.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/29.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

public protocol SRTabHeaderDelegate: class {
    func tabHeader(_ tabHeader: SRTabHeader, didSelect index: Int)
}

extension SRTabHeaderDelegate {
    func tabHeader(_ tabHeader: SRTabHeader, didSelect index: Int) { }
}

open class SRTabHeader: UIView {
    public weak var delegate: SRTabHeaderDelegate?
    public var titles: [String] = [] {
        didSet {
            guard titles != oldValue else {
                return
            }
            
            subviews.forEach { $0.removeFromSuperview() }
            
            var tabItems = [] as [SRTabItem]
            for i in 0 ..< titles.count {
                let tabItem = SRTabItem()
                tabItem.tag = i
                tabItem.selectedTextColor = selectedTextColor
                tabItem.unselectedTextColor = unselectedTextColor
                tabItems.append(tabItem)
                
                let gr = UITapGestureRecognizer(target: self, action: #selector(clickTabItem(_:)))
                tabItem.addGestureRecognizer(gr)
                
                let label = tabItem.titleLabel
                label.font = titleFont
                label.textAlignment = .center
                label.numberOfLines = 0
                
                addSubview(tabItem)
            }
            self.tabItems = tabItems
            
            cursorView.backgroundColor = cursorColor
            addSubview(cursorView)
            
            bottomLineView.backgroundColor = cursorColor
            addSubview(bottomLineView)
        }
    }
    fileprivate var _selectedIndex = 0
    public var selectedIndex: Int { return _selectedIndex }
    public var titleFont = UIFont.boldSystemFont(ofSize: 17) {
        didSet {
            tabItems.forEach { $0.titleLabel.font = titleFont }
        }
    }
    public var cursorColor = UIColor(hue: 224.0 / 360.0,
                                     saturation: 50.0 / 100.0,
                                     brightness: 63.0 / 100.0,
                                     alpha: 1.0) {
        didSet {
            cursorView.backgroundColor = cursorColor
        }
    }
    public var cursorHeight: CGFloat = 3.0
    public var cursorOffset: CGFloat = 10.0 //对标题长出的差值
    
    open var selectedTextColor = UIColor(hue: 224.0 / 360.0,
                                         saturation: 56.0 / 100.0,
                                         brightness: 51.0 / 100.0,
                                         alpha: 1.0)
    {
        didSet {
            tabItems.forEach { $0.selectedTextColor = selectedTextColor }
        }
    }
    open var unselectedTextColor = UIColor.gray {
        didSet {
            tabItems.forEach { $0.unselectedTextColor = unselectedTextColor }
        }
    }
    
    var tabItems: [SRTabItem] = []
    var cursorView = UIView()
    var cursorFrames: [CGRect] = []
    
    private var bottomLineView = UIView()

    open func layout() {
        guard !titles.isEmpty else {
            return
        }
        
        let tabWidth = frame.size.width / CGFloat(titles.count)
        let tabHeight = max(frame.size.height - cursorHeight, 0)
        let labelHeight = max(tabHeight, titleFont.lineHeight)
        var cursorFrames = [] as [CGRect]
        for i in 0 ..< titles.count {
            let title = titles[i]
            let tabItem = tabItems[i]
            tabItem.frame =
                CGRect(x: CGFloat(i) * tabWidth, y: 0, width: tabWidth, height: tabHeight)
            let label = tabItem.titleLabel
            label.text = title
            var labelWidth =
                title.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                height: labelHeight),
                                   options: .calculateTextSize,
                                   attributes: [.font : titleFont],
                                   context: nil).size.width
            labelWidth = min(tabWidth, ceil(labelWidth))
            label.frame =
                CGRect(x: (tabWidth - labelWidth) / 2.0, y: 0, width: labelWidth, height: tabHeight)
            let cursorWidth = min(labelWidth + 2.0 * cursorOffset, tabWidth)
            let cursorFrame = CGRect(x: tabItem.frame.origin.x + ((tabWidth - cursorWidth) / 2.0),
                                     y: tabHeight,
                                     width: cursorWidth,
                                     height: cursorHeight)
            cursorFrames.append(cursorFrame)
        }
        self.cursorFrames = cursorFrames
        bottomLineView.frame =
            CGRect(x: 0, y: frame.size.height - 0.5, width: frame.size.width, height: 0.5)
        activeTab(selectedIndex, animated: false)
    }
    
    open func activeTab(_ index: Int, animated: Bool) {
        guard index >= 0 && index < titles.count else {
            return
        }
        
        (0 ..< titles.count).forEach { tabItems[$0].isSelected = $0 == index }
        if animated {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.cursorView.frame = (self?.cursorFrames[index])!
            }, completion: { [weak self] (finished) in
                self?._selectedIndex = index
            })
        } else {
            cursorView.frame = cursorFrames[index]
            _selectedIndex = index
        }
    }
    
    open func update(_ index: Int, offsetRate: CGFloat) {
        for i in 0 ..< titles.count {
            if i != index || i == titles.count - 1 {
                continue
            }
            let cursorFrame = cursorFrames[i]
            let rightCursorFrame = cursorFrames[i + 1]
            updateCursor(cursorFrame.origin.x
                + (rightCursorFrame.origin.x - cursorFrame.origin.x) * offsetRate,
                         width: cursorFrame.size.width
                            + (rightCursorFrame.size.width - cursorFrame.size.width) * offsetRate)
        }
    }
    
    public func updateCursor(_ x: CGFloat, width: CGFloat) {
        var frame = cursorView.frame
        if x != frame.origin.x || width != frame.size.width {
            frame.origin.x = x
            frame.size.width = width
            cursorView.frame = frame
        }
    }
    
    @objc func clickTabItem(_ gr: UITapGestureRecognizer) {
        let index = (gr.view?.tag)!
        activeTab(index, animated: true)
        _selectedIndex = index
        delegate?.tabHeader(self, didSelect: index)
    }
}
