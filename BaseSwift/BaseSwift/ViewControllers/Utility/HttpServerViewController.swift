//
//  HttpServerViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/12.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import DTCoreText
import GCDWebServer

//仅用于调试
class HttpServerViewController: UITableViewController {
    @IBOutlet weak var networkStatusLabel: DTAttributedLabel!
    @IBOutlet weak var listenLabel: UILabel!
    @IBOutlet weak var stopToExitButton: UIButton!
    @IBOutlet weak var holdToExitButton: UIButton!
    @IBOutlet weak var responseSuccessCell: UITableViewCell!
    @IBOutlet weak var responseTimeCell: UITableViewCell!
    @IBOutlet weak var clearTokenCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Common.shared.addObserver(self,
                                forKeyPath: "networkStatus",
                                options: .new,
                                context: nil)
        initView()
        SRHttpServer.shared.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNetworkStatus()
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        Common.shared.removeObserver(self, forKeyPath: "networkStatus")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    //默认不能横屏
    override public var shouldAutorotate: Bool { return false }
    
    //默认只支持一个正面竖屏方向
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    //页面刚展示时使用正面竖屏方向
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        stopToExitButton.titleColor = UIColor.white
        stopToExitButton.backgroundImage = UIImage.rect(NavigationBar.backgroundColor,
                                                        size: stopToExitButton.bounds.size)
        stopToExitButton.layer.cornerRadius = SubmitButton.cornerRadius
        holdToExitButton.titleColor = UIColor.white
        holdToExitButton.backgroundImage = UIImage.rect(SubmitButton.backgroundColorNormal,
                                                        size: stopToExitButton.bounds.size)
        holdToExitButton.layer.cornerRadius = SubmitButton.cornerRadius
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        if let responseResult = SRHttpServer.shared.responseResult {
            if responseResult.isSuccess {
                responseSuccessCell.detailTextLabel?.text = "返回成功"
            } else if responseResult.isBFailure {
                responseSuccessCell.detailTextLabel?.text = "返回业务失败"
            } else if responseResult.isFailure {
                responseSuccessCell.detailTextLabel?.text = "返回失败"
            }
        } else {
            responseTimeCell.detailTextLabel?.text = "如实返回"
        }
        
        switch SRHttpServer.shared.responseTime {
        case .immediately:
            responseTimeCell.detailTextLabel?.text = "立即返回"
        case .speediness:
            responseTimeCell.detailTextLabel?.text = "快(0.3秒)"
        case .normal:
            responseTimeCell.detailTextLabel?.text = "一般(1秒)"
        case .long:
            responseTimeCell.detailTextLabel?.text = "长(10秒)"
        case .timeout:
            responseTimeCell.detailTextLabel?.text = "超时(100秒)"
        }
        
        if SRHttpServer.shared.token == "Expired" {
            clearTokenCell.detailTextLabel?.text = "已失效"
        } else if SRHttpServer.shared.token == "" {
            clearTokenCell.detailTextLabel?.text = "未登录"
        } else {
            clearTokenCell.detailTextLabel?.text = "已登录"
        }
        
        updateNetworkStatus()
    }
    
    //MARK: - 业务处理
    
    func updateNetworkStatus() {
        let wifiEnable = HttpManager.default.networkStatus == .reachable(.ethernetOrWiFi)
        var format = "<p style=\"font-family: sans-serif; font-weight: bold; font-size: 18px; color: black\">当前WIFI状态  <span style=\"color: %@\">%@</span></p>"
        if !wifiEnable {
            networkStatusLabel.attributedString =
                String(format: format, "red", "不可用").attributedString
            return
        }
        
        let wifiStatus = String(format: format, "blue", "正常")
        format = "<p style=\"font-family: sans-serif; font-size: 16px; color: #333333\">手机内置的Http Server地址为<br><a href=\"www\" color: #06c>http://%@:%d</a><br>在同一局域网内的电脑上浏览该网址可访问程序日志文件</p>"
        let url = String(format: format, GCDWebServerGetPrimaryIPAddress(false)!, 9999)
        DispatchQueue.main.async {
            self.networkStatusLabel.attributedString = (wifiStatus + url).attributedString
            self.tableView.reloadData()
        }
    }
    
    public func updateListenLabel(_ text: String) {
        DispatchQueue.main.async {
            self.listenLabel.text = text
        }
    }
    
    // MARK: - 事件响应
    
    @IBAction func stopToExit(_ sender: Any) {
        SRHttpServer.shared.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func holdToExit(_ sender: Any) {
        SRHttpServer.shared.start()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "networkStatus" {
            updateNetworkStatus()
        }
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 140.0
        } else if indexPath.section == 1 && indexPath.row == 0 {
            return 60.0
        }
        return TableCellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 && indexPath.row == 0 {
            let alert = SRAlertController(title: "成功与否",
                                          message: "若处理的结果与设置的成功与否不一致，将强制返回所设置的成功类型",
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "如实返回",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseSuccessCell.detailTextLabel?.text = "如实返回"
                    //SRHttpServer.shared.responseResult = nil
            }))
            alert.addAction(UIAlertAction(title: "返回成功",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    //self?.responseSuccessCell.detailTextLabel?.text = "返回成功"
                    //SRHttpServer.shared.responseResult = .success(nil)
            }))
            alert.addAction(UIAlertAction(title: "返回业务失败",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseSuccessCell.detailTextLabel?.text = "返回业务失败"
                    //SRHttpServer.shared.responseResult = .bfailure(nil)
            }))
            alert.addAction(UIAlertAction(title: "返回失败",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseSuccessCell.detailTextLabel?.text = "返回失败"
                    //SRHttpServer.shared.responseResult = .failure(NSError())
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        } else if indexPath.section == 2 && indexPath.row == 1 {
            let alert = SRAlertController(title: "响应速度",
                                          message: nil,
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "立即返回",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseTimeCell.detailTextLabel?.text = "立即返回"
                    //SRHttpServer.shared.responseTime = .immediately
            }))
            alert.addAction(UIAlertAction(title: "快(0.3秒)",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseTimeCell.detailTextLabel?.text = "快(0.3秒)"
                    //SRHttpServer.shared.responseTime = .speediness
            }))
            alert.addAction(UIAlertAction(title: "一般(1秒)",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseTimeCell.detailTextLabel?.text = "一般(1秒)"
                    //SRHttpServer.shared.responseTime = .normal
            }))
            alert.addAction(UIAlertAction(title: "长(10秒)",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseTimeCell.detailTextLabel?.text = "长(10秒)"
                    //SRHttpServer.shared.responseTime = .long
            }))
            alert.addAction(UIAlertAction(title: "超时(100秒)",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.responseTimeCell.detailTextLabel?.text = "超时(100秒)"
                    //SRHttpServer.shared.responseTime = .timeout
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        } else if indexPath.section == 2 && indexPath.row == 2 {
            let alert = SRAlertController(title: "清除用户登录状态",
                                          message: "再次进行需要鉴权的Http请求时会返回登录过期的错误",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定",
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    self?.clearTokenCell.detailTextLabel?.text = "已失效"
                    //SRHttpServer.shared.token = "Expired"
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
