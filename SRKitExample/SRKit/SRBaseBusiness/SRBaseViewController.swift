//
//  SRBaseViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/20.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SDWebImage
import DTCoreText
import Cartography

open class SRBaseViewController: UIViewController,
    UIScrollViewDelegate,
    SRStateMachineDelegate,
DTAttributedTextContentViewDelegate {
    lazy var eventTarget = EventTarget(self)
    //内部的事件响应类
    class EventTarget: NSObject {
        weak var viewController: SRBaseViewController?
        
        init(_ viewController: SRBaseViewController) {
            self.viewController = viewController
        }
        
        deinit {
            NotifyDefault.remove(self)
        }
        
        //MARK: - Selector
        @objc func contentSizeCategoryDidChange() {
            DispatchQueue.main.async { [weak self] in
                self?.viewController?.contentSizeCategoryDidChange()
            }
        }
        
        @objc func deviceOrientationDidChange(_ sender: AnyObject?) {
            DispatchQueue.main.async { [weak self] in
                self?.viewController?.deviceOrientationDidChange(sender)
            }
        }
        
        @objc func clickNavigationBarLeftButton(_ button: UIButton) {
            DispatchQueue.main.async { [weak self] in
                self?.viewController?.clickNavigationBarLeftButton(button)
            }
        }
        
        @objc func clickNavigationBarRightButton(_ button: UIButton) {
            DispatchQueue.main.async { [weak self] in
                self?.viewController?.clickNavigationBarRightButton(button)
            }
        }
        
        //在程序运行中收到指令，基本都可以通过走状态机实现
        @objc func newAction(_ notification: Notification) {
            if let event = notification.object as? SRKit.Event,
                let viewController = viewController {
                viewController.stateMachine.append(event)
            }
        }
        
        //FIXME: FOR DEBUG，由self push的WebpageViewController完成加载后会发出通知，触发状态机的完成事件
        //TODO: 此处若是其他程序调用而启动本应用（如在本应用被杀死的状态下点击退送消息），似乎会收不到该通知，等待解决
        @objc func didEndStateMachinePageEvent(_ notification: Notification) {
            if let event = notification.object as? SRKit.Event,
                let viewController = viewController,
                viewController === event.sender {
                viewController.stateMachine(viewController.stateMachine, didEnd: event)
            }
        }
        
        @objc func clickDTLinkButton(_ sender: Any) {
            viewController?.clickDTLinkButton(sender)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        stateMachine.delegate = self
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.contentSizeCategoryDidChange),
                          name: UIContentSizeCategory.didChangeNotification)
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.newAction(_:)),
                          name: SRKit.newActionNotification)
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.didEndStateMachinePageEvent(_:)),
                          name: SRKit.didEndStateMachinePageEventNotification)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appear = navigationBarAppear
        navigationBarAppear = appear
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.contentSizeCategoryDidChange),
                          name: UIDevice.orientationDidChangeNotification,
                          object: nil)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        LogInfo("enter: \(NSStringFromClass(type(of: self)))")
        
        let component = baseBusinessComponent
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            if navigationBarType == .system {
                if navigationBarAppear == .visible {
                    if navigationController.isNavigationBarHidden {
                        navigationController.setNavigationBarHidden(false, animated: false)
                    }
                    ensureNavigationBarHidden(false)
                } else if navigationBarAppear == .hidden {
                    if !navigationController.isNavigationBarHidden {
                        navigationController.setNavigationBarHidden(true, animated: false)
                    }
                    ensureNavigationBarHidden(true)
                }
            }
            
            Keyboard.manager = .iq
            SRKeyboardManager.shared.viewController = self
            
            component.isNavigationBarButtonsActive = true
            //let style = component.pageBackGestureStyle
            //component.pageBackGestureStyle = style
            //let enabled = component.isPageLongPressEnabled
            //component.isPageLongPressEnabled = enabled
        }
        
        if !component.isViewDidAppear {
            component.isViewDidAppear = true
            if component.needShowProgress {
                showProgress(component.progressMaskType)
            }
            performViewDidLoad()
        } else {
            resetProgressPosition()
            resetLoadDataFailViewPosition()
        }
        
