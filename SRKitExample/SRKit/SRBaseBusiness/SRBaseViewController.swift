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
    SRStateMachineDelegate,
DTAttributedTextContentViewDelegate {
    private var _eventTarget: SRBaseViewController.EventTarget!
    open var eventTarget: SRBaseViewController.EventTarget {
        if _eventTarget == nil {
            _eventTarget = EventTarget(self)
        }
        return _eventTarget
    }
    
    //内部的事件响应类
    open class EventTarget: NSObject {
        public weak var viewController: SRBaseViewController?
        
        public init(_ viewController: SRBaseViewController) {
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
                self?.viewController?.srRegainTopLayout()
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
                viewController.srStateMachine.append(event)
            }
        }
        
        //FIXME: FOR DEBUG，由self push的WebpageViewController完成加载后会发出通知，触发状态机的完成事件
        //TODO: 此处若是其他程序调用而启动本应用（如在本应用被杀死的状态下点击退送消息），似乎会收不到该通知，等待解决
        @objc func didEndStateMachinePageEvent(_ notification: Notification) {
            if let event = notification.object as? SRKit.Event,
                let viewController = viewController,
                viewController === event.sender {
                viewController.stateMachine(viewController.srStateMachine, didEnd: event)
            }
        }
        
        @objc func clickDTLinkButton(_ sender: Any) {
            viewController?.clickDTLinkButton(sender)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.backgroundColor = .white
        srStateMachine.delegate = self
        srIsPageLongPressEnabled = true
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
        let appear = srNavigationBarAppear
        srNavigationBarAppear = appear
        NotifyDefault.add(eventTarget,
                          selector: #selector(EventTarget.deviceOrientationDidChange(_:)),
                          name: UIDevice.orientationDidChangeNotification,
                          object: nil)
        srRegainTopLayout()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        srRegainTopLayout()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if srIsTop {
            LogInfo("enter: \(NSStringFromClass(type(of: self)))")
        }
        
        let component = srBaseComponent
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            if srNavigationBarType == .system {
                if srNavigationBarAppear == .visible {
                    if navigationController.isNavigationBarHidden {
                        navigationController.setNavigationBarHidden(false, animated: false)
                    }
                    srEnsureNavigationBarHidden(false)
                } else if srNavigationBarAppear == .hidden {
                    if !navigationController.isNavigationBarHidden {
                        navigationController.setNavigationBarHidden(true, animated: false)
                    }
                    srEnsureNavigationBarHidden(true)
                }
            }
            
            Keyboard.manager = .iq
            SRKeyboardManager.shared.viewController = self
            
            component.isNavigationBarButtonsActive = true
            //let style = component.srPageBackGestureStyle
            //component.srPageBackGestureStyle = style
            let enabled = component.isPageLongPressEnabled
            component.isPageLongPressEnabled = enabled
        }
        
//        if !component.isViewDidAppear {
//            component.isViewDidAppear = true
//            if component.needShowProgress {
//                showProgress(component.progressMaskType)
//            }
//            performViewDidLoad()
//        } else {
//            resetProgressPosition()
//        }
//        resetLoadDataFailViewPosition()
        
//        if component.srNavigationBarBackgroundView.superview == view
//            && component.srNavigationBarBackgroundView.constraints.isEmpty {
//            constrain(component.srNavigationBarBackgroundView, self.car_topLayoutGuide) { (view, topLayoutGuide) in
//                view.top == view.superview!.top
//                view.leading == view.superview!.leading
//                view.trailing == view.superview!.trailing
//                view.bottom == topLayoutGuide.bottom
//            }
//        }
        
        if !component.isViewDidAppear {
            component.isViewDidAppear = true
            performViewDidLoad()
        }
        
        //广播“触发状态机的完成事件”的通知
        if let event = srEvent {
            #if DEBUG
            LogDebug(NSStringFromClass(type(of: self)) + ".\(#function), event: \(event)")
            #endif
            NotifyDefault.post(name: SRKit.didEndStateMachinePageEventNotification, object: srParams)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationController = navigationController,
            navigationController.viewControllers.contains(self) {
            Keyboard.manager = .unable
            SRKeyboardManager.shared.viewController = nil
            srBaseComponent.isNavigationBarButtonsActive = false
        }
        
        NotifyDefault.remove(self, name: UIDevice.orientationDidChangeNotification)
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    deinit {
        #if DEBUG
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        #endif
        NotifyDefault.remove(self)
        //SRHttpManager.shared.cancel(sender: String(pointer: self))
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Event
    
    /// 接收UIContentSizeCategory.didChangeNotification的通知做的响应，一般发生在系统字体变化后执行
    open func contentSizeCategoryDidChange() {
        
    }
    
    /// 设备方向发生变化时执行
    /// 执行viewWillAppear时接收UIDevice.orientationDidChangeNotification的通知做的响应，执行viewWillDisappear时移动通知响应
    /// 也可传入nil执行该函数，传入参数为nil时会强制通过，一般用于初始化或者强制刷新页面布局
    /// 子类覆盖该方法时，务必按照如下格式执行
    /// override func deviceOrientationDidChange(_ sender: AnyObject?) {
    ///      super.func deviceOrientationDidChange(sender)
    ///      guard srGuardDeviceOrientationDidChange(sender) else { return }
    ///      ... // your subclass code
    /// }
    open func deviceOrientationDidChange(_ sender: AnyObject?) {
        guard srGuardDeviceOrientationDidChange(sender) else { return }
//        //只在屏幕旋转时才更新位置
//        if sender != nil {
//            resetProgressPosition()
//            resetLoadDataFailViewPosition()
//        }
    }
    
    /// 导航栏左边按钮的点击响应，通过button的tag(0,1,2,3...)来判断按钮位置，为0时会执行srPopBack()退回上个页面
    open func clickNavigationBarLeftButton(_ button: UIButton) {
        guard MutexTouch else { return }
        if button.tag == 0 {
            srPopBack()
        }
    }
    
    /// 导航栏右边按钮的点击响应，通过button的tag(0,1,2,3...)来判断按钮位置
    open func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
    }
    
//    /// 状态机结束时的执行，
//    open func didEndStateMachineEvent(_ notification: Notification) {
//        if let event = notification.object as? SRKit.Event, self === event.sender {
//            stateMachine.end(event)
//        }
//    }
    
    /*open*/ func clickDTLinkButton(_ sender: Any) {
        if let button = sender as? DTLinkButton {
            clickDTLink(button.guid, url: button.url)
        }
    }
    
    //MARK: - Status Bar
    
    /// 设置为false后横屏状态下将默认显示状态栏，前提是info.plist设置View controller-based status bar appearance为YES
    /// 在某些不需要横屏状态下显示状态栏的页面，重写该方法，返回true
    override open var prefersStatusBarHidden: Bool { return false }
    
    /// 务必将Info.plist中的View controller-based status bar appearance设置为NO
    override open var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
    //MARK: - Autorotate Orientation
    
    /// return ShouldAutorotate
    override open var shouldAutorotate: Bool { return C.shouldAutorotate }
    
    /// return SupportedInterfaceOrientations
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return C.supportedInterfaceOrientations
    }
    
    /// return PreferredInterfaceOrientationForPresentation
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return C.preferredInterfaceOrientationForPresentation
    }
    
    //MARK: Page
    
    /// 在第一次执行viewDidAppear时执行该方法，一般执行用户初始化请求的操作
    open func performViewDidLoad() {
        
    }
    
    //MARK: Navigation Bar
    
    open override var title: String? {
        didSet {
            if srNavigationBarType == .system {
                super.title = title
            } else if srNavigationBarType == .sr {
                srBaseComponent.navigationBar.navigationItem.title = title
            }
        }
    }
    
    open var srNavigationItem: SRNavigationItem {
            return srBaseComponent.navigationItem
    }
    
    /// 设置默认的导航栏，title: 页面标题，left: 页面左上角按钮的设置，默认提供箭头图片
    open func setDefaultNavigationBar(_ title: String? = nil, left options: [NavigationBar.ButtonItemOption]? = nil) {
        setNavigationBar()
        if srNavigationBarType == .system {
            self.title = title
            if self !== navigationController?.viewControllers.first {
                navBarLeftButtonOptions = options ?? [.image(UIImage.srNamed("sr_page_back")!)]
            }
        } else if srNavigationBarType == .sr {
            srNavigationBar.title = title
            if self !== navigationController?.viewControllers.first {
                navBarLeftButtonOptions = options
                    ?? [.image(UIImage.srNamed(srNavigationBar.barStyle == .black
                        ? "sr_page_back_white" :
                        "sr_page_back")!)]
            }
        }
    }
    
    /// 设置导航栏的样式，包括标题文字样式，背景颜色、图片，及tintColor等
    open func setNavigationBar() {
        if srNavigationBarType == .system, let navigationController = navigationController {
            let srNavigationBar = navigationController.navigationBar
            srNavigationBar.titleTextAttributes = NavigationBar.titleTextAttributes
            srNavigationBar.setBackgroundImage(NavigationBar.backgroundImage, for: .default)
            srNavigationBar.tintColor = NavigationBar.tintColor
        } else if srNavigationBarType == .sr {
            srNavigationBar.titleTextAttributes = NavigationBar.titleTextAttributes
            srNavigationBar.setBackgroundImage(NavigationBar.backgroundImage, for: .default)
            srNavigationBar.tintColor = NavigationBar.tintColor
        }
    }
    
    /// 导航栏左边按钮的设定，使用navBarLeftButtonOptions = [...]的方式来更改导航栏的左边按钮
    open var navBarLeftButtonOptions: [NavigationBar.ButtonItemOption]? {
        didSet {
            guard let options = navBarLeftButtonOptions, !options.isEmpty else { //左边完全无按钮
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                return
            }
            
            //再添加新的按钮
            let items = (0 ..< options.count).compactMap {
                NavigationBar.buttonItem(options[$0],
                                         target: eventTarget,
                                         action: #selector(EventTarget.clickNavigationBarLeftButton(_:)),
                                         tag: $0,
                                         useCustomView: srNavigationBarType != .system)
            }
            if srNavigationBarType == .system {
                if items.isEmpty {
                    navigationItem.leftBarButtonItem = nil
                    navigationItem.leftBarButtonItems = nil
                } else if items.count == 1 {
                    navigationItem.leftBarButtonItem = items.first
                } else {
                    navigationItem.leftBarButtonItems = items
                }
            } else if srNavigationBarType == .sr {
                srNavigationItem.leftBarButtonItems = items
            }
        }
    }
    
    /// 导航栏右边按钮的设定，使用navBarRightButtonOptions = [...]的方式来更改导航栏的右边按钮
    open var navBarRightButtonOptions: [NavigationBar.ButtonItemOption]? {
        didSet {
            guard let options = navBarRightButtonOptions, !options.isEmpty else {
                navigationItem.rightBarButtonItem = nil
                navigationItem.rightBarButtonItems = nil
                return
            }
            
            let items = (0 ..< options.count).compactMap {
                NavigationBar.buttonItem(options[$0],
                                         target: eventTarget,
                                         action: #selector(EventTarget.clickNavigationBarRightButton(_:)),
                                         tag: $0,
                                         useCustomView: srNavigationBarType != .system)
            }
            
            if srNavigationBarType == .system {
                if items.isEmpty {
                    navigationItem.rightBarButtonItem = nil
                    navigationItem.rightBarButtonItems = nil
                } else {
                    navigationItem.rightBarButtonItems = items
                }
            } else if srNavigationBarType == .sr {
                srNavigationItem.rightBarButtonItems = items
            }
        }
    }
    
    //MARK: -
    open var topLayoutSubviewHeightConstraint: NSLayoutConstraint? {
        return srBaseComponent.topLayoutSubviewHeightConstraint
    }
    
    open var topLayoutSubview: UIView? {
        get {
            return srBaseComponent.topLayoutSubview
        }
        set {
            srBaseComponent.topLayoutSubview = newValue
        }
    }
    
    //MARK: Progress
    
    /// 加载数据的等待转圈
