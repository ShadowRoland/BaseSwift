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
    public var gif: UIImage.SRGif? {
        didSet {
            guard let gif = gif, let images = gif.images, !images.isEmpty else {
                stateGifs.removeAll()
                gifView.removeFromSuperview()
                lastUpdatedTimeLabel?.isHidden = false
                return
            }
            
            addSubview(gifView)
            var array = [] as [UIImage]
            if gif.imageSize == CGSize.zero {
                array = images
            } else {
                images.forEach { array.append($0.imageScaled(to: gif.imageSize)) }
            }
            set(gif: gif, for: .idle)
            set(gif: gif, for: .pulling)
            set(gif: gif, for: .refreshing)
            lastUpdatedTimeLabel?.isHidden = true
        }
    }
    
    public static var defaultGif: UIImage.SRGif? = nil
    
    lazy var gifView = UIImageView()
    lazy var stateGifs: [MJRefreshState : UIImage.SRGif] = [:]
    
    public init(refreshingBlock: MJRefresh.MJRefreshComponentAction!,
                gif: UIImage.SRGif? = nil) {
        super.init(frame: CGRect())
        self.refreshingBlock = refreshingBlock
        setTitle("MJRefreshHeaderIdleText".srLocalized, for: .idle)
        setTitle("MJRefreshHeaderPullingText".srLocalized, for: .pulling)
        setTitle("MJRefreshHeaderRefreshingText".srLocalized, for: .refreshing)
        if SRMJRefreshHeader.defaultGif == nil {
            var gif = UIImage.SRGif()
            gif.images = (0 ..< 30).compactMap { UIImage.srNamed("sr_refresh_header_\($0)") }
            gif.imageSize = CGSize(65.0, 80.0)
            gif.duration = Double(gif.images!.count) * 0.05
            SRMJRefreshHeader.defaultGif = gif
        }
        if let gif = gif {
            self.gif = gif
        } else {
            self.gif = SRMJRefreshHeader.defaultGif
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(gif: UIImage.SRGif, for state: MJRefreshState) {
        stateGifs[state] = gif
//        stateDurations[state] = Double(images.count) * 0.05
        mj_h = max(gif.images!.first!.size.height, mj_h)// 根据图片设置控件的高度
    }
    
    //MARK: - 实现父类的方法
    
    override public var pullingPercent: CGFloat {
        didSet {
            super.pullingPercent = self.pullingPercent
            guard state == .idle, let images = stateGifs[state]?.images, !images.isEmpty else {
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
        if let image = gif?.images?.first {
            let width = mj_h * image.size.width / image.size.height
            if let stateLabel = stateLabel, let lastUpdatedTimeLabel = lastUpdatedTimeLabel, stateLabel.isHidden && lastUpdatedTimeLabel.isHidden {
                gifView.frame = CGRect((mj_w - width) / 2.0, 0, width, mj_h)
            } else {
                gifView.frame = CGRect(mj_w / 2.0 - width - 15.0, 0, width, mj_h)
                stateLabel?.mj_x = mj_w / 2.0 - 15.0
                stateLabel?.mj_w = mj_w / 2.0 + 15.0
                stateLabel?.textAlignment = .left
            }
        }
    }
    
    override public var state: MJRefreshState {
        didSet {
            guard oldValue != state else {
                return
            }
            super.state = state
            
            if state == .pulling || state == .refreshing {
                guard let gif = stateGifs[state], let images = gif.images, !images.isEmpty else {
                    return
                }
                
                gifView.stopAnimating()
                if images.count == 1 {
                    gifView.image = images.first
                } else {
                    gifView.animationImages = images
                    gifView.animationDuration = gif.duration
                    gifView.startAnimating()
                }
            }
        }
    }
}
