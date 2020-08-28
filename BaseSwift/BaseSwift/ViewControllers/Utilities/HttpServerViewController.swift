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
        
        HttpManager.shared.addListener(forNetworkStatusChanged: self,
                                        action: #selector(updateNetworkStatus))
        initView()
        HttpServer.shared.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNetworkStatus()
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        HttpManager.shared.removeListener(forNetworkStatusChanged: self)
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
        stopToExitButton.titleColor = .white
        stopToExitButton.backgroundImage =
            .gradient("CFD8DC".color,
                      toColor: "546E7A".color,
                      size: stopToExitButton.sizeThatFits(CGSize(.greatestFiniteMagnitude,
                                                                 .greatestFiniteMagnitude)))
        stopToExitButton.layer.cornerRadius = SubmitButton.cornerRadius
        
        holdToExitButton.titleColor = .white
        holdToExitButton.backgroundImage =
            .gradient("5581f1".color,
                      toColor: "1153FC".color,
                      size: holdToExitButton.sizeThatFits(CGSize(.greatestFiniteMagnitude,
                                                                 .greatestFiniteMagnitude)))
        holdToExitButton.layer.cornerRadius = SubmitButton.cornerRadius
        
        responseSuccessCell.detailTextLabel?.text = HttpServer.shared.responseResult?.description ?? "如实返回"
        responseTimeCell.detailTextLabel?.text = HttpServer.shared.responseSpeed.description
        
        updateNetworkStatus()
    }
    
    //MARK: - 业务处理
    
    @objc func updateNetworkStatus() {
        let wifiEnable = HttpManager.shared.networkStatus == .reachable(.ethernetOrWiFi)
        var format = "<p style=\"font-family: sans-serif; font-weight: bold; font-size: 18px; color: black\">当前WIFI状态  <span style=\"color: %@\">%@</span></p>"
        if !wifiEnable {
            networkStatusLabel.attributedString =
                String(format: format, "red", "不可用").attributedString
            return
        }
        
        let wifiStatus = String(format: format, "blue", "正常")
        format = "<p style=\"font-family: sans-serif; font-size: 16px; color: #333333\">手机内置的Http Server地址为<br><a href=\"www\" color: #06c>http://%@:%d</a><br>在同一局域网内的电脑上浏览该网址可访问程序日志文件</p>"
        let url = String(format: format, GCDWebServerGetPrimaryIPAddress(false) ?? "127.0.0.1", 9999)
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
        HttpServer.shared.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func holdToExit(_ sender: Any) {
        HttpServer.shared.start()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 140.0
        } else if indexPath.section == 1 && indexPath.row == 0 {
            return 60.0
        }
        return C.tableCellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 && indexPath.row == 0 {
            let alert = SRAlertController(title: "成功与否",
                                          message: "若处理的结果与设置的成功与否不一致，将强制返回所设置的成功类型",
                                          preferredStyle: .actionSheet)
            
            func addResponseResultAction(_ result: SRHttpServer.GCDWebServerResponseResult?) {
                alert.addAction(UIAlertAction(title: result?.description ?? "如实返回",
                                              style: .default,
                                              handler:
                    { [weak self] action in
                        self?.responseSuccessCell.detailTextLabel?.text = result?.description ?? "如实返回"
                        HttpServer.shared.responseResult = result
                }))
            }
            
            addResponseResultAction(nil)
            addResponseResultAction(.success)
            addResponseResultAction(.failure)
            addResponseResultAction(.error)
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        } else if indexPath.section == 2 && indexPath.row == 1 {
            let alert = SRAlertController(title: "响应速度",
                                          message: nil,
                                          preferredStyle: .actionSheet)
            
            func addResponseTimeIntervalAction(_ responseSpeed: SRHttpServer.GCDWebServerResponseSpeed) {
                alert.addAction(UIAlertAction(title: responseSpeed.description,
                                              style: .default,
                                              handler:
                    { [weak self] action in
                        self?.responseTimeCell.detailTextLabel?.text =
                            responseSpeed.description
                        HttpServer.shared.responseSpeed = responseSpeed
                }))
            }
            
            addResponseTimeIntervalAction(.immediately)
            addResponseTimeIntervalAction(.rapid)
            addResponseTimeIntervalAction(.normal)
            addResponseTimeIntervalAction(.long)
            addResponseTimeIntervalAction(.timeout)
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        } else if indexPath.section == 2 && indexPath.row == 2 {
            let alert = SRAlertController(title: "清除用户登录状态",
                                          message: "再次进行需要鉴权的Http请求时会返回登录过期的错误",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定",
                                          style: .default,
                                          handler:
                { [weak self] action in
                    self?.clearTokenCell.detailTextLabel?.text = "已失效"
                    HttpServer.token = "Expired"
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