//        if component.navigationBarBackgroundView.superview == view
//            && component.navigationBarBackgroundView.constraints.isEmpty {
//            constrain(component.navigationBarBackgroundView, self.car_topLayoutGuide) { (view, topLayoutGuide) in
//                view.top == view.superview!.top
//                view.leading == view.superview!.leading
//                view.trailing == view.superview!.trailing
//                view.bottom == topLayoutGuide.bottom
//            }
//        }
        
        //广播“触发状态机的完成事件”的通知
        if let event = event {
            LogDebug(NSStringFromClass(type(of: self)) + ".\(#function), event: \(event)")
            NotifyDefault.post(name: SRKit.didEndStateMachinePageEventNotification, object: params)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            Keyboard.manager = .unable
            SRKeyboardManager.shared.viewController = nil
            baseBusinessComponent.isNavigationBarButtonsActive = false
        }
        
        NotifyDefault.remove(self, name: UIDevice.orientationDidChangeNotification)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if navigationBarType == .sr {
            view.bringSubviewToFront(baseBusinessComponent.navigationBar)
        }
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
        //SRHttpManager.shared.cancel(sender: String(pointer: self))
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Event
    
    open func contentSizeCategoryDidChange() {
        
    }
    
    open func deviceOrientationDidChange(_ sender: AnyObject?) {
        guard guardDeviceOrientationDidChange(sender) else { return }
        //只在屏幕旋转时才更新位置
        if sender != nil {
            resetProgressPosition()
            resetLoadDataFailViewPosition()
        }
    }
    
    open func clickNavigationBarLeftButton(_ button: UIButton) {
        guard MutexTouch else { return }
        if button.tag == 0 {
            popBack()
        }
    }
    
    open func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
    }
    
    open func didEndStateMachineEvent(_ notification: Notification) {
        if let event = notification.object as? SRKit.Event, self === event.sender {
            stateMachine.end(event)
        }
    }
    
    open func clickDTLinkButton(_ sender: Any) {
        if let button = sender as? DTLinkButton {
            clickDTLink(button.guid, url: button.url)
        }
    }
    
    //MARK: - Status Bar
    
    //设置为false后横屏状态下将默认显示状态栏，前提是info.plist设置View controller-based status bar appearance为YES
    //在某些不需要横屏状态下显示状态栏的页面，重写该方法，返回true
    override open var prefersStatusBarHidden: Bool { return false }
    
    //务必将Info.plist中的View controller-based status bar appearance设置为NO
    override open var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
    //MARK: - Autorotate Orientation
    
    override open var shouldAutorotate: Bool { return ShouldAutorotate }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return SupportedInterfaceOrientations
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return PreferredInterfaceOrientationForPresentation
    }
    
    //MARK: Page
    
    open func performViewDidLoad() {
        
    }
    
    //MARK: Navigation Bar
    
    open override var title: String? {
        didSet {
            switch navigationBarType {
            case .system:
                super.title = self.title
            case .sr:
                baseBusinessComponent.navigationItem.title = self.title
            }
        }
    }
    
    open var srNavigationItem: SRNavigationItem {
            return baseBusinessComponent.navigationItem
    }
    
    open func setDefaultNavigationBar(_ title: String? = nil) {
        setDefaultNavigationBar(title: title, leftImage: nil)
    }
    
    open func setDefaultNavigationBar(title: String?, leftImage image: UIImage?) {
        self.title = title
        setNavigationBar()
        if self !== navigationController?.viewControllers.first {
            switch navigationBarType {
            case .system:
                navBarLeftButtonSettings = [[.style : NavigationBar.ButtonItemStyle.image,
                                             .image : UIImage.srNamed("sr_page_back")!]]
            case .sr:
                navBarLeftButtonSettings =
                    [[.style : NavigationBar.ButtonItemStyle.image,
                      .image : UIImage.srNamed(navigationBar.barStyle == .black ? "sr_page_back_white" : "sr_page_back")!]]
            }
        }
    }
    
    open func setNavigationBar() {
        switch navigationBarType {
        case .system:
            guard let navigationController = navigationController else { return }
            
            let navigationBar = navigationController.navigationBar
            navigationBar.titleTextAttributes = NavigationBar.titleTextAttributes
            navigationBar.setBackgroundImage(NavigationBar.backgroundImage, for: .default)
            navigationBar.tintColor = NavigationBar.tintColor
            
        case .sr:
            navigationBar.titleTextAttributes = NavigationBar.titleTextAttributes
            navigationBar.setBackgroundImage(NavigationBar.backgroundImage, for: .default)
            navigationBar.tintColor = NavigationBar.tintColor
        }
    }
    
    open var navBarLeftButtonSettings: [[NavigationBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarLeftButtonSettings, !settings.isEmpty else { //左边完全无按钮
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                return
            }
            
            //再添加新的按钮
            let items = (0 ..< settings.count).compactMap {
                NavigationBar.buttonItem(settings[$0],
                                         target: eventTarget,
                                         action: #selector(EventTarget.clickNavigationBarLeftButton(_:)),
                                         tag: $0,
                                         isCustomView: navigationBarType != .system)
            }
            switch navigationBarType {
            case .system:
                if items.isEmpty {
                    navigationItem.leftBarButtonItem = nil
                    navigationItem.leftBarButtonItems = nil
                } else if items.count == 1 {
                    navigationItem.leftBarButtonItem = items.first
                } else {
                    navigationItem.leftBarButtonItems = items
                }
                
            case .sr:
                srNavigationItem.leftBarButtonItems = items
            }
        }
    }
    
    open var navBarRightButtonSettings: [[NavigationBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarRightButtonSettings, !settings.isEmpty else {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
                return
            }
            
            let items = (0 ..< settings.count).compactMap {
                NavigationBar.buttonItem(settings[$0],
                                         target: eventTarget,
                                         action: #selector(EventTarget.clickNavigationBarRightButton(_:)),
                                         tag: $0,
                                         isCustomView: navigationBarType != .system)
            }
            
            switch navigationBarType {
            case .system:
                if items.isEmpty {
                    navigationItem.rightBarButtonItem = nil
                    navigationItem.rightBarButtonItems = nil
                } else {
                    navigationItem.rightBarButtonItems = items
                }
                
            case .sr:
                srNavigationItem.rightBarButtonItems = items
            }
        }
    }
    
    //MARK: Progress
    
    open func showProgress() {
        showProgress(.clear, immediately: false)
    }
    
    open func showProgress(_ maskType: UIView.SRProgressComponent.MaskType) {
        showProgress(maskType, immediately: false)
    }
    
    open func showProgress(_ maskType: UIView.SRProgressComponent.MaskType,
                             immediately: Bool) {
        guard let view = self.view else { return }
        
        let component = baseBusinessComponent
        
        if !immediately && !component.isViewDidAppear {
            component.needShowProgress = true
            component.progressMaskType = maskType
            return
        }
        
        view.insertSubview(component.progressContainerView, at: view.subviews.count)
        if #available(iOS 11.0, *) {
            component.progressContainerView.frame =
                CGRect(0,
                       view.safeAreaInsets.top,
                       view.bounds.size.width,
                       view.bounds.size.height - view.safeAreaInsets.top)
        } else {
            component.progressContainerView.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       view.bounds.size.width,
                       view.bounds.size.height - topLayoutGuide.length)
        }
        
        //在此改变默认的加载转圈样式
        component.progressContainerView.showProgress(maskType)
        //component.progressContainerView.showProgress(maskType,
        //                                             progressType: .svRing,
        //                                             options: [ProgressOptionKey.showPercentage : true])
        //component.progressContainerView.showProgress(maskType,
        //                                             progressType: .m13Ring,
        //                                             options: [ProgressOptionKey.shouldAutorotate : shouldAutorotate])
    }
    
    open func dismissProgress() {
        dismissProgress(false)
    }
    
    open func dismissProgress(_ animated: Bool) {
        guard isShowingProgress else {
            if baseBusinessComponent.needShowProgress {
                baseBusinessComponent.needShowProgress = false
            }
            return
        }
        
        baseBusinessComponent.progressContainerView.dismissProgress(animated)
        baseBusinessComponent.progressContainerView.removeFromSuperview()
    }
    
    open func resetProgressPosition() {
        guard isShowingProgress else { return }
        
        if #available(iOS 11.0, *) {
            baseBusinessComponent.progressContainerView.frame =
                CGRect(0,
                       view.safeAreaInsets.top,
                       view.bounds.size.width,
                       view.bounds.size.height - view.safeAreaInsets.top)
        } else {
            baseBusinessComponent.progressContainerView.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       view.bounds.size.width,
                       view.bounds.size.height - topLayoutGuide.length)
        }
        baseBusinessComponent.progressContainerView.resetProgressPosition()
    }
    
    open var isShowingProgress: Bool {
        guard let view = view,
            baseBusinessComponent.progressContainerView.superview === view else {
                return false
        }
        return baseBusinessComponent.progressContainerView.isShowingProgress
    }
    
    //MARK: Load Data Fail
    
    open func showLoadDataFailView(_ text: String?, image: UIImage? = nil) {
        guard let view = view else { return }
        
        let component = baseBusinessComponent
        view.insertSubview(component.loadDataFailContainerView, at: view.subviews.count)
        if #available(iOS 11.0, *) {
            component.loadDataFailContainerView.frame =
                CGRect(0,
                       view.safeAreaInsets.top,
                       view.bounds.size.width,
                       view.bounds.size.height - view.safeAreaInsets.top)
        } else {
            component.loadDataFailContainerView.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       view.bounds.size.width,
                       view.bounds.size.height - topLayoutGuide.length)
        }
        component.showLoadDataFailView(text, image: image ?? UIImage.srNamed("sr_load_data_fail")!)
    }
    
    open func dismissLoadDataFailView() {
        guard isShowingLoadDataFailView else { return }
        baseBusinessComponent.loadDataFailContainerView.removeFromSuperview()
        baseBusinessComponent.dismissLoadDataFailView()
    }
    
    open func resetLoadDataFailViewPosition() {
        guard isShowingLoadDataFailView else { return }
        if #available(iOS 11.0, *) {
            baseBusinessComponent.loadDataFailContainerView.frame =
                CGRect(0,
                       view.safeAreaInsets.top,
                       view.bounds.size.width,
                       view.bounds.size.height - view.safeAreaInsets.top)
        } else {
            baseBusinessComponent.loadDataFailContainerView.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       view.bounds.size.width,
                       view.bounds.size.height - topLayoutGuide.length)
        }
    }
    
    open var isShowingLoadDataFailView: Bool {
        guard let view = view,
            baseBusinessComponent.loadDataFailContainerView.superview === view else {
                return false
                
        }
        return baseBusinessComponent.isShowingLoadDataFailView
    }
    
    open func setLoadDataFail(_ method: HTTP.Method, retry: (() -> Void)?) {
        baseBusinessComponent.loadDataFailRetryMethod = method
        baseBusinessComponent.loadDataFailRetryHandler = retry
    }
    
    open var loadDataFailMethod: HTTP.Method? {
        return baseBusinessComponent.loadDataFailRetryMethod
    }
    
    open func clickDTLink(_ text: String?, url: URL? = nil) {
        
    }
    
    //MARK: - Http Request
    
    open func httpRequest(_ method: HTTP.Method,
                            anonymous: Bool = false,
                            encoding: ParamEncoding? = nil,
                            headers: ParamHeaders? = nil,
                            options: [HTTP.Key.Option : Any]? = nil,
                            success: ((Any) -> Void)? = nil,
                            bfail: ((HTTP.Method, Any) -> Void)? = nil,
                            fail: ((HTTP.Method, BFError) -> Void)? = nil) {
//        var successHandler: ((Any) -> Void)!
//        if let success = success {
//            successHandler = success
//        } else {
//            successHandler = { [weak self] response in
//                self?.httpRespondSuccess(response)
//            }
//        }
//
//        var bfailHandler: ((HTTP.Method, Any) -> Void)!
//        if let bfail = bfail {
//            bfailHandler = bfail
//        } else {
//            bfailHandler = { [weak self] (method, response) in
//                self?.httpRespondBfail(method, response: response)
//            }
//        }
//
//        var failHandler: ((HTTP.Method, BFError) -> Void)!
//        if let fail = fail {
//            failHandler = fail
//        } else {
//            failHandler = { [weak self] (method, error) in
//                self?.httpRespondFail(method, error: error)
//            }
//        }
//
//        SRHttpManager.shared.request(method,
//                                     sender: anonymous ? nil : String(pointer: self),
//                                     encoding: encoding,
//                                     headers: headers,
//                                     options: options,
//                                     success: successHandler,
//                                     bfail: bfailHandler,
//                                     fail: failHandler)
    }
    
    open func httpRespondSuccess(_ response: Any) {
        dismissProgress()
        if isTop {
            SRAlert.show((response as? JSON)?[HTTP.Key.Response.errorMessage].string,
                         type: .success)
        }
    }
    
    open func httpRespondBfail(_ method: HTTP.Method, response: Any) {
        dismissProgress()
        if method == loadDataFailMethod {
            showLoadDataFailView(logBFail(method,
                                          response: response,
                                          show: false))
        } else {
            logBFail(method, response: response)
        }
    }
    
    open func httpRespondFail(_ method: HTTP.Method, error: BFError) {
        dismissProgress()
        if method == loadDataFailMethod {
            showLoadDataFailView(error.errorDescription)
        } else {
            showToast(error.errorDescription)
        }
    }
    
    @discardableResult
    open func logBFail(_ method: HTTP.Method,
                         response: Any?,
                         show: Bool = true) -> String {
        var message = ""
        if let json = response as? JSON {
            message = NonNull.string(json[HTTP.Key.Response.errorMessage].string)
        }
        LogError(String(format: "request failed, url: %@\nreponse: %@\nmessage: %@",
                        method.url,
                        (response as? JSON)?.rawValue as? CVarArg ?? "",
                        message))
        if show {
            SRAlert.show(message: message, type: .error)
        }
        return message
    }
    
    //MARK: - DTAttributedTextContentViewDelegate
    
    open func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!,
                                          viewFor string: NSAttributedString!,
                                          frame: CGRect) -> UIView! {
        let attributes = string.attributes(at: 0, effectiveRange: nil)
        let url = attributes[NSAttributedString.Key(DTLinkAttribute)]
        //let identifier = attributes[NSAttributedString.Key(DTGUIDAttribute)]
        
        let button = DTLinkButton(frame: frame)
        button.url = url as? URL
        button.minimumHitSize = CGSize(25.0, 25.0) // adjusts it's bounds so that button is always large enough
        //button.guid = identifier as? String
        button.guid = string.string

        // get image with normal link text
        var image = attributedTextContentView.contentImage(withBounds: frame, options: .default)
        button.setImage(image, for: .normal)
        
        // get image for highlighted link text
        image = attributedTextContentView.contentImage(withBounds: frame, options: .drawLinksHighlighted)
        button.setImage(image, for: .highlighted)
        
        // use normal push action for opening URL
        button.clicked(eventTarget, action: #selector(EventTarget.clickDTLinkButton(_:)))
        
        return button;
    }
    
    //MARK: SRStateMachineDelegate
    
    open func stateMachine(_ stateMachine: SRStateMachine, didFire event: SRKit.Event) {
        
    }
    
    open func stateMachine(_ stateMachine: SRStateMachine, didEnd event: SRKit.Event) {
        
    }
}
