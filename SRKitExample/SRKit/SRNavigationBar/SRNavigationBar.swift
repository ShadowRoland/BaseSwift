//
//  SRNavigationBar.swift
//  SRKit
//
//  Created by Gary on 2019/5/13.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit
import Cartography

open class SRNavigationBar: UIView {
    public init() {
        super.init(frame: CGRect())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static var height: CGFloat = 44.0
    
    //MARK: Customize
    
    public struct Const {
        static var contentPadding = 8.0 as CGFloat
    }
    
    //MARK: -
    
    open weak var navigationItem: SRNavigationItem? {
        didSet {
            navigationItem?.navigationBar = self
        }
    }
    
    open var barStyle: UIBarStyle = .default {
        didSet {
            if barStyle == .black {
                tintColor = .white
                barBackgroundColor = .black
                backgroundBlurView?.removeFromSuperview()
                backgroundBlurView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
                backgroundBlurView?.alpha = 1.0
                backgroundView.insertSubview(backgroundBlurView!, at: 0)
                constrain(backgroundBlurView!) { $0.edges == inset($0.superview!.edges, 0) }
                layout()
            } else {
                tintColor = .black
                barBackgroundColor = .white
                backgroundBlurView?.removeFromSuperview()
                backgroundBlurView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .extraLight)))
                backgroundBlurView?.alpha = 1.0
                backgroundView.insertSubview(backgroundBlurView!, at: 0)
                constrain(backgroundBlurView!) { $0.edges == inset($0.superview!.edges, 0) }
                layout()
            }
        }
    }
    open var barTintColor: UIColor?
    var barBackgroundColor: UIColor = .white
    open var isTranslucent: Bool = true
    open var titleTextAttributes: [NSAttributedString.Key : Any]?
    open var leftBarButtonItems: [UIBarButtonItem]?
    open var rightBarButtonItems: [UIBarButtonItem]?
    
    var backgroundImageDictionary = [:] as [UIBarMetrics : UIImage]
    
    open func setBackgroundImage(_ backgroundImage: UIImage?, for barMetrics: UIBarMetrics) {
        if let image = backgroundImage {
            backgroundImageDictionary[barMetrics] = image
        } else {
            backgroundImageDictionary.removeValue(forKey: barMetrics)
        }
    }
    
    open func backgroundImage(for barMetrics: UIBarMetrics) -> UIImage? {
        return backgroundImageDictionary[barMetrics]
    }
    
    lazy var backgroundView: UIView = {
        let view = UIView()
        insertSubview(view, at: 0)
        constrain(view) { $0.edges == inset($0.superview!.edges, 0) }
        return view
    }()
    
    lazy var backgroundShadowImageView: UIImageView = UIImageView()
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        backgroundView.addSubview(imageView)
        constrain(imageView) { $0.edges == inset($0.superview!.edges, 0) }
        return imageView
    }()
    
    var backgroundBlurView: UIVisualEffectView?
    
    lazy var contentView: UIView = {
        let view = UIView()
        addSubview(view)
        constrain(view) { $0.edges == inset($0.superview!.edges, 0) }
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        contentView.addSubview(label)
        return label
    }()
    
    open var shadowImage: UIImage? {
        didSet {
            if let shadowImage = shadowImage {
                if shadowImage.size.width > 0, shadowImage.size.height > 0 {
                    backgroundShadowImageView.image = shadowImage
                    backgroundShadowImageView.removeFromSuperview()
                    backgroundView.insertSubview(backgroundShadowImageView, at: 0)
                    constrain(backgroundShadowImageView) {
                        $0.leading == $0.superview!.leading
                        $0.trailing == $0.superview!.trailing
                        $0.top == $0.superview!.bottom
                        $0.height == $0.width * shadowImage.size.height / shadowImage.size.width
                    }
                } else {
                    backgroundShadowImageView.image = nil
                    backgroundShadowImageView.removeFromSuperview()
                }
                layout()
            } else {
                backgroundShadowImageView.image = nil
                backgroundShadowImageView.backgroundColor = "D".color
                backgroundShadowImageView.removeFromSuperview()
                backgroundView.insertSubview(backgroundShadowImageView, at: 0)
                constrain(backgroundShadowImageView) {
                    $0.leading == $0.superview!.leading
                    $0.trailing == $0.superview!.trailing
                    $0.top == $0.superview!.bottom
                    $0.height == 1.0
                }
                layout()
            }
        }
    }
    
    open func layout() {
        // Layout left items
        contentView.subviews.forEach { $0.removeFromSuperview() }
        var leftWidth = SRNavigationBar.Const.contentPadding
        var leftPrevious: UIView! = nil
        if let items = navigationItem?.leftBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                if let customView = items[index].customView {
                    contentView.addSubview(customView)
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
        if let items = navigationItem?.rightBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                if let customView = items[count - 1 - index].customView {
                    contentView.addSubview(customView)
                    if rightPrevious == nil {
                        constrain(customView) {
                            $0.trailing == $0.superview!.trailing - SRNavigationBar.Const.contentPadding
                            $0.top == $0.superview!.top
                            $0.bottom == $0.superview!.bottom
                        }
                    } else {
                        constrain(customView, rightPrevious) {
                            $0.trailing == $1.leading
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
                    
                    customView.frame = CGRect(0, 0, width, SRNavigationBar.height)
                    
                    rightWidth += width
                    rightPrevious = customView
                }
            }
        }
        
        // Layout titleView
        var titleView: UIView!
        if let view = navigationItem?.titleView {
            titleView = view
            titleLabel.isHidden = true
        } else {
            titleView = titleLabel
            titleLabel.isHidden = false
            if let title = navigationItem?.title, !title.isEmpty {
                if let attributes = titleTextAttributes, !attributes.isEmpty {
                    titleLabel.textColor = tintColor
                    titleLabel.attributedText = NSAttributedString.init(string: title,
                                                                        attributes: attributes)
                } else {
                    titleLabel.textColor = tintColor
                    titleLabel.text = title
                }
            } else {
                titleLabel.text = nil
            }
        }
        
        contentView.addSubview(titleView)
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
            }
            
            let left = NSLayoutConstraint(item: titleView,
                                          attribute: .left,
                                          relatedBy: .greaterThanOrEqual,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1.0,
                                          constant: titleMargin)
            left.priority = .defaultLow
            contentView.addConstraint(left)
            
            let right = NSLayoutConstraint(item: titleView,
                                           attribute: .right,
                                           relatedBy: .lessThanOrEqual,
                                           toItem: contentView,
                                           attribute: .right,
                                           multiplier: 1.0,
                                           constant: -titleMargin)
            right.priority = .defaultLow
            contentView.addConstraint(right)
        } else {
            constrain(titleView) {
                $0.centerX == $0.superview!.centerX
                $0.width == titleView.width
            }
        }
        
        // Layout background
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var image: UIImage? = nil
        if statusBarOrientation.isPortrait,
            let defaultImage = backgroundImageDictionary[.default] {
            image = defaultImage
        } else if let compactImage = backgroundImageDictionary[.compact] {
            image = compactImage
        }
        if let image = image {
            backgroundView.backgroundColor = nil
            backgroundBlurView?.isHidden = !isTranslucent
            backgroundImageView.image = image
            backgroundImageView.isHidden = false
        } else {
            backgroundImageView.isHidden = true
            if let barTintColor = barTintColor {
                backgroundView.backgroundColor = barTintColor
                backgroundBlurView?.isHidden = !isTranslucent
            } else {
                if isTranslucent {
                    backgroundView.backgroundColor = nil
                    backgroundBlurView?.isHidden = false
                } else {
                    backgroundView.backgroundColor = barBackgroundColor
                    backgroundBlurView?.isHidden = true
                }
            }
        }
        
        layoutBackground()
        layoutIfNeeded()
    }
    
    var statusBarOrientation: UIInterfaceOrientation?
    
    func layoutBackground() {
        // Layout background
        self.statusBarOrientation = UIApplication.shared.statusBarOrientation
        var image: UIImage? = nil
        if statusBarOrientation!.isPortrait,
            let defaultImage = backgroundImageDictionary[.default] {
            image = defaultImage
        } else if let compactImage = backgroundImageDictionary[.compact] {
            image = compactImage
        }
        if let image = image {
            backgroundView.backgroundColor = nil
            backgroundBlurView?.isHidden = !isTranslucent
            backgroundImageView.image = image
            backgroundImageView.isHidden = false
        } else {
            backgroundImageView.isHidden = true
            if let barTintColor = barTintColor {
                backgroundView.backgroundColor = barTintColor
                backgroundBlurView?.isHidden = !isTranslucent
            } else {
                if isTranslucent {
                    backgroundView.backgroundColor = nil
                    backgroundBlurView?.isHidden = false
                } else {
                    backgroundView.backgroundColor = barBackgroundColor
                    backgroundBlurView?.isHidden = true
                }
            }
        }
    }
    
    open override func layoutSubviews() {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if statusBarOrientation != self.statusBarOrientation {
            layoutBackground()
        }
    }
}
