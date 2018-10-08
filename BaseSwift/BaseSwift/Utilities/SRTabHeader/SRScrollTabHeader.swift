//
//  SRScrollTabHeader.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/29.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Cartography

public class SRScrollTabHeader: SRTabHeader, UIScrollViewDelegate {
    private var _titles: [String] = []
    override public var titles: [String] {
        get {
            return _titles
        }
        set {
            guard _titles != newValue else {
                return
            }
            _titles = newValue
            
            scrollView.subviews.forEach { $0.removeFromSuperview() }
            
            var tabItems = [] as [SRScrollTabItem]
            var labels = [] as [UILabel]
            for i in 0 ..< _titles.count {
                let tabItem = SRScrollTabItem()
                tabItem.tag = i
                tabItem.selectedTextColor = _selectedTextColor
                tabItem.unselectedTextColor = _unselectedTextColor
                tabItem.titleBigScale = titleBigScale
                tabItems.append(tabItem)
                
                let gr = UITapGestureRecognizer(target: self, action: #selector(clickTabItem(_:)))
                tabItem.addGestureRecognizer(gr)
                
                let label = tabItem.titleLabel
                label.font = titleFont
                label.textAlignment = .center
                label.numberOfLines = 0
                labels.append(label)
                
                scrollView.addSubview(tabItem)
            }
            self.tabItems = tabItems
            
            cursorView.backgroundColor = cursorColor
            scrollView.addSubview(cursorView)
        }
    }
    
    public var titleBigScale = 1.2 as CGFloat //选中时标题放大的比率
    public var firstItemMarginLeft = 10.0 as CGFloat
    public var lastItemMarginRight = 10.0 as CGFloat
    public var labelMarginHorizontal = 10.0 as CGFloat //标题文字两边的间距
    
    fileprivate var _selectedIndex = 0
    override var selectedIndex: Int {
        return _selectedIndex
    }
    fileprivate weak var oldSelectedTabItem: SRScrollTabItem?
    fileprivate weak var selectedTabItem: SRScrollTabItem?
    
    override public var selectedTextColor: UIColor {
        get {
            return _selectedTextColor
        }
        set {
            
        }
    }
    
    public func setSelectedTextColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        selectedTextColorR = r
        selectedTextColorG = g
        selectedTextColorB = b
        _selectedTextColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        tabItems.forEach { $0.selectedTextColor = _selectedTextColor }
    }
    
    private var _selectedTextColor: UIColor!
    private var selectedTextColorR: CGFloat!
    private var selectedTextColorG: CGFloat!
    private var selectedTextColorB: CGFloat!
    
    override public var unselectedTextColor: UIColor {
        get {
            return _unselectedTextColor
        }
        set {
            
        }
    }
    
    public func setUnselectedTextColorR(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        unselectedTextColorR = r
        unselectedTextColorG = g
        unselectedTextColorB = b
        _unselectedTextColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        tabItems.forEach { $0.unselectedTextColor = _unselectedTextColor }
    }
    
    private var _unselectedTextColor: UIColor!
    private var unselectedTextColorR: CGFloat!
    private var unselectedTextColorG: CGFloat!
    private var unselectedTextColorB: CGFloat!
    
    fileprivate var scrollView = UIScrollView()
    
    //内部调整使用的变量
    fileprivate var isSilent = true //scrollView左右滚动和停下时是否会触发事件
    fileprivate var originCursorFrame = CGRect()
    fileprivate var destinationIndex = 0
    fileprivate var destinationX: CGFloat = 0
    fileprivate var scrollViewOffset: CGFloat = 0
    
    public init() {
        super.init(frame: CGRect())
        initView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        titleFont = UIFont.systemFont(ofSize: 16)
        cursorHeight = 2.0
        cursorOffset = 2.0
        setSelectedTextColor(255.0 / 255.0, 50.0 / 255.0, 0)
        setUnselectedTextColorR(30.0 / 255.0, 30.0 / 255.0, 30.0 / 255.0)
        
        isUserInteractionEnabled = true
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        addSubview(scrollView)
        constrain(scrollView) { $0.edges == inset($0.superview!.edges, 0) }
    }
    
