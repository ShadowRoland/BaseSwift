//
//  AdvertisingGuideViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/5.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

protocol AdvertisingGuideDelegate: class {
    func advertisingGuideShowAdvertising(_ viewController: AdvertisingGuideViewController)
    func advertisingGuideSkip(_ viewController: AdvertisingGuideViewController)
    func advertisingDisDimiss(_ viewController: AdvertisingGuideViewController)
}

extension AdvertisingGuideDelegate {
    func advertisingGuideShowAdvertising(_ viewController: AdvertisingGuideViewController) { }
    func advertisingGuideSkip(_ viewController: AdvertisingGuideViewController) { }
    func advertisingDisDimiss(_ viewController: AdvertisingGuideViewController) { }
}

class AdvertisingGuideViewController: UIViewController {
    weak var delegate: AdvertisingGuideDelegate?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var skipButton: UIButton!
    
    var timer: Timer!
    var second = 5

    override func viewDidLoad() {
        super.viewDidLoad()

        initTimer()
        skipButton.backgroundImage =
            UIImage.rect(C.maskBackgroundColor, size: CGSize(80.0, C.tableCellHeight))
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
        delegate?.advertisingDisDimiss(self)
    }
    
    @IBAction func clickAdvertising(_ sender: Any) {
        guard MutexTouch else { return }
        delegate?.advertisingGuideShowAdvertising(self)
    }
    
    @IBAction func skip(_ sender: Any) {
        guard MutexTouch else { return }
        delegate?.advertisingGuideSkip(self)
    }
}