//    open func showProgress(_ maskType: UIView.SRProgressComponent.MaskType = .clear,
//                             immediately: Bool = false) {
//        let component = srBaseComponent
//
//        if !immediately && !component.isViewDidAppear {
//            component.needShowProgress = true
//            component.progressMaskType = maskType
//            return
//        }
//
//        view.insertSubview(component.progressContainerView, at: view.subviews.count)
//        switch srNavigationBarType {
//        case .system:
//            if #available(iOS 11.0, *) {
//                component.progressContainerView.frame =
//                    CGRect(0,
//                           view.safeAreaInsets.top,
//                           view.bounds.size.width,
//                           view.bounds.size.height - view.safeAreaInsets.top)
//            } else {
//                component.progressContainerView.frame =
//                    CGRect(0,
//                           topLayoutGuide.length,
//                           view.bounds.size.width,
//                           view.bounds.size.height - topLayoutGuide.length)
//            }
//
//        case .sr:
//            let y = srNavigationBar.isHidden ? 0 : srNavigationBar.bottom
//            component.progressContainerView.frame =
//                CGRect(0,
//                       y,
//                       view.bounds.size.width,
//                       view.bounds.size.height - y)
//        }
//
//        //在此可以改变默认的加载转圈样式
//        component.progressContainerView.showProgress([.progressType(.infinite),
//                                                      .maskType(maskType)])
//    }
    
    /// 加载数据的等待转圈
    open func showProgress(_ maskType: UIView.SRProgressComponent.MaskType = .clear,
                           insets: UIEdgeInsets? = nil) {
        let component = srBaseComponent
        let containerView = component.progressContainerView
        component.progressMaskType = maskType
        containerView.removeFromSuperview()
        view.insertSubview(containerView, at: view.subviews.count)
        if let insets = insets {
            constrain(containerView) { view in
                view.edges == inset(view.superview!.edges, insets)
            }
        } else {
//            constrain(containerView) { [weak self] (view, self?.topLayoutSubview) in
//                view.edges == inset(view.superview!.edges,
//                                    UIEdgeInsets(srNavigationHeaderHeight, 0, 0, 0))
//            }
            constrain(containerView, topLayoutSubview ?? UIView()) { (view, topLayoutSubview) in
                view.top == topLayoutSubview.bottom
                view.leading == view.superview!.leading
                view.trailing == view.superview!.trailing
                view.bottom == view.superview!.bottom
            }
        }
        //在此可以改变默认的加载转圈样式
        containerView.showProgress([.progressType(.infinite), .maskType(maskType)])
    }

    open func dismissProgress() {
        dismissProgress(false)
    }
    
    open func dismissProgress(_ animated: Bool) {
        guard isShowingProgress else { return }
        srBaseComponent.progressContainerView.dismissProgress(animated)
        srBaseComponent.progressContainerView.removeFromSuperview()
    }
    
