//
//  SRNavigationBar.swift
//  SRKit
//
//  Created by Gary on 2019/5/13.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit
import Cartography

open class SRNavigationBar: UINavigationBar {
    public init() {
        super.init(frame: CGRect())
        super.isTranslucent = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Override super properties and functions
    
    fileprivate var _barStyle: UIBarStyle = .default
    open override var barStyle: UIBarStyle {
        get {
            return _barStyle
        }
        set {
            _barStyle = newValue
        }
    }
    
    fileprivate var _isTranslucent: Bool = true
    @available(iOS 3.0, *)
    open override var isTranslucent: Bool {
        get {
            return _isTranslucent
        }
        set {
            _isTranslucent = newValue
        }
    }
    
    // Pushing a navigation item displays the item's title in the center of the navigation bar.
    // The previous top navigation item (if it exists) is displayed as a "back" button on the left.
    open override func pushItem(_ item: UINavigationItem, animated: Bool) {
        if let item = item as? SRNavigationItem {
            srNavigationItem = item
        }
    }
    
    open override func popItem(animated: Bool) -> UINavigationItem? {
        return nil
    }
    
    
    open override var topItem: UINavigationItem? {
        return nil
    }
    
    open override var backItem: UINavigationItem? {
        return nil
    }
    
    fileprivate var _items: [UINavigationItem]? = nil
    open override var items: [UINavigationItem]? {
        get {
            return _items
        }
        set {
            _items = newValue
        }
    }
    
    open override func setItems(_ items: [UINavigationItem]?, animated: Bool) {
        
    }
    
    /// When set to YES, the navigation bar will use a larger out-of-line title view when requested by the current navigation item. To specify when the large out-of-line title view appears, see UINavigationItem.largeTitleDisplayMode. Defaults to NO.
    @available(iOS 11.0, *)
    open override var prefersLargeTitles: Bool {
        get {
            return false
        }
        set {
            
        }
    }
    
    
    /*
     The behavior of tintColor for bars has changed on iOS 7.0. It no longer affects the bar's background
     and behaves as described for the tintColor property added to UIView.
     To tint the bar's background, please use -barTintColor.
     */
    fileprivate var _tintColor: UIColor = UIColor.black
    open override var tintColor: UIColor! {
        get {
            return _tintColor
        }
        set {
            _tintColor = newValue
        }
    }
    
    fileprivate var _barTintColor: UIColor? = nil
    @available(iOS 7.0, *)
    open override var barTintColor: UIColor? {// default is nil
        get {
            return _barTintColor
        }
        set {
            _barTintColor = newValue
        }
    }
    
    
    /* In general, you should specify a value for the normal state to be used by other states which don't have a custom value set.
     
     Similarly, when a property is dependent on the bar metrics (on the iPhone in landscape orientation, bars have a different height from standard), be sure to specify a value for UIBarMetricsDefault.
     */
    
    @available(iOS 7.0, *)
    open override func setBackgroundImage(_ backgroundImage: UIImage?, for barPosition: UIBarPosition, barMetrics: UIBarMetrics) {
        setBackgroundImage(backgroundImage, for: barMetrics)
    }
    
    @available(iOS 7.0, *)
    open override func backgroundImage(for barPosition: UIBarPosition, barMetrics: UIBarMetrics) -> UIImage? {
        return backgroundImage(for: barMetrics)
    }
    
    
    /*
     Same as using UIBarPositionAny in -setBackgroundImage:forBarPosition:barMetrics. Resizable images will be stretched
     vertically if necessary when the navigation bar is in the position UIBarPositionTopAttached.
     */
    @available(iOS 5.0, *)
    open override func setBackgroundImage(_ backgroundImage: UIImage?, for barMetrics: UIBarMetrics) {
        if let image = backgroundImage {
            srBackgroundImageDictionary[barMetrics] = image
        } else {
            srBackgroundImageDictionary.removeValue(forKey: barMetrics)
        }
    }
    
    @available(iOS 5.0, *)
    open override func backgroundImage(for barMetrics: UIBarMetrics) -> UIImage? {
        return srBackgroundImageDictionary[barMetrics]
    }
    
    
    /* Default is nil. When non-nil, a custom shadow image to show instead of the default shadow image. For a custom shadow to be shown, a custom background image must also be set with -setBackgroundImage:forBarMetrics: (if the default background image is used, the default shadow image will be used).
     */
    fileprivate var _shadowImage: UIImage? = nil
    @available(iOS 6.0, *)
    open override var shadowImage: UIImage? {
        get {
            return _shadowImage
        }
        set {
            _shadowImage = newValue
            super.shadowImage = _shadowImage
        }
    }
    
    
    /* You may specify the font, text color, and shadow properties for the title in the text attributes dictionary, using the keys found in NSAttributedString.h.
     */
    fileprivate var _titleTextAttributes: [NSAttributedString.Key : Any]? = nil
    @available(iOS 5.0, *)
    open override var titleTextAttributes: [NSAttributedString.Key : Any]? {
        get {
            return _titleTextAttributes
        }
        set {
            _titleTextAttributes = newValue
        }
    }
    
    
    /* You may specify the font, text color, and shadow properties for the large title in the text attributes dictionary, using the keys found in NSAttributedString.h.
     */
    fileprivate var _largeTitleTextAttributes: [NSAttributedString.Key : Any]? = nil
    @available(iOS 11.0, *)
    open override var largeTitleTextAttributes: [NSAttributedString.Key : Any]? {
        get {
            return _largeTitleTextAttributes
        }
        set {
            _largeTitleTextAttributes = newValue
        }
    }
    
    
    @available(iOS 5.0, *)
    open override func setTitleVerticalPositionAdjustment(_ adjustment: CGFloat, for barMetrics: UIBarMetrics) {
        
    }
    
    @available(iOS 5.0, *)
    open override func titleVerticalPositionAdjustment(for barMetrics: UIBarMetrics) -> CGFloat {
        return 0
    }
    
    
    /*
     The back indicator image is shown beside the back button.
     The back indicator transition mask image is used as a mask for content during push and pop transitions
     Note: These properties must both be set if you want to customize the back indicator image.
     */
    fileprivate var _backIndicatorImage: UIImage? = nil
    @available(iOS 7.0, *)
    open override var backIndicatorImage: UIImage? {
        get {
            return _backIndicatorImage
        }
        set {
            _backIndicatorImage = newValue
        }
    }
    
    fileprivate var _backIndicatorTransitionMaskImage: UIImage? = nil
    @available(iOS 7.0, *)
    open override var backIndicatorTransitionMaskImage: UIImage? {
        get {
            return _backIndicatorTransitionMaskImage
        }
        set {
            _backIndicatorTransitionMaskImage = newValue
        }
    }
    
    open override func draw(_ rect: CGRect) {
        
    }
    
    open override func didAddSubview(_ subview: UIView) {
        
    }
    
    open override func layoutSubviews() {
        subviews.forEach { $0.isHidden = $0 !== srNavigationBarView }
        layoutSRNavigationBarView()
    }
    
    //MARK: Customize
    
    public struct Const {
        static var contentPadding = 8.0 as CGFloat
    }
    
    open var srNavigationItem: SRNavigationItem?
    var srBackgroundImageDictionary = [:] as [UIBarMetrics : UIImage]
    
    open lazy var srNavigationBarView: UIView = {
       let view = UIView()
        addSubview(view)
        constrain(view) {
            $0.edges == inset($0.superview!.edges, 0)
        }
        return view
    }()
    open lazy var srBackgroundView: UIView = {
        let view = UIView()
        srNavigationBarView.addSubview(view)
        constrain(view) {
            $0.edges == inset($0.superview!.edges, 0)
        }
        return view
    }()
    open lazy var srBackgroundImageView: UIImageView = {
        let imageView = UIImageView()
        srBackgroundView.addSubview(imageView)
        constrain(imageView) {
            $0.edges == inset($0.superview!.edges, 0)
        }
        return imageView
    }()
    open lazy var srContentView: UIView = {
        let view = UIView()
        srNavigationBarView.addSubview(view)
        constrain(view) {
            $0.edges == inset($0.superview!.edges, 0)
        }
        return view
    }()
    open lazy var srTitleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        srContentView.addSubview(label)
        return label
    }()
    
