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
        self._navigationItem.navigationBar = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static var height: CGFloat = 44.0
    
    var delegate: SRNavigationBarDelegate?
    
    //MARK: Customize
    
    public struct Const {
        static var contentPadding = 8.0 as CGFloat
        static var minButtonItemWidth = 35.0 as CGFloat
    }
    
    //MARK: -

    fileprivate var _navigationItem = SRNavigationItem()
    open var navigationItem: SRNavigationItem {
        get {
            return _navigationItem
        }
        set {
            _navigationItem = newValue
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
    open var leftBarButtonItems: [SRNavigationBarButtonItem]?
    open var rightBarButtonItems: [SRNavigationBarButtonItem]?
    
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
    
    public var title: String? {
        didSet {
            navigationItem.title = title
            layout()
        }
    }
    
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
    
    var layoutObserver: CFRunLoopObserver?
    fileprivate func layout() {
        if layoutObserver == nil {
            let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                              CFRunLoopActivity.allActivities.rawValue, true, 0) { [weak self] (observer, activity) in
                switch activity {
                case .beforeSources:
                    self?.layoutItems()
                    if let layoutObserver = self?.layoutObserver {
                        CFRunLoopRemoveObserver(CFRunLoopGetMain(), layoutObserver, .defaultMode)
                        self?.layoutObserver = nil
                    }
                default: break
                }
            }
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .defaultMode)
            layoutObserver = observer
        }
    }
    
    fileprivate func layoutItems() {
        // Layout left items
        contentView.subviews.forEach { $0.removeFromSuperview() }
        var leftWidth = SRNavigationBar.Const.contentPadding
        var leftPrevious: UIView! = nil
        
        func setLeftButtonItem(_ item: SRNavigationBarButtonItem) {
            let button = item.customView as! UIButton
            contentView.addSubview(button)
            if leftPrevious == nil {
                constrain(button) {
                    $0.leading == $0.superview!.leading + SRNavigationBar.Const.contentPadding
                    $0.top == $0.superview!.top
                    $0.bottom == $0.superview!.bottom
                }
            } else {
                constrain(button, leftPrevious) {
                    $0.leading == $1.trailing
                    $0.top == $0.superview!.top
                    $0.bottom == $0.superview!.bottom
                }
            }
            var width = button.intrinsicContentSize.width
            if width < SRNavigationBar.Const.minButtonItemWidth {
                width = SRNavigationBar.Const.minButtonItemWidth
                constrain(button) {
                    $0.width == width
                }
            }

            leftWidth += width
            leftPrevious = button
        }
        
        func setLeftButtonItem(customView item: SRNavigationBarButtonItem) {
            let customView = item.customView!
            contentView.addSubview(customView)
            if leftPrevious == nil {
                constrain(customView) {
                    $0.leading == $0.superview!.leading + SRNavigationBar.Const.contentPadding
                }
            } else {
                constrain(customView, leftPrevious) {
                    $0.leading == $1.trailing
                }
            }
            let size = customView.frame.size
            constrain(customView) {
                $0.width == size.width
                $0.height == size.height
                $0.centerY == $0.superview!.centerY
            }

            leftWidth += width
            leftPrevious = customView
        }
        
        if let items = navigationItem.leftBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                let item = items[index] as! SRNavigationBarButtonItem
                let option = item.option!
                switch option {
                case .text, .image:
                    setLeftButtonItem(item)
                    
                default:
                    setLeftButtonItem(customView: item)
                }
            }
        }
        
        // Layout right items
        var rightWidth = SRNavigationBar.Const.contentPadding
        var rightPrevious: UIView! = nil
        
        func setRightButtonItem(_ item: SRNavigationBarButtonItem) {
            let button = item.customView as! UIButton
            contentView.addSubview(button)
            if rightPrevious == nil {
                constrain(button) {
                    $0.trailing == $0.superview!.trailing - SRNavigationBar.Const.contentPadding
                    $0.top == $0.superview!.top
                    $0.bottom == $0.superview!.bottom
                }
            } else {
                constrain(button, rightPrevious) {
                    $0.trailing == $1.leading
                    $0.top == $0.superview!.top
                    $0.bottom == $0.superview!.bottom
                }
            }
            
            var width = button.intrinsicContentSize.width
            if width < SRNavigationBar.Const.minButtonItemWidth {
                width = SRNavigationBar.Const.minButtonItemWidth
                constrain(button) {
                    $0.width == width
                }
            }

            rightWidth += width
            rightPrevious = button
        }
        
        func setRightButtonItem(customView item: SRNavigationBarButtonItem) {
            let customView = item.customView!
            contentView.addSubview(customView)
            if rightPrevious == nil {
                constrain(customView) {
                    $0.trailing == $0.superview!.trailing - SRNavigationBar.Const.contentPadding
                }
            } else {
                constrain(customView, rightPrevious) {
                    $0.trailing == $1.leading
                }
            }
            let size = customView.frame.size
            constrain(customView) {
                $0.width == size.width
                $0.height == size.height
                $0.centerY == $0.superview!.centerY
            }

            rightWidth += width
            rightPrevious = customView
        }
        
        if let items = navigationItem.rightBarButtonItems {
            let count = items.count
            (0 ..< count).forEach { index in
                let item = items[index] as! SRNavigationBarButtonItem
                let option = item.option!
                switch option {
                case .text, .image:
                    setRightButtonItem(item)
                    
                default:
                    setRightButtonItem(customView: item)
                }
            }
        }
        
        // Layout titleView
        var titleView: UIView!
        if let view = navigationItem.titleView {
            titleView = view
            titleLabel.isHidden = true
        } else {
            titleView = titleLabel
            titleLabel.isHidden = false
            if let title = navigationItem.title, !title.isEmpty {
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
        //layoutIfNeeded()
        delegate?.navigationBarDidLayout(self)
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

public protocol SRNavigationBarDelegate {
    func navigationBarDidLayout(_ navigationBar: SRNavigationBar)
}

open class SRNavigationItem: UINavigationItem {
    init() {
        super.init(title: "")
    }

    private override init(title: String) {
        super.init(title: title)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: -
    
    open weak var navigationBar: SRNavigationBar?
    
    fileprivate var _title: String? = nil
    open override var title: String? { // Title when topmost on the stack. default is nil
        get {
            return _title
        }
        set {
            _title = newValue
            navigationBar?.layout()
        }
    }
    
    fileprivate var _titleView: UIView? = nil
    open override var titleView: UIView? { // Custom view to use in lieu of a title. May be sized horizontally. Only used when item is topmost on the stack.
        get {
            return _titleView
        }
        set {
            _titleView = newValue
            navigationBar?.layout()
        }
    }
    
    
    fileprivate var _prompt: String? = nil
    open override var prompt: String? { // Explanatory text to display above the navigation bar buttons.
        get {
            return _prompt
        }
        set {
            _prompt = newValue
            //navigationBar?.layout()
            navigationBar?.layout()
        }
    }
    
    fileprivate var _backBarButtonItem: UIBarButtonItem? = nil
    open override var backBarButtonItem: UIBarButtonItem? { // Bar button item to use for the back button in the child navigation item.
        get {
            return _backBarButtonItem
        }
        set {
            _backBarButtonItem = newValue
        }
    }
    
    
    fileprivate var _hidesBackButton: Bool = false
    open override var hidesBackButton: Bool {// If YES, this navigation item will hide the back button when it's on top of the stack.
        get {
            return _hidesBackButton
        }
        set {
            _hidesBackButton = newValue
        }
    }
    
    open override func setHidesBackButton(_ hidesBackButton: Bool, animated: Bool) {
        
    }
    
    
    /* Use these properties to set multiple items in a navigation bar.
     The older single properties (leftBarButtonItem and rightBarButtonItem) now refer to
     the first item in the respective array of items.
     
     NOTE: You'll achieve the best results if you use either the singular properties or
     the plural properties consistently and don't try to mix them.
     
     leftBarButtonItems are placed in the navigation bar left to right with the first
     item in the list at the left outside edge and left aligned.
     rightBarButtonItems are placed right to left with the first item in the list at
     the right outside edge and right aligned.
     */
    fileprivate var _leftBarButtonItems: [UIBarButtonItem]? = nil
    @available(iOS 5.0, *)
    open override var leftBarButtonItems: [UIBarButtonItem]? {
        get {
            return _leftBarButtonItems
        }
        set {
            _leftBarButtonItems = newValue
            navigationBar?.layout()
        }
    }
    
    fileprivate var _rightBarButtonItems: [UIBarButtonItem]? = nil
    @available(iOS 5.0, *)
    open override var rightBarButtonItems: [UIBarButtonItem]? {
        get {
            return _rightBarButtonItems
        }
        set {
            _rightBarButtonItems = newValue
            navigationBar?.layout()
        }
    }
    
    @available(iOS 5.0, *)
    open override func setLeftBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        
    }
    
    @available(iOS 5.0, *)
    open override func setRightBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        
    }
    
    
    /* By default, the leftItemsSupplementBackButton property is NO. In this case,
     the back button is not drawn and the left item or items replace it. If you
     would like the left items to appear in addition to the back button (as opposed to instead of it)
     set leftItemsSupplementBackButton to YES.
     */
    fileprivate var _leftItemsSupplementBackButton: Bool = false
    @available(iOS 5.0, *)
    open override var leftItemsSupplementBackButton: Bool {
        get {
            return _leftItemsSupplementBackButton
        }
        set {
            _leftItemsSupplementBackButton = newValue
        }
    }
    
    
    // Some navigation items want to display a custom left or right item when they're on top of the stack.
    // A custom left item replaces the regular back button unless you set leftItemsSupplementBackButton to YES
    //fileprivate var _leftBarButtonItem: SRNavigationBarButtonItem? = nil
    open override var leftBarButtonItem: UIBarButtonItem? {
        get {
            return 1 == _leftBarButtonItems?.count ? _leftBarButtonItems?.first : nil
        }
        set {
            if let newValue = newValue {
                _leftBarButtonItems = [newValue]
            } else {
                _leftBarButtonItems = nil
            }
            //navigationBar?.layout()
            navigationBar?.layout()
        }
    }
    
    //fileprivate var _rightBarButtonItem: SRNavigationBarButtonItem? = nil
    open override var rightBarButtonItem: UIBarButtonItem? {
        get {
            return 1 == _rightBarButtonItems?.count ? _rightBarButtonItems?.first : nil
        }
        set {
            if let newValue = newValue {
                _rightBarButtonItems = [newValue]
            } else {
                _rightBarButtonItems = nil
            }
            //navigationBar?.layout()
            navigationBar?.layout()
        }
    }
    
    open override func setLeftBarButton(_ item: UIBarButtonItem?, animated: Bool) {
        
    }
    
    open override func setRightBarButton(_ item: UIBarButtonItem?, animated: Bool) {
        
    }
    
    
    /// When UINavigationBar.prefersLargeTitles=YES, this property controls when the larger out-of-line title is displayed. If prefersLargeTitles=NO, this property has no effect. The default value is Automatic.
    fileprivate var _largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .automatic
    @available(iOS 11.0, *)
    open override var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        get {
            return _largeTitleDisplayMode
        }
        set {
            _largeTitleDisplayMode = newValue
        }
    }
    
    
    // A view controller that will be shown inside of a navigation controller can assign a UISearchController to this property to display the search controller’s search bar in its containing navigation controller’s navigation bar.
    fileprivate var _searchController: UISearchController? = nil
    @available(iOS 11.0, *)
    open override var searchController: UISearchController? {
        get {
            return _searchController
        }
        set {
            _searchController = newValue
        }
    }
    
    
    // If this property is true (the default), the searchController’s search bar will hide as the user scrolls in the top view controller’s scroll view. If false, the search bar will remain visible and pinned underneath the navigation bar.
    fileprivate var _hidesSearchBarWhenScrolling: Bool = true
    @available(iOS 11.0, *)
    open override var hidesSearchBarWhenScrolling: Bool {
        get {
            return _hidesSearchBarWhenScrolling
        }
        set {
            _hidesSearchBarWhenScrolling = newValue
        }
    }
}

open class SRNavigationBarButtonItem: UIBarButtonItem {
    public override init() {
        super.init()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var option: NavigationBar.ButtonItemOption?
}
