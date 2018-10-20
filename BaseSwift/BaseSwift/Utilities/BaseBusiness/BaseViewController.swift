//
//  BaseViewController.swift
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

public class BaseViewController: UIViewController,
    UIScrollViewDelegate,
    LoadDataStateDelegate,
    SRStateMachineDelegate,
DTAttributedTextContentViewDelegate {    
    override public func viewDidLoad() {
        super.viewDidLoad()
        stateMachine.delegate = self
        NotifyDefault.add(self,
                          selector: .contentSizeCategoryDidChange,
                          name: .UIContentSizeCategoryDidChange)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
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
        
        NotifyDefault.add(self,
                          selector: .deviceOrientationDidChange,
                          name: .UIDeviceOrientationDidChange,
                          object: nil)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
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
            && component.navigationBarBackgroundView.constraints.count == 0 {
            constrain(component.navigationBarBackgroundView, self.car_topLayoutGuide) { (view, topLayoutGuide) in
                view.top == view.superview!.top
                view.leading == view.superview!.leading
                view.trailing == view.superview!.trailing
                view.bottom == topLayoutGuide.bottom
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            Keyboard.manager = .unable
            SRKeyboardManager.shared.viewController = nil
            baseBusinessComponent.isNavigationBarButtonsActive = false
        }
        
        NotifyDefault.remove(self, name: .UIDeviceOrientationDidChange)
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
        let sender = String(pointer: self)
        DispatchQueue.global(qos: .default).async {
            BF.callBusiness(BF.businessId(.http, HttpCapability.function(.clearRequests).funcId),
                            params: sender)
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    public func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        //只在屏幕旋转时才更新位置
        if sender != nil {
            resetProgressPosition()
            resetLoadDataFailViewPosition()
        }
    }
    
    public func contentSizeCategoryDidChange() {
        
    }
    
    //MARK: - Status Bar
    
    //设置为false后横屏状态下将默认显示状态栏，前提是info.plist设置View controller-based status bar appearance为YES
    //在某些不需要横屏状态下显示状态栏的页面，重写该方法，返回true
    override public var prefersStatusBarHidden: Bool { return false }
    
    //务必将Info.plist中的View controller-based status bar appearance设置为NO
    override public var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
    //MARK: - Autorotate Orientation
    
    override public var shouldAutorotate: Bool { return ShouldAutorotate }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return SupportedInterfaceOrientations
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return PreferredInterfaceOrientationForPresentation
    }
    
    //MARK: Page
    
    public func performViewDidLoad() {
        
    }
    
    //MARK: Navigation Bar
    
    public func defaultNavigationBar(_ title: String? = nil) {
        defaultNavigationBar(title: title, leftImage: nil)
    }
    
    public func defaultNavigationBar(title: String?, leftImage image: UIImage?) {
        if let title = title {
            self.title = title
        }
        
        navigationBarBackgroundAlpha = NavigartionBar.backgroundBlurAlpha
        navigationBarTintColor = NavigartionBar.tintColor
        initNavigationBar()
        
        if let navigationController = navigationController {
            let backImage = image == nil ? UIImage("page_back") : image
            navigationController.navigationBar.backIndicatorImage = backImage
            navigationController.navigationBar.backIndicatorTransitionMaskImage = backImage
            let backBarButtonItem = UIBarButtonItem()
            backBarButtonItem.title = " "
            navigationItem.backBarButtonItem = backBarButtonItem
            UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(0, -200.0),
                                                                              for: .default)
        }
    }
    
    public func initNavigationBar() {
        guard let navigationController = navigationController else { return }
        
        let navigationBar = navigationController.navigationBar
        navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white,
                                             .font : UIFont.heavyTitle]
        //navigationBar.tintColor = UIColor.white
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.backgroundColor = UIColor.clear
    }
    
    public var navBarLeftButtonSettings: [[NavigartionBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarLeftButtonSettings, settings.count > 0 else { //左边完全无按钮
                navigationController?.navigationBar.backIndicatorImage = nil
                navigationController?.navigationBar.backIndicatorTransitionMaskImage = nil
                navigationItem.backBarButtonItem = nil
                navigationItem.leftBarButtonItems = nil
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                return
            }
            
            if settings.first!.count == 0 { //使用默认的返回
                navigationController?.navigationBar.backIndicatorImage = UIImage("page_back")
                navigationController?.navigationBar.backIndicatorTransitionMaskImage =
                    UIImage("page_back")
                navigationItem.backBarButtonItem =
                    UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
                
                let items = (1 ..< settings.count).compactMap {
                    BaseCommon.navigationBarButtonItem(settings[$0],
                                                       target: self,
                                                       action: .clickNavigationBarLeftButton,
                                                       tag: $0)
                }
                
                //再添加新的按钮
                if items.count == 0 {
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
                    BaseCommon.navigationBarButtonItem(settings[$0],
                                                       target: self,
                                                       action: .clickNavigationBarLeftButton,
                                                       tag: $0)
                }
                
                navigationItem.backBarButtonItem = nil
                if items.count == 0 {
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
    
    public var navBarRightButtonSettings: [[NavigartionBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarRightButtonSettings, settings.count > 0 else {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
                return
            }
            
            let items = (0 ..< settings.count).compactMap {
                BaseCommon.navigationBarButtonItem(settings[$0],
                                                   target: self,
                                                   action: .clickNavigationBarRightButton,
                                                   tag: $0)
            }
            
            
            if items.count == 0 {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
            } else {
                navigationItem.rightBarButtonItems = items
            }
        }
    }
    
    public func clickNavigationBarLeftButton(_ button: UIButton) {
        guard BaseCommon.mutexTouch() else { return }
    }
    
    public func clickNavigationBarRightButton(_ button: UIButton) {
        guard BaseCommon.mutexTouch() else { return }
    }
    
    //MARK: Progress
    
    public func showProgress() {
        showProgress(.clear, immediately: false)
    }
    
    public func showProgress(_ maskType: UIView.ProgressComponent.MaskType) {
        showProgress(maskType, immediately: false)
    }
    
    public func showProgress(_ maskType: UIView.ProgressComponent.MaskType,
                             immediately: Bool) {
        guard let view = self.view else { return }
        
        let component = baseBusinessComponent
        
        if !immediately && !component.isViewDidAppear {
            component.needShowProgress = true
            component.progressMaskType = maskType
            return
        }
        
        component.progressContainerView.frame =
            CGRect(0,
                   topLayoutGuide.length,
                   view.bounds.size.width,
                   view.bounds.size.height - topLayoutGuide.length - bottomLayoutGuide.length)
        view.insertSubview(component.progressContainerView, at: view.subviews.count)
        
        //在此改变默认的加载转圈样式
        component.progressContainerView.showProgress()
        //component.progressContainerView.showProgress(maskType,
        //                                             progressType: .srvRing,
        //                                             options: [ProgressOptionKey.showPercentage : true])
        //component.progressContainerView.showProgress(maskType,
        //                                             progressType: .m13Ring,
        //                                             options: [ProgressOptionKey.shouldAutorotate : shouldAutorotate])
    }
    
    public func dismissProgress() {
        dismissProgress(false)
    }
    
    public func dismissProgress(_ animated: Bool) {
        guard isShowingProgress else {
            if baseBusinessComponent.needShowProgress {
                baseBusinessComponent.needShowProgress = false
            }
            return
        }
        
        baseBusinessComponent.progressContainerView.dismissProgress(animated)
        baseBusinessComponent.progressContainerView.removeFromSuperview()
    }
    
    public func resetProgressPosition() {
        guard isShowingProgress else { return }
        
        baseBusinessComponent.progressContainerView.frame =
            CGRect(0,
                   topLayoutGuide.length,
                   view!.bounds.size.width,
                   view!.bounds.size.height - topLayoutGuide.length - bottomLayoutGuide.length)
        baseBusinessComponent.progressContainerView.resetProgressPosition()
    }
    
    public var isShowingProgress: Bool {
        guard let view = view,
            baseBusinessComponent.progressContainerView.superview === view else {
                return false
        }
        return baseBusinessComponent.progressContainerView.isShowingProgress
    }
    
    //MARK: Load Data Fail
    
    public func showLoadDataFailView(_ text: String?) {
        guard let view = view else { return }
        
        let component = baseBusinessComponent
        component.loadDataFailContainerView.frame =
            CGRect(0,
                   topLayoutGuide.length,
                   view.bounds.size.width,
                   view.bounds.size.height - topLayoutGuide.length - bottomLayoutGuide.length)
        view.insertSubview(component.loadDataFailContainerView, at: view.subviews.count)
        component.showLoadDataFailView(component.loadDataFailContainerView, text: text)
        component.loadDataFailView?.delegate = self
    }
    
    public func dismissLoadDataFailView() {
        guard isShowingLoadDataFailView else { return }
        baseBusinessComponent.loadDataFailContainerView.removeFromSuperview()
        baseBusinessComponent.dismissLoadDataFailView()
    }
    
    public func resetLoadDataFailViewPosition() {
        guard isShowingLoadDataFailView else { return }
        baseBusinessComponent.loadDataFailContainerView.frame =
            CGRect(0,
                   topLayoutGuide.length,
                   view!.bounds.size.width,
                   view!.bounds.size.height - topLayoutGuide.length - bottomLayoutGuide.length)
        baseBusinessComponent.resetLoadDataFailViewPosition()
    }
    
    public var isShowingLoadDataFailView: Bool {
        guard let view = view,
            baseBusinessComponent.loadDataFailContainerView.superview === view else {
                return false
                
        }
        return baseBusinessComponent.isShowingLoadDataFailView
    }
    
    public func setLoadDataFail(_ capability: HttpCapability, retry: (() -> Void)?) {
        baseBusinessComponent.loadDataFailRetryCapability = capability
        baseBusinessComponent.loadDataFailRetryHandler = retry
    }
    
    public var loadDataFailCapability: HttpCapability? {
        return baseBusinessComponent.loadDataFailRetryCapability
    }
    
    //MARK: State Machine
    
    public func didEndStateMachineEvent(_ notification: Notification) {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        guard let params = notification.object as? [AnyHashable : Any],
            let sender = params[ParamKey.sender] as? String,
            sender == String(pointer: self),
            let event = params[ParamKey.event] as? Int else {
                return
        }
        stateMachine.end(event)
    }
    
    //MARK: DTCoreText
    
    func clickDTLinkButton(_ sender: Any) {
        let button = sender as? DTLinkButton
        clickDTLink(button?.tagString, url: button?.url)
    }
    
    public func clickDTLink(_ text: String?, url: URL? = nil) {
        
    }
    
    //MARK: - Http Request
    
    public func httpRequest(_ capability: HttpCapability,
                            _ params: ParamDictionary? = nil,
                            anonymous: Bool = false,
                            url: String? = nil,
                            encoding: ParamEncoding? = nil,
                            headers: ParamHeaders? = nil,
                            success: ((Any) -> Void)? = nil,
                            bfail: ((Any) -> Void)? = nil,
                            fail: ((BFError) -> Void)? = nil) {
        var successHandler: ((HttpCapability, Any) -> Void)!
        if let success = success {
            successHandler = { [weak self] _, response in
                guard self != nil else { return }
                success(response)
            }
        } else {
            successHandler = { [weak self] (capability, response) in
                guard let strongSelf = self else { return }
                strongSelf.dismissProgress()
                if strongSelf.isFront {
                    Common.showAlert(title: (response as? JSON)?[HttpKey.Response.errorMessage].string,
                                     type: .success)
                }
            }
        }
        
        var bfailHandler: ((HttpCapability, Any) -> Void)!
        if let bfail = bfail {
            bfailHandler = { [weak self] _, response in
                guard self != nil else { return }
                bfail(response)
            }
        } else {
            bfailHandler = { [weak self] (capability, response) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondBfail(capability, response: response)
            }
        }
        
        var failHandler: ((HttpCapability, BFError) -> Void)!
        if let fail = fail {
            failHandler = { [weak self] _, error in
                guard self != nil else { return }
                fail(error)
            }
        } else {
            failHandler = { [weak self] (capability, error) in
                guard let strongSelf = self else { return }
                strongSelf.httpRespondFail(capability, error: error)
            }
        }
        
        HttpManager.shared.request(capability,
                                   sender: anonymous ? nil : String(pointer: self),
                                   params: params,
                                   url: url,
                                   encoding: encoding,
                                   headers: headers,
                                   success: successHandler,
                                   bfail: bfailHandler,
                                   fail: failHandler)
    }
    
    public func httpRespondBfail(_ capability: HttpCapability, response: Any) {
        dismissProgress()
        if capability == loadDataFailCapability {
            showLoadDataFailView(logBFail(capability,
                                          response: response,
                                          show: false))
        } else {
            logBFail(capability, response: response)
        }
    }
    
    public func httpRespondFail(_ capability: HttpCapability, error: BFError) {
        dismissProgress()
        if capability == loadDataFailCapability {
            showLoadDataFailView(error.errorDescription)
        } else {
            showToast(error.errorDescription)
        }
    }
    
    @discardableResult
    public func logBFail(_ capability: HttpCapability,
                         response: Any?,
                         show: Bool = true) -> String {
        var message = EmptyString
        if let json = response as? JSON {
            message = NonNull.string(json[HttpKey.Response.errorMessage].string)
        }
        LogError(String(format: "request failed, api: %@\nreponse: %@\nmessage: %@",
                        HttpDefine.api(capability)!,
                        (response as? JSON)?.rawValue as? CVarArg ?? EmptyString,
                        message))
        if show {
            Common.showAlert(message: message, type: .error)
        }
        return message
    }
    
    //MARK: LoadDataStateDelegate httpFailRetry
    
    public func retryLoadData() {
        dismissLoadDataFailView()
        baseBusinessComponent.loadDataFailRetryHandler?()
    }
    
    //MARK: DTAttributedTextContentViewDelegate
    
    public func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!,
                                          viewFor string: NSAttributedString!,
                                          frame: CGRect) -> UIView! {
        let attributes = string.attributes(at: 0, effectiveRange: nil)
        let url = attributes[NSAttributedStringKey(DTLinkAttribute)]
        let identifier = attributes[NSAttributedStringKey(DTGUIDAttribute)]
        
        let button = DTLinkButton(frame: frame)
        button.url = url as? URL
        button.minimumHitSize = CGSize(25.0, 25.0) // adjusts it's bounds so that button is always large enough
        button.guid = identifier as? String
        
        // get image with normal link text
        var image = attributedTextContentView.contentImage(withBounds: frame,
                                                           options: .default)
        button.setImage(image, for: .normal)
        
        // get image for highlighted link text
        image = attributedTextContentView.contentImage(withBounds: frame,
                                                       options: .drawLinksHighlighted)
        button.setImage(image, for: .highlighted)
        
        // use normal push action for opening URL
        button.tagString = string.string
        button.clicked(self, action: .clickDTLinkButton)
        
        return button;
    }
    
    //MARK: - UIScrollViewDelegate
    
    //为了不因图片加载而使得滑动列表时发生卡顿，这里在滑动列表时禁止了图片加载
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        SDWebImageManager.shared().imageDownloader?.setSuspended(true)
    }
    
    //列表停止滑动后恢复图片下载
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
        if !decelerate {
            SDWebImageManager.shared().imageDownloader?.setSuspended(false)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        SDWebImageManager.shared().imageDownloader?.setSuspended(false)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        SDWebImageManager.shared().imageDownloader?.setSuspended(false)
    }
    
    //MARK: SRStateMachineDelegate
    
    public func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        switch event {
            //FIXME: FOR DEBUG，在所有的视图上弹出网页视图
            //也可以处理其他全局型的业务，如跳转到聊天页面
        //此处业务不是必需的，可按照具体需求操作
        case Event.Option.openWebpage:
            guard isFront else { break }
            
            var string = EmptyString
            if let url = Common.currentActionParams()?[ParamKey.url] as? String {
                string = url
            }
            if let vc = self as? WebpageViewController {
                Common.clearPops()
                Common.clearModals()
                var params = [ParamKey.url : URL(string: string)!] as ParamDictionary
                if let title = Common.currentActionParams()?[ParamKey.title] as? String {
                    params[ParamKey.title] = title
                }
                vc.params = params
                vc.reload()
                stateMachine.end(event)
            } else {
                NotifyDefault.add(self,
                                  selector: .didEndStateMachineEvent,
                                  name: Notification.Name.Base.didEndStateMachineEvent)
                Common.clearPops()
                Common.clearModals(viewController: self)
                showWebpage(URL(string: string)!,
                            title: Common.currentActionParams()?[ParamKey.title] as? String,
                            params: [ParamKey.sender : String(pointer: self),
                                     ParamKey.event : event])
            }
        default:
            break
        }
    }
    
    public func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Int) {
        Common.clearActionParams(event)
        
        switch event {
        case Event.Option.openWebpage:
            NotifyDefault.remove(self, name: Notification.Name.Base.didEndStateMachineEvent)
        default:
            break
        }
    }
}