    override public func layout() {
        guard titles.count > 0 else {
            return
        }
        
        let tabHeight = max(scrollView.frame.size.height, 0)
        let labelHeight = max(tabHeight, titleFont.lineHeight)
        var lastRight = firstItemMarginLeft
        var cursorFrames = [] as [CGRect]
        for i in 0 ..< titles.count {
            let title = titles[i]
            let tabItem = tabItems[i] as! SRScrollTabItem
            if i == selectedIndex {//必须先复原，否则在屏幕旋转后会发生字体太大使得文字显示为"..."的情况
                tabItem.titleLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            let label = tabItem.titleLabel
            label.text = title
            label.font = titleFont
            let labelWidth =
                ceil(title.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                     height: labelHeight),
                                        options: [.usesLineFragmentOrigin,
                                                  .usesFontLeading,
                                                  .truncatesLastVisibleLine],
                                        attributes: [.font : titleFont],
                                        context: nil).size.width)
            let tabWidth = labelWidth + 2.0 * labelMarginHorizontal
            tabItem.frame = CGRect(x: lastRight, y: 0, width: tabWidth, height: tabHeight)
            label.frame =
                CGRect(x: labelMarginHorizontal, y: 0, width: labelWidth, height: tabHeight)
            let cursorWidth = labelWidth + 2.0 * cursorOffset
            let cursorFrame = CGRect(x: tabItem.frame.origin.x + ((tabWidth - cursorWidth) / 2.0),
                                     y: frame.size.height - cursorHeight,
                                     width: cursorWidth,
                                     height: cursorHeight)
            cursorFrames.append(cursorFrame)
            lastRight = tabItem.frame.origin.x + tabItem.frame.size.width
        }
        self.cursorFrames = cursorFrames
        //scrollView.frame = bounds
        scrollView.contentSize =
            CGSize(width: tabItems.last!.frame.origin.x + tabItems.last!.frame.size.width
                + lastItemMarginRight,
                   height: frame.size.height)
        
