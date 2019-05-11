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
        public enum MaskType: Int {
            case clear = 0, //背景透明
            translucence, //背景半透明
            opaque //完全不透明的背景，默认白色
        }
        
        public class AttributedString {
            public struct Key: RawRepresentable, Hashable  {
                public typealias RawValue = String
                public var rawValue: String
                
                public init(_ rawValue: String) {
                    self.rawValue = rawValue
                }
                
                public init(rawValue: String) {
                    self.rawValue = rawValue
                }
            }
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
        
        public func show(_ maskType: MaskType,
                         progressType: SRProgressHUD.ProgressType,
                         progress: CGFloat,
                         options: [SRProgressComponent.AttributedString.Key : Any]?) {
            guard !isShowing else { return }
            
            if maskView == nil {
                maskView = UIView()
                progressHUD = SRProgressHUD.hud(progressType)
            }
            
            if progressType != progressHUD.progressType {
                progressHUD.dismiss(false)
                progressHUD = SRProgressHUD.hud(progressType)
            }
            
            if progressHUD.maskType != maskType {
                progressHUD.maskType = maskType
            }
            
            progressHUD.progress = progress
            if let options = options {
                if let showPercentage = options[.showPercentage] as? Bool {
                    progressHUD.showPercentage = showPercentage
                }
                if let shouldAutorotate = options[.shouldAutorotate] as? Bool {
                    progressHUD.shouldAutorotate = shouldAutorotate
                }
                if let opaqueMaskColor = options[.opaqueMaskColor] as? UIColor {
                    self.opaqueMaskColor = opaqueMaskColor
                }
                if let imageProgressSize = options[.imageProgressSize] as? SRProgressHUD.ImageProgressSize {
                    progressHUD.imageProgressSize = imageProgressSize
                }
                if let gif = options[.gif] as? UIImage.SRGif {
                    progressHUD.gif = gif
                }
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
    func showProgress(_ maskType: UIView.SRProgressComponent.MaskType?,
                      progressType: SRProgressHUD.ProgressType?,
                      progress: CGFloat?,
                      options: [UIView.SRProgressComponent.AttributedString.Key : Any]?)
    func dismissProgress(_ animated: Bool)
    var isShowingProgress: Bool { get }
    func resetProgressPosition()
}

extension SRProgressProtocol where Self: UIView {
    public func showProgress() {
        showProgress(nil, progressType: nil, progress: nil, options: nil)
    }
    
    public func showProgress(_ maskType: SRProgressComponent.MaskType) {
        showProgress(maskType, progressType: nil, progress: nil, options: nil)
    }
    
    public func showProgress(_ maskType: SRProgressComponent.MaskType?,
                             progressType: SRProgressHUD.ProgressType?,
                             progress: CGFloat?,
                             options: [SRProgressComponent.AttributedString.Key : Any]?) {
        var type: SRProgressHUD.ProgressType = .infinite
        if let progressType = progressType {
            type = progressType
        } else if progressComponent.progressHUD != nil {
            type = progressComponent.progressHUD.progressType
        }
        progressComponent.show(maskType ?? .clear,
                               progressType: type,
                               progress: progress ?? progressComponent.progress,
                               options: options)
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

public extension UIView.SRProgressComponent.AttributedString.Key {
    static let showPercentage: UIView.SRProgressComponent.AttributedString.Key =  UIView.SRProgressComponent.AttributedString.Key("showPercentage")
    static let shouldAutorotate: UIView.SRProgressComponent.AttributedString.Key =  UIView.SRProgressComponent.AttributedString.Key("shouldAutorotate")
    static let opaqueMaskColor: UIView.SRProgressComponent.AttributedString.Key =  UIView.SRProgressComponent.AttributedString.Key("opaqueMaskColor")
    static let imageProgressSize: UIView.SRProgressComponent.AttributedString.Key =  UIView.SRProgressComponent.AttributedString.Key("imageProgressSize")
    static let gif: UIView.SRProgressComponent.AttributedString.Key =  UIView.SRProgressComponent.AttributedString.Key("gif")
}
