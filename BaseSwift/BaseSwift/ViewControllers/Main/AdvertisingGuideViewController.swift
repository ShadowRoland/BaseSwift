//
//  AdvertisingGuideViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/5.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

class AdvertisingGuideViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var advertisingButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var timer: Timer!
    var second = 5

    override func viewDidLoad() {
        super.viewDidLoad()

        initTimer()
        skipButton.backgroundImage =
            UIImage.rect(MaskBackgroundColor, size: CGSize(80.0, TableCellHeight))
        skipButton.title = String(format: "See Ad.(%d)".localized, second)
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 业务处理
    
    func initTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                          target: self,
                                          selector: #selector(countDown),
                                          userInfo: nil,
                                          repeats: true)
        RunLoop.current.add(timer, forMode: .common)
    }
    
    //MARK: - 事件响应
    
   @objc func countDown() {
        if second == 0 {
            dimiss()
        } else {
            skipButton.title = String(format: "See Ad.(%d)".localized, second)
            second -= 1
        }
    }
    
    func dimiss() {
        timer.invalidate()
        view.removeFromSuperview()
    }
    
    //MARK: - Autorotate Orientation
    
    override public var shouldAutorotate: Bool { return false }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}