        DispatchQueue.main.async { [weak self] in
            self?.activeTab(self?.selectedIndex ?? 0, animated: false)
        }
    }
    
    override public func activeTab(_ index: Int, animated: Bool) {
        guard index >= 0 && index < titles.count else {
            return
        }
        
        //文字大小变化
        oldSelectedTabItem = selectedIndex <= tabItems.count && tabItems[selectedIndex].isSelected
            ? tabItems[selectedIndex] as? SRScrollTabItem
            : nil
        selectedTabItem = tabItems[index] as? SRScrollTabItem
        if oldSelectedTabItem === selectedTabItem {
            oldSelectedTabItem = nil
        }
        
        //将选中的Item移动到中间
        var x = (selectedTabItem?.frame.origin.x)!
            - scrollView.frame.size.width / 2.0 + selectedTabItem!.frame.size.width / 2.0
        x = max(0, x)
        var offsetWidth = scrollView.contentSize.width - scrollView.frame.size.width
        offsetWidth = max(0, offsetWidth)
        x = min(offsetWidth, x)
        if animated {
            if scrollView.contentOffset.x != x {
                originCursorFrame = cursorView.frame
                destinationIndex = index
                destinationX = x
                scrollViewOffset = abs(x - scrollView.contentOffset.x)
                scrollView.isUserInteractionEnabled = false
                isSilent = false
                scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            } else {
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self?.oldSelectedTabItem?.isSelected = false
                    self?.selectedTabItem?.isSelected = true
                    self?.cursorView.frame = (self?.cursorFrames[index])!
                    }, completion: { [weak self] (finished) in
                        self?.oldSelectedTabItem?.isSelected = false
                        self?.selectedTabItem?.isSelected = true
                        self?.cursorView.frame = (self?.cursorFrames[index])!
                        self?._selectedIndex = index
                })
            }
        } else {
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
            oldSelectedTabItem?.isSelected = false
            selectedTabItem?.isSelected = true
            _selectedIndex = index
            //重新变大
            selectedTabItem?.titleLabel.transform =
                CGAffineTransform(scaleX: titleBigScale, y: titleBigScale)
            cursorView.frame = cursorFrames[index]
        }
    }
    
    override public func update(_ index: Int, offsetRate: CGFloat) {
        for i in 0 ..< titles.count {
            let tabItem = tabItems[i] as! SRScrollTabItem
            if i == index {
                transformTitle(tabItem,
                               titleScale: 1.0 + (titleBigScale - 1.0) * (1.0 - offsetRate)) //字体缩小
                if i < titles.count - 1 {
                    let cursorFrame = cursorFrames[i]
                    let rightCursorFrame = cursorFrames[i + 1]
                    updateCursor(cursorFrame.origin.x + (rightCursorFrame.origin.x - cursorFrame.origin.x) * offsetRate,
                                 width: cursorFrame.size.width + (rightCursorFrame.size.width - cursorFrame.size.width) * offsetRate)
                }
            } else if i == index + 1 {
                transformTitle(tabItem, titleScale: 1.0 + (titleBigScale - 1.0) * offsetRate) //字体放大
            } else {
                transformTitle(tabItem, titleScale: 1.0)
            }
        }
    }
    
    func transformTitle(_ item: SRScrollTabItem, titleScale: CGFloat) {
        if titleScale != item.titleScale {
            item.titleScale = titleScale
            item.titleLabel.transform = CGAffineTransform(scaleX: titleScale, y: titleScale)
            //颜色渐变
            let colorRate = (item.titleScale - 1.0) / (item.titleBigScale - 1.0)
            item.titleLabel.textColor =
                UIColor(red: unselectedTextColorR + (selectedTextColorR - unselectedTextColorR) * colorRate,
                        green: unselectedTextColorG + (selectedTextColorG - unselectedTextColorG) * colorRate,
                        blue: unselectedTextColorB + (selectedTextColorB - unselectedTextColorB) * colorRate,
                        alpha: 1.0)
        }
    }
    
    override func clickTabItem(_ gr: UITapGestureRecognizer) {
        let index = (gr.view?.tag)!
        activeTab(index, animated: true)
        delegate?.tabHeader(self, didSelect: index)
    }
    
    //MARK: - UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSilent else {
            return
        }
        
        let offsetRate = 1.0 - abs(scrollView.contentOffset.x - destinationX) / scrollViewOffset
        if let tabItem = oldSelectedTabItem, tabItem.titleScale != 1.0 {
            transformTitle(tabItem,
                           titleScale: 1.0 + (titleBigScale - 1.0) * (1.0 - offsetRate)) //字体缩小
        }
        
        if let tabItem = selectedTabItem, tabItem.titleScale != titleBigScale {
            transformTitle(tabItem, titleScale: 1.0 + (titleBigScale - 1.0) * offsetRate) //字体放大
        }
        
        let cursorFrame = originCursorFrame
        let rightCursorFrame = cursorFrames[destinationIndex]
        if !(cursorFrame.origin.x == rightCursorFrame.origin.x
            && cursorFrame.size.width == rightCursorFrame.size.width) {
            updateCursor(cursorFrame.origin.x + (rightCursorFrame.origin.x - cursorFrame.origin.x) * offsetRate,
                         width: cursorFrame.size.width + (rightCursorFrame.size.width - cursorFrame.size.width) * offsetRate)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
        if !decelerate {
            resetAfterScrollViewDidEndScroll(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    func resetAfterScrollViewDidEndScroll(_ scrollView: UIScrollView) {
        guard !isSilent else {
            return
        }
        
        if let tabItem = oldSelectedTabItem {
            tabItem.isSelected = false
        }
        if let tabItem = selectedTabItem {
            tabItem.isSelected = true
        }
        _selectedIndex = destinationIndex
        cursorView.frame = cursorFrames[_selectedIndex]
        scrollView.isUserInteractionEnabled = true
        isSilent = true
    }
}