//    /// viewDidAppear中执行
//    open func resetProgressPosition() {
//        guard isShowingProgress else { return }
//
//        let component = srBaseComponent
//        switch srNavigationBarType {
//        case .system:
//            if #available(iOS 11.0, *) {
//                component.progressContainerView.frame =
//                    CGRect(0,
//                           view.safeAreaInsets.top,
//                           view.bounds.size.width,
//                           view.bounds.size.height - view.safeAreaInsets.top)
//            } else {
//                component.progressContainerView.frame =
//                    CGRect(0,
//                           topLayoutGuide.length,
//                           view.bounds.size.width,
//                           view.bounds.size.height - topLayoutGuide.length)
//            }
//
//        case .sr:
//            let y = srNavigationBar.isHidden ? 0 : srNavigationBar.bottom
//            component.progressContainerView.frame =
//                CGRect(0,
//                       y,
//                       view.bounds.size.width,
//                       view.bounds.size.height - y)
//        }
//        component.progressContainerView.resetProgressPosition()
//    }
    
    open var isShowingProgress: Bool {
        guard let view = view,
            srBaseComponent.progressContainerView.superview === view else {
                return false
        }
        return srBaseComponent.progressContainerView.isShowingProgress
    }
    
    //MARK: Load Data Fail
    
