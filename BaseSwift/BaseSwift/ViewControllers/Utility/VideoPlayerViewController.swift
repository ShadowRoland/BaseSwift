//
//  VideoPlayerViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/4.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class VideoPlayerViewController: BaseViewController, SRVideoPlayerDelegate {
    var url: URL!
    private var player: SRVideoPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pageBackGestureStyle = .none
        CommonShare.addObserver(self,
                                forKeyPath: "networkStatus",
                                options: .new,
                                context: nil)
        defaultNavigationBar(EmptyString)
        player = SRVideoPlayer()
        player.delegate = self
        view.backgroundColor = UIColor.black
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    deinit {
        CommonShare.removeObserver(self, forKeyPath: "networkStatus")
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
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "networkStatus" {
            if CommonShare.networkStatus == .reachable(.wwan) {
                player.connectWwan()
            }
        }
    }
    
    //MARK: - SRVideoPlayerDelegate
    
    func player(didFailLoading player: SRVideoPlayer!, error: Error?) {
        
    }
        
    func player(isConnectingWwan player: SRVideoPlayer!) -> Bool {
        return CommonShare.networkStatus == .reachable(.wwan)
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
