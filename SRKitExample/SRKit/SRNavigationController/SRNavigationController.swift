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

open class SRNavigationController: UINavigationController, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    public struct DebugMenuItem {
        public var title: String
        public var description: String?
        public var action: () -> Void
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
    
    var _debugMenu: REMenu?
    var debugMenu: REMenu {
        if _debugMenu == nil {
            _debugMenu = REMenu()
            _debugMenu!.textColor = .white
            _debugMenu!.font = .title
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
        guard !debugMenu.isOpen && !debugMenu.isAnimating else { return }
        debugMenu.show(from: UIApplication.shared.keyWindow!.bounds,
                       in: UIApplication.shared.keyWindow)
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
