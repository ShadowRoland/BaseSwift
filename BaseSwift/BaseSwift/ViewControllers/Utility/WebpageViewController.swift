//
//  WebpageViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/11.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Cartography
import WebKit
import M13ProgressSuite

let WebpageBackGestureStyle = "WebpageBackGestureStyle"

class WebpageViewController: BaseViewController,
WKNavigationDelegate,
WKUIDelegate,
SRShareToolDelegate {
    private(set) var url: URL?
    private(set) var currentUrl: URL?
    
    private var webView: WKWebView!
    private var progressView: M13ProgressViewBar!
    private var canGoBack = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        defaultNavigationBar(title: "Loading ...".localized,
                             leftImage: UIImage(named: "close_left"))
        setNavigationBarRightButtonItems()
        initView()
        reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let enumInt = params[WebpageBackGestureStyle] as? UInt {
            let style = BaseBusinessComponent.PageBackGestureStyle(rawValue: enumInt)
            if style != baseBusinessComponent.pageBackGestureStyle {
                pageBackGestureStyle = style
            }
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        webView = WKWebView()
        view.addSubview(webView)
        constrain(webView) { $0.edges == inset($0.superview!.edges, 0) }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.new, context: nil)
        webView.addObserver(self, forKeyPath:"title", options:.new, context:nil)
        
        progressView = M13ProgressViewBar()
        progressView.showPercentage = false
        progressView.progressBarThickness = 3.0
        view.addSubview(progressView)
    }
    
    func setNavigationBarLeftButtonItems() {
        var backSetting = NavigartionBar.buttonFullSetting //获取带全属性的按钮字典
        backSetting[.style] = NavigartionBar.ButtonItemStyle.image //设置按钮的风格为纯图片
        backSetting[.image] =
            canGoBack ? UIImage(named: "page_back") : UIImage(named: "close_left")
        
        if webView.canGoForward {
            var forwardSetting = NavigartionBar.buttonFullSetting
            forwardSetting[.style] = NavigartionBar.ButtonItemStyle.image //设置按钮的风格为纯图片
            forwardSetting[.image] = UIImage(named: "page_forward_left")
            navBarLeftButtonSettings = [backSetting, forwardSetting]
        } else {
            navBarLeftButtonSettings = [backSetting]
        }
    }
    
    func setNavigationBarRightButtonItems() {
        var setting = NavigartionBar.buttonFullSetting
        setting[.style] = NavigartionBar.ButtonItemStyle.image
        setting[.image] = UIImage(named: "more")
        navBarRightButtonSettings = [setting]
    }

    func reload() {
        webView.stopLoading()
        if let title = params[ParamKey.title] as? String {
            self.title = title
        }
        if let url = params[ParamKey.url] as? URL {
            self.url = url
            currentUrl = url
            webView.load(URLRequest(url: url))
        }
    }
    
    //MARK: - Autorotate Orientation

    override public func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        //只在屏幕旋转时才更新位置
        if sender != nil && !progressView.isHidden {
            progressView.frame =
                CGRect(0, topLayoutGuide.length, view.width, progressView.progressBarThickness)
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        //FIXME: FOR DEBUG，广播“触发状态机的完成事件”的通知
        if let sender = params[ParamKey.sender] as? String,
            let event = params[ParamKey.event] as? Int {
            LogDebug(NSStringFromClass(type(of: self)) + ".\(#function), sender: \(sender), event: \(event)")
            NotifyDefault.post(name: Notification.Name.Base.didEndStateMachineEvent,
                               object: params)
        }
    }
    
    func pageBack() {
        //webView.backForwardList.backList
        if webView.canGoBack {
            webView.stopLoading()
            webView.goBack()
        } else {
            popBack()
        }
    }
    
    override func clickNavigationBarLeftButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        
        if button.tag == 0 {
            pageBack()
        } else if webView.canGoForward {
            webView.stopLoading()
            webView.goForward()
        }
    }
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        
        if let url = params[ParamKey.url] as? URL {
            SRShareTool.shared.option = SRShareOption(title: title,
                                                      description: title,
                                                      url: url.absoluteString,
                                                      image: nil)
            SRShareTool.shared.delegate = self
            SRShareTool.shared.show()
        }
    }
    
    func updateProgressView(_ progress: CGFloat, animated: Bool) {
        if progress >= 1.0 {
            progressView.isHidden = true
        } else {
            if progressView.isHidden {
                progressView.isHidden = false
            }
            
            let frame = progressView.frame
            let y = topLayoutGuide.length
            let width = view.width
            if frame.origin.y != y || frame.size.width != width {
                progressView.frame = CGRect(0, y, width, progressView.progressBarThickness)
            }
            
            progressView.setProgress(progress, animated: animated)
        }
    }
    
    //MARK: - 事件响应
    
    //获得网页加载进度和标题
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            updateProgressView(CGFloat(webView.estimatedProgress), animated: true)
            
            if canGoBack != webView.canGoBack {
                canGoBack = webView.canGoBack
                setNavigationBarLeftButtonItems()
            }
        } else if keyPath == "title" {
            if !NonNull.check(params[ParamKey.title])  {
                title = webView.title
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webViewDidClose(_ webView: WKWebView) {
        pageBack()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        currentUrl = webView.url
        updateProgressView(0, animated: false)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        canGoBack = webView.canGoBack
        setNavigationBarLeftButtonItems()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !NonNull.check(params[ParamKey.title]) {
            updateProgressView(1.0, animated: true)
            title = webView.title
        }
        
        if canGoBack != webView.canGoBack {
            canGoBack = webView.canGoBack
            setNavigationBarLeftButtonItems()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {

    }
    
    // MARK: - SRShareToolDelegate
    
    func shareTool(types shareTool: SRShareTool) -> [SRShareTool.CellType]? {
        return SRShareTool.defaultTypes + [.tool(.refresh)]
    }
    
    func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool {
        if type == .tool(.refresh) {
            if let currentUrl = currentUrl {
                webView.stopLoading()
                webView.load(URLRequest(url: currentUrl))
            }
            return true
        }
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
