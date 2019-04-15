//
//  SRMJRefresh.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/22.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import MJRefresh

public class SRMJRefreshHeader: MJRefreshStateHeader {
    lazy var gifView = UIImageView()
    lazy var stateImages: [Int : [UIImage]] = [:]
    lazy var stateDurations:  [Int : TimeInterval] = [:]
    
    struct Const {
        static let gifViewImageHeight = 80.0 as CGFloat
        static var gifViewImageRatio = 248.0 / 304.0 as CGFloat
    }
    
    public init(refreshingBlock: MJRefresh.MJRefreshComponentRefreshingBlock!) {
        super.init(frame: CGRect())
        self.refreshingBlock = refreshingBlock
        setTitle("MJRefreshHeaderIdleText".localized, for: .idle)
        setTitle("MJRefreshHeaderPullingText".localized, for: .pulling)
        setTitle("MJRefreshHeaderRefreshingText".localized, for: .refreshing)
        addSubview(gifView)
        
        var images = [] as [UIImage]
        for i in (0 ..< 36) {
            var image = UIImage(named: "pokemon_ball_\(i)")!
            Const.gifViewImageRatio = image.size.width / image.size.height
            image = image.imageScaled(to: CGSize(width: Const.gifViewImageHeight * Const.gifViewImageRatio,
                                                 height: Const.gifViewImageHeight))
            images.append(image)
        }
        set(images: [images.first!], for: .idle)
        set(images: images, for: .pulling)
        set(images: images, for: .refreshing)
        lastUpdatedTimeLabel.isHidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(images: [UIImage], for state: MJRefreshState) {
        stateImages[state.rawValue] = images
        stateDurations[state.rawValue] = Double(images.count) * 0.05
        mj_h = max(images[0].size.height, mj_h)// 根据图片设置控件的高度
    }
    
    //MARK: - 实现父类的方法
    
    override public var pullingPercent: CGFloat {
        didSet {
            super.pullingPercent = self.pullingPercent
            guard state == .idle,
                let images = stateImages[MJRefreshState.idle.rawValue],
                !images.isEmpty else {
                    return
            }
            gifView.stopAnimating() //停止动画
            var index = Int(CGFloat(images.count) * self.pullingPercent)
            index = min(images.count - 1, index)
            gifView.image = images[index]
        }
    }
    
    override public func placeSubviews() {
        super.placeSubviews()
        let gifViewImageWidth = mj_h * Const.gifViewImageRatio
        if stateLabel.isHidden && lastUpdatedTimeLabel.isHidden {
            gifView.frame = CGRect((mj_w - gifViewImageWidth) / 2.0, 0, gifViewImageWidth, mj_h)
        } else {
            gifView.frame = CGRect(mj_w / 2.0 - gifViewImageWidth - 15.0,
                                    0,
                                    gifViewImageWidth,
                                    mj_h)
            stateLabel.mj_x = mj_w / 2.0 - 15.0
            stateLabel.mj_w = mj_w / 2.0 + 15.0
            stateLabel.textAlignment = .left
        }
    }
    
    override public var state: MJRefreshState {
        didSet {
            guard oldValue != state else {
                return
            }
            super.state = state
            
            if state == .pulling || state == .refreshing {
                guard let images = stateImages[state.rawValue], !images.isEmpty else {
                    return
                }
                
                gifView.stopAnimating()
                if images.count == 1 {
                    gifView.image = images.first
                } else {
                    gifView.animationImages = images
                    gifView.animationDuration = stateDurations[state.rawValue]!
                    gifView.startAnimating()
                }
            }
        }
    }
}
