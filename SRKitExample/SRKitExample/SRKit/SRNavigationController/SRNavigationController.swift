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

public class SRNavigationController: UINavigationController,
    UIGestureRecognizerDelegate,
UINavigationBarDelegate {
    public var isPageSwipeEnabled = false {
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
    
    public var isNavPageLongPressEnabled = false {
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
    
    lazy var debugMenu: REMenu = {
        let menu = REMenu()
        menu.textColor = UIColor.white
        menu.font = UIFont.title
        return menu
    }()
    
    public func appendMenuItem(title: String,
                               description: String?,
                               action: @escaping (() -> Void)) {
        let item = REMenuItem(title: title,
                              subtitle: description,
                              image: nil,
                              highlightedImage: nil,
                              action: { _ in
                action()
        })
        var items = debugMenu.items
        items?.append(item!)
        debugMenu.items = items
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func handleLongPressed() {
        guard !debugMenu.isOpen && !debugMenu.isAnimating else { return }
        debugMenu.show(from: UIApplication.shared.keyWindow!.bounds,
                       in: UIApplication.shared.keyWindow)
    }
    
    //MARK: - Orientations
    
    override public var shouldAutorotate: Bool {
        if let topViewController = topViewController {
            return topViewController.shouldAutorotate
        }
        return super.shouldAutorotate
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let topViewController = topViewController {
            return topViewController.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let topViewController = topViewController {
            return topViewController.preferredInterfaceOrientationForPresentation
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    //MARK: - Status Bar
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
