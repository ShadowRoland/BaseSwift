//
//  SRProgressHUD.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/18.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import Cartography
import MBProgressHUD
import M13ProgressSuite

public final class SRProgressHUD {
    public enum ProgressType {
        case infinite
        case m13Ring
        /*
        case m13SegmentedRing
        case m13Pie
        case m13Bar
        case m13SegmentedBar
        case m13BorderedBar
        case m13StripedBar
        case m13Hud
        */
    }
    
    private(set) var progressType: ProgressType = .infinite
    
    var maskType: UIView.SRProgressComponent.MaskType = .clear
    var opaqueMaskColor = UIColor.white
    
    static let LoopedProgress = -1.0 as CGFloat
    var progress = LoopedProgress {
        didSet {
            if .m13Ring == progressType {
                if self.progress == SRProgressHUD.LoopedProgress {
                    mb13ProgressHUD.indeterminate = true
                } else {
                    mb13ProgressHUD.setProgress(self.progress, animated: true)
                }
            }
        }
    }
    var showPercentage = false {
        didSet {
            if showPercentage != oldValue {
                switch progressType {
                case .m13Ring:
                    (mb13ProgressHUD.progressView as! M13ProgressViewRing).showPercentage = true
                default: break
                }
            }
        }
    }
    var shouldAutorotate = false {
        didSet {
            if showPercentage != oldValue {
                if .m13Ring == progressType {
                    mb13ProgressHUD.indeterminate = true
                    mb13ProgressHUD.shouldAutorotate = shouldAutorotate
                }
            }
        }
    }
    
    public enum ImageProgressSize {
        case none,
        min,
        normal,
        max
        
        var imageSize: CGSize? {
            switch self {
            case .min:
                return CGSize(8.0, 8.0)
                
            case .normal:
                return CGSize(15.0, 15.0)
                
            default:
                return nil
            }
        }
        
        var font: UIFont? {
            switch self {
            case .min:
                return UIFont.Preferred.caption2
                
            case .normal:
                return UIFont.Preferred.footnote
                
            default:
                return nil
            }
        }
    }
    var imageProgressSize: ImageProgressSize = .none
 
    private(set) weak var hudView: UIView!
    private var mbProgressHUD: MBProgressHUD!
    fileprivate var animationImageView: UIImageView!
    var mb13ProgressHUD: M13ProgressHUD!
    
    var constraintGroup = ConstraintGroup()
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
    }
    
    public func dismiss(_ animated: Bool = true) {
        switch progressType {
        case .infinite:
            animationImageView.stopAnimating()
            mbProgressHUD.hide(animated: animated)
            
        case .m13Ring:
            if animated {
                mb13ProgressHUD.dismiss(true)
            } else {
                mb13ProgressHUD.progressView?.setProgress((mb13ProgressHUD.progressView?.progress)! + CGFloat(0.00001), animated: false)
                mb13ProgressHUD.dismiss(false)
            }
            mb13ProgressHUD.perform(M13ProgressViewActionNone, animated: false)
        }
    }
    
    public func show(_ animated: Bool = true) {
        guard let superview = hudView.superview else { return }
        
        switch progressType {
        case .infinite:
            switch maskType {
            case .clear:
                superview.backgroundColor = UIColor.clear
                
            case .translucence:
                superview.backgroundColor = MaskBackgroundColor
                
            case .opaque:
                superview.backgroundColor = opaqueMaskColor
            }
            animationImageView.startAnimating()
            layout()
            mbProgressHUD.show(animated: animated)
            
        case .m13Ring:
            switch maskType {
            case .clear:
                superview.backgroundColor = UIColor.clear
                
            case .translucence:
                superview.backgroundColor = MaskBackgroundColor
                
            case .opaque:
                superview.backgroundColor = opaqueMaskColor
            }
            layout()
            mb13ProgressHUD.show(animated)
        }
    }
    
    public func layout() {
        guard let superview = hudView.superview else { return }

        switch progressType {
        case .infinite:
            constraintGroup = constrain(mbProgressHUD, replace: constraintGroup) {
                $0.edges == inset($0.superview!.edges, 0)
            }
            
        case .m13Ring:
            mb13ProgressHUD.animationPoint =
                CGPoint((superview.width - mb13ProgressHUD.progressViewSize.width) / 2.0,
                        (superview.height - mb13ProgressHUD.progressViewSize.height) / 2.0)
        }
    }
    
    public func setProgress(_ progress: CGFloat, animated: Bool) {
        switch progressType {
        case .m13Ring:
            if progress == SRProgressHUD.LoopedProgress {
                mb13ProgressHUD.indeterminate = true
            } else {
                mb13ProgressHUD.indeterminate = false
                mb13ProgressHUD.setProgress(progress, animated: animated)
            }
            
        default:
            break
        }
    }

    public class func hud(_ type: ProgressType) -> SRProgressHUD {
        switch type {
        case .infinite:
            return SRProgressHUD.infiniteHUD()
            
        case .m13Ring:
            return SRProgressHUD.m13RingHUD()
        }
    }
    
    class func infiniteHUD() -> SRProgressHUD {
        let animationImageView = UIImageView(frame: CGRect(0, 0, 60.0, 60.0))
        var array = [] as [UIImage]
        (0 ..< 30).forEach { array.append(UIImage(named: "huaji_\($0)")!) }
        animationImageView.animationImages = array
        animationImageView.animationDuration = 1.0
        animationImageView.animationRepeatCount = 0
        
        let hud = SRProgressHUD()
        hud.progressType = .infinite
        hud.animationImageView = animationImageView
        hud.mbProgressHUD = MBProgressHUD(view: hud.animationImageView)
        hud.mbProgressHUD.customView = hud.animationImageView
        hud.mbProgressHUD.margin = 0
        hud.mbProgressHUD.mode = MBProgressHUDMode.customView
        hud.mbProgressHUD.removeFromSuperViewOnHide = false
        hud.mbProgressHUD.bezelView.color = UIColor.clear
        hud.mbProgressHUD.bezelView.style = .solidColor
        hud.mbProgressHUD.backgroundView.color = UIColor.clear
        hud.mbProgressHUD.backgroundView.style = .solidColor
        
        hud.hudView = hud.mbProgressHUD
        return hud
    }
    
    class func m13RingHUD() -> SRProgressHUD {
        let progressView = M13ProgressViewRing()
        progressView.showPercentage = false
        progressView.backgroundRingWidth = 4.0
        progressView.secondaryColor = NavigartionBar.backgroundColor
        
        let hud = SRProgressHUD()
        hud.progressType = .m13Ring
        hud.mb13ProgressHUD = M13ProgressHUD(progressView: progressView)!
        hud.mb13ProgressHUD.hudBackgroundColor =
            UIColor(hue: 42.0, saturation: 25.0, brightness: 94.0)
        hud.mb13ProgressHUD.progressViewSize = CGSize(60.0, 60.0)
        hud.mb13ProgressHUD.minimumSize = CGSize(60.0, 60.0)
        hud.mb13ProgressHUD.contentMargin = 0
        hud.mb13ProgressHUD.cornerRadius = 30.0
        hud.mb13ProgressHUD.indeterminate = true
        hud.mb13ProgressHUD.animationCentered = true
        
        hud.hudView = hud.mb13ProgressHUD
        return hud
    }
}
