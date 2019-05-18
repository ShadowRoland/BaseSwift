//
//  SRBrightnessView.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/8.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class SRBrightnessView: UIView {
    private var levelSuperview: UIView!
    private var levelViews: [UIView] = []
    private var hiddenTimer: Timer?
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: "brightness")
    }
    
    struct Const {
        static let width = 156.0 as CGFloat
        static let height = 156.0 as CGFloat
        static let levelMax = 20
    }
    
    func hide() {
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        layer.removeAllAnimations()
        isHidden = true
    }
    
    func initView() {
        guard levelSuperview == nil else {
            return
        }
        
        layer.cornerRadius = 10.0
        layer.masksToBounds = true
        backgroundColor = UIColor(white: 1, alpha: 0.7)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = CGRect(x: 0, y: 0, width: Const.width, height: Const.height)
        addSubview(blurView)
        
        let imageView = UIImageView(frame: CGRect(x: (Const.width - 100.0) / 2.0,
                                                  y: 15.0,
                                                  width: 100.0,
                                                  height: 100.0))
        imageView.image = UIImage.srNamed("sr_player_brightness")
        addSubview(imageView)
        
        
        levelSuperview =
            UIView(frame: CGRect(x: 13.0, y: 134.0, width: Const.width - 26.0, height: 7.0))
        addSubview(levelSuperview)
        
        let levelMagin = 1.0 as CGFloat
        let levelWidth = (levelSuperview.frame.size.width - CGFloat(Const.levelMax - 1) * levelMagin) / CGFloat(Const.levelMax)
        let levelHeight = levelSuperview.frame.size.height - 2.0 * levelMagin
        for i in 0 ..< Const.levelMax {
            let levelView = UIView()
            if i == 0 {
                levelView.frame =
                    CGRect(x: 0, y: levelMagin, width: levelWidth, height: levelHeight)
            } else {
                levelView.frame =
                    CGRect(x: CGFloat(i) * levelWidth + CGFloat(i - 1) * levelMagin,
                           y: levelMagin,
                           width: levelWidth,
                           height: levelHeight)
            }
            levelView.backgroundColor = .white
            levelSuperview.addSubview(levelView)
            levelViews.append(levelView)
        }
        
        UIScreen.main.addObserver(self, forKeyPath: "brightness", options: .new, context: nil)
    }
    
    func startHiddenTimer() {
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        hiddenTimer = Timer.scheduledTimer(timeInterval: 2.0,
                                           target: self,
                                           selector: #selector(stopHiddenTimer),
                                           userInfo: nil,
                                           repeats: false)
    }
    
    @objc func stopHiddenTimer() {
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        UIView.animate(withDuration: 0.6, animations: {
            self.alpha = 0
        }) { (finished) in
            if finished {
                self.alpha = 0
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                      of object: Any?,
                      change: [NSKeyValueChangeKey : Any]?,
                      context: UnsafeMutableRawPointer?) {
        let value = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).floatValue
        let level = value * Float(Const.levelMax)
        (0 ..< levelViews.count).forEach { levelViews[$0].isHidden = Float($0) > level }
        layer.removeAllAnimations()
        alpha = 1.0
        startHiddenTimer()
    }
}
