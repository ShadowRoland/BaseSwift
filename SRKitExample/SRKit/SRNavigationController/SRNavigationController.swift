//
//  SRNavigationController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import REMenu
import SwiftyJSON

open class SRNavigationController: UINavigationController, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UINavigationBarDelegate {
    public struct DebugMenuItem {
        fileprivate var title: String
        fileprivate var description: String?
        fileprivate var action: () -> Void
        
        public init(_ title: String, description: String?, action: @escaping () -> Void) {
            self.title = title
            self.description = description
            self.action = action
        }
    }
    
    open var isPageSwipeEnabled = false {
        didSet {
            if isPageSwipeEnabled != oldValue {
                let gr = interactivePopGestureRecognizer
                if isPageSwipeEnabled {
                    gr?.view?.addGestureRecognizer(panRecognizer)
                } else {
                    gr?.view?.removeGestureRecognizer(panRecognizer)
                }
            }
        }
    }
    
    open var isNavPageLongPressEnabled = false {
        didSet {
            if isNavPageLongPressEnabled != oldValue {
                let gr = interactivePopGestureRecognizer
                if isNavPageLongPressEnabled {
                    gr?.view?.addGestureRecognizer(longPressRecognizer)
                } else {
                    gr?.view?.removeGestureRecognizer(longPressRecognizer)
                }
            }
        }
    }
    
    /**
     *  滑动退出页面的手势
     *  注意，该手势与UITableViewCell的左滑冲突，会覆盖掉UITableViewCell的左滑操作
     *  如果页面中有UITableViewCell需要左滑的动作，需要禁止该手势
     */
    lazy var panRecognizer: UIPanGestureRecognizer = {
        let gr = UIPanGestureRecognizer()
        gr.delegate = self
        gr.maximumNumberOfTouches = 1
        
        let gesture = interactivePopGestureRecognizer
        let targets = gesture?.value(forKey: "_targets") as? Array<AnyObject>
        let gestureRecognizerTarget = targets?.first as AnyObject
        let navigationInteractiveTransition = gestureRecognizerTarget.value(forKey: "_target")
        let handleTransition = NSSelectorFromString("handleNavigationTransition:") as Selector;
        gr.addTarget(navigationInteractiveTransition!, action: handleTransition)
        
        return gr
    }()
    
    /**
     *  长按导航栏或者页面的手势
     */
    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        let gr = UILongPressGestureRecognizer(target: self,
                                              action: #selector(handleLongPressed))
        navigationBar.addGestureRecognizer(gr)
        return gr
    }()
    
    private var _debugMenu: REMenu?
    var debugMenu: REMenu {
        if _debugMenu == nil {
            _debugMenu = REMenu()
            _debugMenu!.textColor = .white
            _debugMenu!.subtitleTextColor = UIColor(white: 0.8)
            _debugMenu!.font = C.Font.title
        }
        
        var items = [] as [DebugMenuItem]
        if let debugMenuItems = debugMenuItems, !debugMenuItems.isEmpty {
            items = debugMenuItems
        } else if let defaultMenuItems = SRNavigationController.defaultMenuItems,
            !defaultMenuItems.isEmpty {
            items = defaultMenuItems
        }
        
        _debugMenu!.items = items.compactMap { item in
            REMenuItem(title: item.title,
                       subtitle: item.description,
                       image: nil,
                       highlightedImage: nil,
                       action: { _ in
                        item.action()
            })
        }
        
        return _debugMenu!
    }
    
    open var debugMenuItems: [DebugMenuItem]?
    
    public static var defaultMenuItems: [DebugMenuItem]?
    
    @objc func handleLongPressed() {
        guard !debugMenu.isOpen && !debugMenu.isAnimating,
            let viewController = topViewController else { return }
        var y = 0 as CGFloat
        if navigationBarType == .system {
            if #available(iOS 11.0, *) {
                y = viewController.view.safeAreaInsets.top
            } else {
                y = viewController.topLayoutGuide.length
            }
        } else if navigationBarType == .sr {
            y = viewController.navigationBar.isHidden ? 0 : viewController.navigationBar.bottom
        }
        var rect = view.bounds
        rect.origin.y = y
        rect.size.height = rect.height - y
        debugMenu.show(from: rect, in: view)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        interactivePopGestureRecognizer?.delegate = self
    }
    
    //MARK: - Orientations
    
    override open var shouldAutorotate: Bool {
        if let topViewController = topViewController {
            return topViewController.shouldAutorotate
        }
        return super.shouldAutorotate
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let topViewController = topViewController {
            return topViewController.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let topViewController = topViewController {
            return topViewController.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    //MARK: - Status Bar
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
    
    //MARK: - UIGestureRecognizerDelegate
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === interactivePopGestureRecognizer  {
            if let topViewController = topViewController {
                return topViewController.pageBackGestureStyle.contains(.edge)
            }
        }
        return true
    }
    
    //MARK: - UINavigationControllerDelegate
    
    open func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        isPageSwipeEnabled = viewController.pageBackGestureStyle.contains(.page)
        isPageLongPressEnabled = viewController.isPageLongPressEnabled
    }
}