    open func layoutSRNavigationBarView() {
        print("layoutSRNavigationBarView")
        // Layout background
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var image: UIImage? = nil
        if statusBarOrientation.isPortrait,
            let defaultImage = srBackgroundImageDictionary[.default] {
            image = defaultImage
        } else if let compactImage = srBackgroundImageDictionary[.compact] {
            image = compactImage
        }
        if let image = image {
            srBackgroundView.backgroundColor = nil
            srBackgroundImageView.image = image
            srBackgroundImageView.isHidden = false
        } else {
            srBackgroundImageView.isHidden = true
            if barTintColor != nil {
                srBackgroundView.backgroundColor = barTintColor
            } else {
                switch barStyle {
                case .black, .blackTranslucent:
                    srBackgroundView.backgroundColor = UIColor.black
                default:
                    srBackgroundView.backgroundColor = UIColor.white
                }
            }
        }
        
        // Layout left items
        srNavigationBarView.bringSubviewToFront(srContentView)
        srContentView.subviews.forEach { $0.removeFromSuperview() }
        var leftWidth = SRNavigationBar.Const.contentPadding
        var leftPrevious: UIView! = nil
        if let items = srNavigationItem?.leftBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                if let customView = items[index].customView {
                    srContentView.addSubview(customView)
                    if leftPrevious == nil {
                        constrain(customView) {
                            $0.leading == $0.superview!.leading + SRNavigationBar.Const.contentPadding
                            $0.top == $0.superview!.top
                            $0.bottom == $0.superview!.bottom
                        }
                    } else {
                        constrain(customView, leftPrevious) {
                            $0.leading == $1.trailing
                            $0.top == $0.superview!.top
                            $0.bottom == $0.superview!.bottom
                        }
                    }
                    
                    var width = customView.intrinsicContentSize.width
                    if width == 0 {
                        width = customView.width
                        constrain(customView) {
                            $0.width == width
                        }
                    }
                    
                    leftWidth += width
                    leftPrevious = customView
                }
            }
        }
        
        // Layout right items
        var rightWidth = SRNavigationBar.Const.contentPadding
        var rightPrevious: UIView! = nil
        if let items = srNavigationItem?.rightBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                if let customView = items[count - 1 - index].customView {
                    srContentView.addSubview(customView)
//                    if rightPrevious == nil {
//                        constrain(customView) {
//                            $0.trailing == $0.superview!.trailing - SRNavigationBar.Const.contentPadding
//                            $0.top == $0.superview!.top
//                            $0.bottom == $0.superview!.bottom
//                        }
//                    } else {
//                        constrain(customView, rightPrevious) {
//                            $0.trailing == $1.leading
//                            $0.top == $0.superview!.top
//                            $0.bottom == $0.superview!.bottom
//                        }
//                    }
                    
                    var width = customView.intrinsicContentSize.width
                    if width == 0 {
                        width = customView.width
//                        constrain(customView) {
//                            $0.width == width
//                        }
                    }
                    
                    customView.frame = CGRect(0, 0, width, NavigationBarHeight)
                    
                    rightWidth += width
                    rightPrevious = customView
                }
            }
        }
        
        // Layout titleView
        var titleView: UIView!
        if let view = srNavigationItem?.titleView {
            titleView = view
            srTitleLabel.isHidden = true
        } else {
            titleView = srTitleLabel
            srTitleLabel.isHidden = false
            if let title = srNavigationItem?.title, !title.isEmpty {
                if let attributes = _titleTextAttributes, !attributes.isEmpty {
                    srTitleLabel.textColor = _barTintColor
                    srTitleLabel.attributedText = NSAttributedString.init(string: title,
                                                                          attributes: attributes)
                } else {
                    srTitleLabel.textColor = _barTintColor
                    srTitleLabel.text = title
                }
            } else {
                srTitleLabel.text = nil
            }
        }
        
        srContentView.addSubview(titleView)
        constrain(titleView) {
            $0.top == $0.superview!.top
            $0.bottom == $0.superview!.bottom
        }
        
        let autoWidth = titleView.intrinsicContentSize.width
        var titleMargin = max(leftWidth, rightWidth)
        if titleMargin > SRNavigationBar.Const.contentPadding {
            titleMargin += SRNavigationBar.Const.contentPadding
        }
        if autoWidth > 0, let titleView = titleView {
            constrain(titleView) {
                $0.centerX == $0.superview!.centerX
                //                $0.width == titleView.width
            }
            return
            
            let left = NSLayoutConstraint(item: titleView,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: srContentView,
                                          attribute: .left,
                                          multiplier: 1.0,
                                          constant: titleMargin)
            left.priority = .defaultLow
            srContentView.addConstraint(left)
            
            let right = NSLayoutConstraint(item: srContentView,
                                           attribute: .right,
                                           relatedBy: .equal,
                                           toItem: titleView,
                                           attribute: .right,
                                           multiplier: 1.0,
                                           constant: titleMargin)
            right.priority = .defaultLow
            srContentView.addConstraint(right)
        } else {
            constrain(titleView) {
                $0.centerX == $0.superview!.centerX
                $0.width == titleView.width
            }
        }
    }
}
