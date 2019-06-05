//
//  SRProgressComponent.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/18.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC
import QuartzCore
import Cartography

//MARK: - Progress

extension UIView {
    public class SRProgressComponent {
        public enum Option {
            case progressType(SRProgressHUD.ProgressType)
            case maskType(MaskType)
            case progress(CGFloat)
            case showPercentage(Bool)
            case shouldAutorotate(Bool)
            case opaqueMaskColor(UIColor)
            case imageProgressSize(SRProgressHUD.ImageProgressSize)
            case gif(UIImage.SRGif)
        }
        
        public enum MaskType: Int {
            case clear = 0, //背景透明
            translucence, //背景半透明
            opaque //完全不透明的背景，默认白色
        }
        
        public weak var decorator: UIView?
        
        deinit {
            LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        }
        
        fileprivate struct AssociatedKeys {
            static var progress = "UIView.SRProgressComponent.progress"
        }

        fileprivate var maskView: UIView!
        fileprivate var progressHUD: SRProgressHUD!
        
        fileprivate var opaqueMaskColor = UIColor.white {
            didSet {
                if progressHUD != nil {
                    progressHUD.opaqueMaskColor = opaqueMaskColor
                }
            }
        }
        
        fileprivate var constraintGroup = ConstraintGroup()
        
        var isShowing: Bool {
            return maskView != nil && maskView.superview != nil
        }
        
        public func show(_ options: [Option]?) {
            guard !isShowing, let options = options else { return }
            
            var progressType: SRProgressHUD.ProgressType?
            var maskType: MaskType?
            var progress: CGFloat?
            var showPercentage: Bool?
            var shouldAutorotate: Bool?
            var opaqueMaskColor: UIColor?
            var imageProgressSize: SRProgressHUD.ImageProgressSize?
            var gif: UIImage.SRGif?
            
            options.forEach {
                switch ($0) {
                case .progressType(let p):
                    progressType = p
                    
                case .maskType(let m):
                    maskType = m
                    
                case .progress(let p):
                    progress = p
                    
                case .showPercentage(let s):
                    showPercentage = s
                    
                case .shouldAutorotate(let s):
                    shouldAutorotate = s
                    
                case .opaqueMaskColor(let o):
                    opaqueMaskColor = o
                    
                case .imageProgressSize(let i):
                    imageProgressSize = i
                    
                case .gif(let g):
                    gif = g
                }
            }
            
            if maskView == nil {
                if let progressType = progressType {
                    maskView = UIView()
                    progressHUD = SRProgressHUD.hud(progressType)
                } else {
                    return
                }
            }
            
            if let progressType = progressType, progressType != progressHUD.progressType {
                progressHUD.dismiss(false)
                progressHUD = SRProgressHUD.hud(progressType)
            }
            
            if let maskType = maskType, maskType != progressHUD.maskType {
                progressHUD.maskType = maskType
            }
            
            if let progress = progress {
                progressHUD.progress = progress
            }
            
            if let showPercentage = showPercentage {
                progressHUD.showPercentage = showPercentage
            }
            if let shouldAutorotate = shouldAutorotate {
                progressHUD.shouldAutorotate = shouldAutorotate
            }
            if let opaqueMaskColor = opaqueMaskColor {
                self.opaqueMaskColor = opaqueMaskColor
            }
            if let imageProgressSize = imageProgressSize {
                progressHUD.imageProgressSize = imageProgressSize
            }
            if let gif = gif {
                progressHUD.gif = gif
            }

            decorator?.addSubview(maskView)
            constraintGroup = constrain(maskView, replace: constraintGroup) {
                $0.edges == inset($0.superview!.edges, 0)
            }
            
            maskView.addSubview(progressHUD.hudView)
            progressHUD.show()
        }
        
        public func dismiss(_ animated: Bool = true) {
            if isShowing {
                progressHUD.dismiss(animated)
                progressHUD.hudView.removeFromSuperview()
                maskView.removeFromSuperview()
            }
        }
        
        public func setProgress(_ progress: CGFloat, animated: Bool) {
            if isShowing {
                progressHUD.setProgress(progress, animated: animated)
            }
        }
        
        public func resetPosition() {
            if isShowing {
                progressHUD.layout()
            }
        }
        
        public var progress: CGFloat {
            return progressHUD != nil ? progressHUD.progress : SRProgressHUD.LoopedProgress
        }
    }
}

public protocol SRProgressProtocol: class {
    func showProgress(_ options: [UIView.SRProgressComponent.Option]?)
    func dismissProgress(_ animated: Bool)
    var isShowingProgress: Bool { get }
    func resetProgressPosition()
}

extension SRProgressProtocol where Self: UIView {
    public func showProgress() {
        showProgress([.progressType(.infinite)])
    }
    
    public func showProgress(maskType: SRProgressComponent.MaskType) {
        showProgress([.progressType(.infinite), .maskType(maskType)])
    }
    
    public func showProgress(_ options: [UIView.SRProgressComponent.Option]?) {
        progressComponent.show(options)
    }
    
    public func dismissProgress() {
        progressComponent.dismiss(true)
    }
    
    public func dismissProgress(_ animated: Bool) {
        progressComponent.dismiss(animated)
    }
    
    public var isShowingProgress: Bool {
        return progressComponent.isShowing
    }
    
    public func resetProgressPosition() {
        progressComponent.resetPosition()
    }
}

extension UIView: SRProgressProtocol {
    public var progressComponent: SRProgressComponent {
        if let component = objc_getAssociatedObject(self, &SRProgressComponent.AssociatedKeys.progress) as? SRProgressComponent {
            return component
        }
        
        let component = SRProgressComponent()
        component.decorator = self
        objc_setAssociatedObject(self,
                                 &SRProgressComponent.AssociatedKeys.progress,
                                 component,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return component
    }
    
    public var progressMaskColor: UIColor {
        get {
            return progressComponent.opaqueMaskColor
        }
        set {
            progressComponent.opaqueMaskColor = newValue
        }
    }
}
