//
//  WebpageViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/11.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import WebKit
import M13ProgressSuite
import Cartography

class WebpageViewController: BaseViewController,
WKNavigationDelegate,
WKUIDelegate,
SRShareToolDelegate {
    private(set) var url: URL?
    private(set) var currentUrl: URL?
    
    lazy var webView: WKWebView = {
        let webView = WKWebView()
        srAddSubview(underTop: webView)
//        constrain(webView) { $0.edges == inset($0.superview!.edges, 0) }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.new, context: nil)
        webView.addObserver(self, forKeyPath:"title", options:.new, context:nil)
        return webView
    }()
    lazy var progressView: M13ProgressViewBar = {
        let progressView = M13ProgressViewBar()
        progressView.showPercentage = false
        progressView.progressBarThickness = 3.0
        view.addSubview(progressView)
        return progressView
    }()
    var canGoBack = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setDefaultNavigationBar("Loading ...".localized)
        setNavigationBarLeftButtonItems()
        setNavigationBarRightButtonItems()
        reload()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func setNavigationBarLeftButtonItems() {
        let back = canGoBack ? "page_back" : "close_left"
        if webView.canGoForward {
            navBarLeftButtonOptions = [.image(UIImage(back)!),
                                       .image(UIImage("page_forward_left")!)]
        } else {
            navBarLeftButtonOptions = [.image(UIImage(back)!)]
        }
    }
    
    func setNavigationBarRightButtonItems() {
        navBarRightButtonOptions = [.image(UIImage("more")!)]
    }

    func reload() {
        webView.stopLoading()
        if let title = srParams[Param.Key.title] as? String {
            self.title = title
        }
        if let url = srParams[Param.Key.url] as? URL {
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
    
    func pageBack() {
        //webView.backForwardList.backList
        if webView.canGoBack {
            webView.stopLoading()
            webView.goBack()
        } else {
            srPopBack()
        }
    }
    
    override public func clickNavigationBarLeftButton(_ button: UIButton) {
        guard MutexTouch else { return }
        
        if button.tag == 0 {
            pageBack()
        } else if webView.canGoForward {
            webView.stopLoading()
            webView.goForward()
        }
    }
    
    override public func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        
        if let url = srParams[Param.Key.url] as? URL {
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
    override public func observeValue(forKeyPath keyPath: String?,
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
            if !NonNull.check(srParams[Param.Key.title])  {
                title = webView.title
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webViewDidClose(_ webView: WKWebView) {
        pageBack()
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        currentUrl = webView.url
        updateProgressView(0, animated: false)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        canGoBack = webView.canGoBack
        setNavigationBarLeftButtonItems()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !NonNull.check(srParams[Param.Key.title]) {
            updateProgressView(1.0, animated: true)
            title = webView.title
        }
        
        if canGoBack != webView.canGoBack {
            canGoBack = webView.canGoBack
            setNavigationBarLeftButtonItems()
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {

    }
    
    // MARK: - SRShareToolDelegate
    
    public func shareTool(types shareTool: SRShareTool) -> [SRShareTool.CellType]? {
        return SRShareTool.defaultTypes + [.tool(.refresh)]
    }
    
    public func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool {
        if type == .tool(.refresh) {
            if let currentUrl = currentUrl {
                webView.stopLoading()
                webView.load(URLRequest(url: currentUrl))
            }
            return true
        }
        return false
    }
}