//    /// 展示加载数据失败时的提示视图，一般配合setLoadDataFail方法使用
//    /// 一般使用场景为刚进入页面时发送初始化请求，请求返回失败后页面展示错误提示视图
//    open func showLoadDataFailView(_ text: String?, image: UIImage? = nil) {
//        guard let view = view else { return }
//
//        let component = srBaseComponent
//        view.insertSubview(component.loadDataFailContainerView, at: view.subviews.count)
//        switch srNavigationBarType {
//        case .system:
//            if #available(iOS 11.0, *) {
//                component.loadDataFailContainerView.frame =
//                    CGRect(0,
//                           view.safeAreaInsets.top,
//                           view.bounds.size.width,
//                           view.bounds.size.height - view.safeAreaInsets.top)
//            } else {
//                component.loadDataFailContainerView.frame =
//                    CGRect(0,
//                           topLayoutGuide.length,
//                           view.bounds.size.width,
//                           view.bounds.size.height - topLayoutGuide.length)
//            }
//
//        case .sr:
//            let y = srNavigationBar.isHidden ? 0 : srNavigationBar.bottom
//            component.loadDataFailContainerView.frame =
//                CGRect(0,
//                       y,
//                       view.bounds.size.width,
//                       view.bounds.size.height - y)
//        }
//        component.showLoadDataFailView(text, image: image ?? UIImage.srNamed("sr_load_data_fail")!)
//    }
    
    /// 展示加载数据失败时的提示视图，一般配合setLoadDataFail方法使用
    /// 一般使用场景为刚进入页面时发送初始化请求，请求返回失败后页面展示错误提示视图
    open func showLoadDataFailView(_ text: String?,
                                   image: UIImage? = nil,
                                   insets: UIEdgeInsets? = nil) {
        let component = srBaseComponent
        let containerView = component.loadDataFailContainerView
        containerView.removeFromSuperview()
        view.insertSubview(containerView, at: view.subviews.count)
        if let insets = insets {
            constrain(containerView) { view in
                view.edges == inset(view.superview!.edges, insets)
            }
        } else {
//            constrain(containerView) { view in
//                view.edges == inset(view.superview!.edges,
//                                    UIEdgeInsets(srNavigationHeaderHeight, 0, 0, 0))
//            }
            constrain(containerView, topLayoutSubview ?? UIView()) { (view, topLayoutSubview) in
                view.top == topLayoutSubview.bottom
                view.leading == view.superview!.leading
                view.trailing == view.superview!.trailing
                view.bottom == view.superview!.bottom
            }
        }
        component.showLoadDataFailView(text, image: image ?? UIImage.srNamed("sr_load_data_fail")!)
    }
    
    open func dismissLoadDataFailView() {
        guard isShowingLoadDataFailView else { return }
        srBaseComponent.loadDataFailContainerView.removeFromSuperview()
        srBaseComponent.dismissLoadDataFailView()
    }
    