//MARK: - State Machine

extension SRStateMachine {
    //FIXME: FOR DEBUG，Event.Option一般都是即时发生的，新的Option加入等待队列时，旧的Option会被覆盖
    //如首页正在展示引导页（当前事件进行中），此时来了推送消息，点击推送消息，将推送消息里的action1加入到等待队列中。
    //若此时来了新推送消息，或者被其他应用所调用，转化成新的action2，在加入到等待队列中之前应该将action1给删除
    //这样引导页展示完毕后（当前事件已完成）就直接执行action2，而非先执行action1，再执行action2
    public func append(option: Int) {
        guard !events.contains(option) else {
            return
        }
        
        Event.Option.range.forEach { remove($0) }
        append(option)
    }
}

//MARK: - Adapter Selector

public extension BaseViewController {
    @objc func contentSizeCategoryDidChangeSelector() {
        contentSizeCategoryDidChange()
    }
    
    @objc func deviceOrientationDidChangeSelector(_ sender: AnyObject?) {
        guard guardDeviceOrientationDidChange(sender) else { return }
        deviceOrientationDidChange(sender)
    }
    
    @objc func clickNavigationBarLeftButtonSelector(_ button: UIButton) {
        clickNavigationBarLeftButton(button)
    }
    
    @objc func clickNavigationBarRightButtonSelector(_ button: UIButton) {
        clickNavigationBarRightButton(button)
    }
    
