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
    SRBaseViewControllerEventDelegate,
    SRLoadDataStateDelegate,
    SRStateMachineDelegate,
DTAttributedTextContentViewDelegate {
    open lazy var eventTarget = EventTarget(self)
    //内部的事件响应类
    open class EventTarget: NSObject {
        var delegate: SRBaseViewControllerEventDelegate?
        
        init(_ delegate: SRBaseViewControllerEventDelegate) {
            self.delegate = delegate
        }
        
        deinit {
            NotifyDefault.remove(self)
        }
        
        //MARK: - Selector
        @objc func contentSizeCategoryDidChange() {
            delegate?.contentSizeCategoryDidChange()
        }
        
        @objc func deviceOrientationDidChange(_ sender: AnyObject?) {
            delegate?.deviceOrientationDidChange(sender)
        }
        
        @objc func clickNavigationBarLeftButton(_ button: UIButton) {
            delegate?.clickNavigationBarLeftButton(button)
        }
        
        @objc func clickNavigationBarRightButton(_ button: UIButton) {
            delegate?.clickNavigationBarRightButton(button)
        }
        
        //FIXME: FOR DEBUG，由self push的WebpageViewController完成加载后会发出通知，触发状态机的完成事件
        //TODO: 此处若是其他程序调用而启动本应用（如在本应用被杀死的状态下点击退送消息），似乎会收不到该通知，等待解决
        @objc func didEndStateMachineEvent(_ notification: Notification) {
            delegate?.didEndStateMachineEvent(notification)
        }
        
        @objc func clickDTLinkButton(_ sender: Any) {
            delegate?.clickDTLinkButton(sender)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        stateMachine.delegate = self
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.contentSizeCategoryDidChange),
                          name: UIContentSizeCategory.didChangeNotification)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            if baseBusinessComponent.navigartionBarAppear == .visible
                && navigationController.isNavigationBarHidden {
                navigationController.setNavigationBarHidden(false, animated: animated)
            } else if baseBusinessComponent.navigartionBarAppear == .hidden
                && !navigationController.isNavigationBarHidden {
                navigationController.setNavigationBarHidden(true, animated: animated)
            }
        }
        
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
            if baseBusinessComponent.navigartionBarAppear == .visible {
                if navigationController.isNavigationBarHidden {
                    navigationController.setNavigationBarHidden(false, animated: false)
                }
                ensureNavigationBarHidden(false)
            } else if baseBusinessComponent.navigartionBarAppear == .hidden {
                if !navigationController.isNavigationBarHidden {
                    navigationController.setNavigationBarHidden(true, animated: false)
                }
                ensureNavigationBarHidden(true)
            }
            
            Keyboard.manager = .iq
            SRKeyboardManager.shared.viewController = self
            
            component.isNavigationBarButtonsActive = true
            let style = component.pageBackGestureStyle
            component.pageBackGestureStyle = style
            let enabled = component.isPageLongPressEnabled
            component.isPageLongPressEnabled = enabled
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
        
        if component.navigationBarBackgroundView.superview == view
            && component.navigationBarBackgroundView.constraints.isEmpty {
            constrain(component.navigationBarBackgroundView, self.car_topLayoutGuide) { (view, topLayoutGuide) in
                view.top == view.superview!.top
                view.leading == view.superview!.leading
                view.trailing == view.superview!.trailing
                view.bottom == topLayoutGuide.bottom
            }
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
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
        SRHttpManager.cancel(sender: String(pointer: self))
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    open func defaultNavigationBar(_ title: String? = nil) {
        defaultNavigationBar(title: title, leftImage: nil)
    }
    
    open func defaultNavigationBar(title: String?, leftImage image: UIImage?) {
        if let title = title {
            self.title = title
        }
        
        initNavigationBar()
        
        var setting = NavigartionBar.buttonFullSetting
        setting[.style] = NavigartionBar.ButtonItemStyle.image
        setting[.image] = image == nil ? UIImage.srNamed("sr_page_back") : image
        navBarLeftButtonSettings = [setting]
    }
    
    open func initNavigationBar() {
        guard let navigationController = navigationController else { return }
        
        navigationBarBackgroundAlpha = NavigartionBar.backgroundBlurAlpha
        navigationBarTintColor = NavigartionBar.tintColor
        
        let navigationBar = navigationController.navigationBar
        navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white,
                                             .font : UIFont.heavyTitle]
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.backgroundColor = UIColor.clear
    }
    
    open var navBarLeftButtonSettings: [[NavigartionBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarLeftButtonSettings, !settings.isEmpty else { //左边完全无按钮
                navigationController?.navigationBar.backIndicatorImage = nil
                navigationController?.navigationBar.backIndicatorTransitionMaskImage = nil
                navigationItem.backBarButtonItem = nil
                navigationItem.leftBarButtonItems = nil
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                return
            }
            
            if settings.first!.isEmpty { //使用默认的返回
                //navigationController?.navigationBar.backIndicatorImage = UIImage.srNamed("page_back")
                //navigationController?.navigationBar.backIndicatorTransitionMaskImage =
                //    UIImage("page_back")
                navigationItem.backBarButtonItem =
                    UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
                
                let items = (1 ..< settings.count).compactMap {
                    SRCommon.navigationBarButtonItem(settings[$0],
                                                       target: eventTarget,
                                                       action: #selector(EventTarget.clickNavigationBarLeftButton(_:)),
                                                       tag: $0)
                }
                
                //再添加新的按钮
                if items.isEmpty {
                    navigationItem.leftBarButtonItem = nil
                    navigationItem.leftBarButtonItems = nil
                } else if items.count == 1 {
                    navigationItem.leftBarButtonItem = items.first
                } else {
                    navigationItem.leftBarButtonItems = items
                }
            } else {
                //返回按钮亦自定义
                let items = (0 ..< settings.count).compactMap {
                    SRCommon.navigationBarButtonItem(settings[$0],
                                                       target: eventTarget,
                                                       action: #selector(EventTarget.clickNavigationBarLeftButton(_:)),
                                                       tag: $0)
                }
                
                navigationItem.backBarButtonItem = nil
                if items.isEmpty {
                    navigationItem.leftBarButtonItem = nil
                    navigationItem.leftBarButtonItems = nil
                } else if items.count == 1 {
                    navigationItem.leftBarButtonItem = items.first
                } else {
                    navigationItem.leftBarButtonItems = items
                }
            }
        }
    }
    
    open var navBarRightButtonSettings: [[NavigartionBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarRightButtonSettings, !settings.isEmpty else {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
                return
            }
            
            let items = (0 ..< settings.count).compactMap {
                SRCommon.navigationBarButtonItem(settings[$0],
                                                   target: eventTarget,
                                                   action: #selector(EventTarget.clickNavigationBarRightButton(_:)),
                                                   tag: $0)
            }
            
            
            if items.isEmpty {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
            } else {
                navigationItem.rightBarButtonItems = items
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
        component.progressContainerView.showProgress()
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
    
    open func showLoadDataFailView(_ text: String?) {
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
        component.showLoadDataFailView(component.loadDataFailContainerView, text: text)
        component.loadDataFailView?.delegate = self
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
        baseBusinessComponent.resetLoadDataFailViewPosition()
    }
    
    open var isShowingLoadDataFailView: Bool {
        guard let view = view,
            baseBusinessComponent.loadDataFailContainerView.superview === view else {
                return false
                
        }
        return baseBusinessComponent.isShowingLoadDataFailView
    }
    
    open func setLoadDataFail(_ url: String, retry: (() -> Void)?) {
        baseBusinessComponent.loadDataFailRetryCapability = url
        baseBusinessComponent.loadDataFailRetryHandler = retry
    }
    
    open var loadDataFailCapability: String? {
        return baseBusinessComponent.loadDataFailRetryCapability
    }
    
    open func clickDTLink(_ text: String?, url: URL? = nil) {
        
    }
    
    //MARK: - Http Request
    
    open func httpRequest(_ method: HTTP.Method<Any>,
                            params: ParamDictionary? = nil,
                            anonymous: Bool = false,
                            encoding: ParamEncoding? = nil,
                            headers: ParamHeaders? = nil,
                            success: ((Any) -> Void)? = nil,
                            bfail: ((Any) -> Void)? = nil,
                            fail: ((BFError) -> Void)? = nil) {
        var successHandler: ((String?, Any) -> Void)!
        if let success = success {
            successHandler = { [weak self] _, response in
                guard self != nil else { return }
                success(response)
            }
        } else {
            successHandler = { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondSuccess(url ?? "", response: response)
            }
        }
        
        var bfailHandler: ((String?, Any) -> Void)!
        if let bfail = bfail {
            bfailHandler = { [weak self] _, response in
                guard self != nil else { return }
                bfail(response)
            }
        } else {
            bfailHandler = { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondBfail(url ?? "", response: response)
            }
        }
        
        var failHandler: ((String?, BFError) -> Void)!
        if let fail = fail {
            failHandler = { [weak self] _, error in
                guard self != nil else { return }
                fail(error)
            }
        } else {
            failHandler = { [weak self] (url, error) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondFail(url ?? "", error: error)
            }
        }
        
        SRHttpManager.request(method,
                              sender: anonymous ? nil : String(pointer: self),
                              params: params,
                              encoding: encoding,
                              headers: headers,
                              success: successHandler,
                              bfail: bfailHandler,
                              fail: failHandler)
    }
    
    open func httpRespondSuccess(_ url: String, response: Any) {
        dismissProgress()
        if isFront {
            SRCommon.showAlert(title: (response as? JSON)?[HTTP.Key.Response.errorMessage].string,
                               type: .success)
        }
    }
    
    open func httpRespondBfail(_ url: String, response: Any) {
        dismissProgress()
        if url == loadDataFailCapability {
            showLoadDataFailView(logBFail(url,
                                          response: response,
                                          show: false))
        } else {
            logBFail(url, response: response)
        }
    }
    
    open func httpRespondFail(_ url: String, error: BFError) {
        dismissProgress()
        if url == loadDataFailCapability {
            showLoadDataFailView(error.errorDescription)
        } else {
            showToast(error.errorDescription)
        }
    }
    
    @discardableResult
    open func logBFail(_ url: String,
                         response: Any?,
                         show: Bool = true) -> String {
        var message = ""
        if let json = response as? JSON {
            message = NonNull.string(json[HTTP.Key.Response.errorMessage].string)
        }
        LogError(String(format: "request failed, url: %@\nreponse: %@\nmessage: %@",
                        url,
                        (response as? JSON)?.rawValue as? CVarArg ?? "",
                        message))
        if show {
            SRCommon.showAlert(message: message, type: .error)
        }
        return message
    }
    
    //MARK: SRLoadDataStateDelegate httpFailRetry
    
    open func retryLoadData() {
        dismissLoadDataFailView()
        baseBusinessComponent.loadDataFailRetryHandler?()
    }
    
    //MARK: DTAttributedTextContentViewDelegate
    
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
    
    //MARK: SRBaseViewControllerEventDelegate
    
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
        guard SRCommon.mutexTouch() else { return }
    }
    
    open func clickNavigationBarRightButton(_ button: UIButton) {
        guard SRCommon.mutexTouch() else { return }
    }
    
    open func didEndStateMachineEvent(_ notification: Notification) {
        guard let params = notification.object as? [AnyHashable : Any],
            let sender = params[Param.Key.sender] as? String,
            sender == String(pointer: self),
            let event = params[Param.Key.event] as? Int else {
                return
        }
        stateMachine.end(event)
    }
    
    open func clickDTLinkButton(_ sender: Any) {
        if let button = sender as? DTLinkButton {
            clickDTLink(button.guid, url: button.url)
        }
    }
    
    //MARK: SRStateMachineDelegate
    
    open func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        
    }
    
    open func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Int) {
        
    }
}

public protocol SRBaseViewControllerEventDelegate {
    func contentSizeCategoryDidChange()
    func deviceOrientationDidChange(_ sender: AnyObject?)
    func clickNavigationBarLeftButton(_ button: UIButton)
    func clickNavigationBarRightButton(_ button: UIButton)
    func didEndStateMachineEvent(_ notification: Notification)
    func clickDTLinkButton(_ sender: Any)
}
