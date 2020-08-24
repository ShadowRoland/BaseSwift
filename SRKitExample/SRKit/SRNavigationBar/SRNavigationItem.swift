//
//  SRNavigationItem.swift
//  SRKit
//
//  Created by Gary on 2019/5/13.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit

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
            navigationBar?.setNeedsLayout()
        }
    }
    
    fileprivate var _titleView: UIView? = nil
    open override var titleView: UIView? { // Custom view to use in lieu of a title. May be sized horizontally. Only used when item is topmost on the stack.
        get {
            return _titleView
        }
        set {
            _titleView = newValue
            navigationBar?.setNeedsLayout()
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
            navigationBar?.setNeedsLayout()
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
            navigationBar?.setNeedsLayout()
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
            navigationBar?.setNeedsLayout()
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
    //fileprivate var _leftBarButtonItem: UIBarButtonItem? = nil
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
            navigationBar?.setNeedsLayout()
        }
    }
    
    //fileprivate var _rightBarButtonItem: UIBarButtonItem? = nil
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
            navigationBar?.setNeedsLayout()
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
