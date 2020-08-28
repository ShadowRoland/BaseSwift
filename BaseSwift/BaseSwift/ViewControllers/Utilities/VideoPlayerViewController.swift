//
//  VideoPlayerViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/4.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class VideoPlayerViewController: BaseViewController, SRVideoPlayerDelegate {
    var url: URL!
    private var player: SRVideoPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        HttpManager.shared.addListener(forNetworkStatusChanged: self,
                                        action: #selector(updateNetworkStatus))
        srPageBackGestureStyle = .none
        setDefaultNavigationBar("")
        player = SRVideoPlayer()
        player.delegate = self
        view.backgroundColor = UIColor.black
        if #available(iOS 9.0, *) {
            
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 9.0, *) {
            
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    deinit {
        HttpManager.shared.removeListener(forNetworkStatusChanged: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func performViewDidLoad() {
        url = URL(string: "http://gslb.miaopai.com/stream/xheWECQwCMh0TlTYdGh30A__.mp4")
        player.play(url, inView: view)
    }
    
//    override func pageWillBack() {
//        player.close()
//        UIApplication.shared.statusBarStyle = .default
//        navigationController?.navigationBar.overlay.alpha = 1.0
//    }
    
    // MARK: - 事件响应
    
    @objc func updateNetworkStatus() {
        if HttpManager.shared.networkStatus == .reachable(.ethernetOrWiFi) {
            player.connectWwan()
        }
    }
    
    //MARK: - SRVideoPlayerDelegate
    
    func player(didFailLoading player: SRVideoPlayer!, error: Error?) {
        
    }
        
    func player(isConnectingWwan player: SRVideoPlayer!) -> Bool {
        return HttpManager.shared.networkStatus == .reachable(.ethernetOrWiFi)
    }
    
    func player(controlViewsDidShow player: SRVideoPlayer!) {
        navigationController?.navigationBar.layer.removeAllAnimations()
        navigationController?.navigationBar.alpha = 1.0
    }
    
    func player(controlViewsWillHide player: SRVideoPlayer!, animated: Bool) {
        if !animated {
            navigationController?.navigationBar.layer.removeAllAnimations()
            navigationController?.navigationBar.alpha = 0
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.navigationController?.navigationBar.alpha = 0
            }, completion: { (finished) in
                if finished {
                    self.navigationController?.navigationBar.alpha = 0
                }
            })
        }
    }
    
    func player(updateStatusBar player: SRVideoPlayer!, isStatusBarHidden: Bool) {
        
    }
}