    //FIXME: FOR DEBUG，由self push的WebpageViewController完成加载后会发出通知，触发状态机的完成事件
    //TODO: 此处若是其他程序调用而启动本应用（如在本应用被杀死的状态下点击退送消息），似乎会收不到该通知，等待解决
    @objc func didEndStateMachineEventSelector(_ notification: Notification) {
        didEndStateMachineEvent(notification)
    }
    
    @objc func clickDTLinkButtonSelector(_ sender: Any) {
        clickDTLinkButton(sender)
    }
}

//MARK: - Syntax Sugar Selector

public extension Selector {
    static let contentSizeCategoryDidChange =
        #selector(BaseViewController.contentSizeCategoryDidChangeSelector)
    static let deviceOrientationDidChange =
        #selector(BaseViewController.deviceOrientationDidChangeSelector(_:))
    static let clickNavigationBarLeftButton =
        #selector(BaseViewController.clickNavigationBarLeftButtonSelector(_:))
    static let clickNavigationBarRightButton =
        #selector(BaseViewController.clickNavigationBarRightButtonSelector(_:))
    static let didEndStateMachineEvent =
        #selector(BaseViewController.didEndStateMachineEventSelector(_:))
    static let clickDTLinkButton =
        #selector(BaseViewController.clickDTLinkButtonSelector(_:))
}