//    /// viewDidAppear中执行
//    open func resetLoadDataFailViewPosition() {
//        guard isShowingLoadDataFailView else { return }
//
//        let component = srBaseComponent
//        switch srNavigationBarType {
//        case .system:
//            if #available(iOS 11.0, *) {
//                component.loadDataFailContainerView.frame =
//                    CGRect(0,
//                           view.safeAreaInsets.top,
//                           view.bounds.size.width,
//                           view.bounds.size.height - view.safeAreaInsets.top)
//            } else {
//                component.loadDataFailContainerView.frame =
//                    CGRect(0,
//                           topLayoutGuide.length,
//                           view.bounds.size.width,
//                           view.bounds.size.height - topLayoutGuide.length)
//            }
//
//        case .sr:
//            let y = srNavigationBar.isHidden ? 0 : srNavigationBar.bottom
//            component.loadDataFailContainerView.frame =
//                CGRect(0,
//                       y,
//                       view.bounds.size.width,
//                       view.bounds.size.height - y)
//        }
//    }
    
    open var isShowingLoadDataFailView: Bool {
        return srBaseComponent.loadDataFailContainerView.superview === view
            && srBaseComponent.isShowingLoadDataFailView
    }
    
    /// 一般使用场景为刚进入页面时发送初始化请求，请求返回失败后页面展示错误提示视图，点击错误提示视图后执行retry()
    open func setLoadDataFail(_ request: SRHTTP.Request, retry: (() -> Void)?) {
        srBaseComponent.loadDataFailRetryRequest = request
        srBaseComponent.loadDataFailRetryHandler = retry
    }
    
    open var loadDataFailRequest: SRHTTP.Request? {
        return srBaseComponent.loadDataFailRetryRequest
    }
    
    /// 富文本控件DTAttributedTextContentView及子类点击链接时的响应
    open func clickDTLink(_ text: String?, url: URL? = nil) {
        
    }
    
    //MARK: - Http Request
    
    open var httpManager: SRHttpManager? = nil
    
    open func httpRequest(_ request: SRHTTP.Request,
                            success: ((Any) -> Void)? = nil,
                            failure: ((SRHTTP.Result<Any>.Failure<Any>) -> Void)? = nil) {
        guard let httpManager = httpManager else { return }
        
        var successHandler: ((Any) -> Void)!
        if let success = success {
            successHandler = success
        } else {
            successHandler = { [weak self] response in
                self?.httpRespond(success: response, request: request)
            }
        }
        
        var failHandler: ((SRHTTP.Result<Any>.Failure<Any>) -> Void)!
        if let failure = failure {
            failHandler = failure
        } else {
            failHandler = { [weak self] result in
                self?.httpRespond(failure: result, request: request)
            }
        }
        
        var array: [SRHTTP.Request.Option]?
        if let options = request.options {
            array = options
            array!.append(.sender(String(pointer: self)))
        } else {
            array = [.sender(String(pointer: self))]
        }
        
        httpManager.request(request, success: successHandler, failure: failHandler)
    }
    
    open func httpRespond(success response: Any, request: SRHTTP.Request? = nil) {
        dismissProgress()
        if srIsTop {
            SRAlert.show((response as? JSON)?[SRHTTP.Key.Response.message].string,
                         type: .success)
        }
    }
    
    open func httpRespond(failure result: SRHTTP.Result<Any>.Failure<Any>, request: SRHTTP.Request? = nil) {
        dismissProgress()
        if request?.method == loadDataFailRequest?.method && request?.url == loadDataFailRequest?.url {
            showLoadDataFailView(result.errorMessage)
        } else {
            srShowToast(result.errorMessage)
        }
    }
    
    //MARK: - DTAttributedTextContentViewDelegate
    
    /// DTAttributedTextContentViewDelegate
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
    
    /// SRStateMachineDelegate
    open func stateMachine(_ stateMachine: SRStateMachine, didFire event: SRKit.Event) {
        
    }
    
    open func stateMachine(_ stateMachine: SRStateMachine, didEnd event: SRKit.Event) {
        
    }
}
