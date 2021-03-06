//
//  UIView+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Foundation

//MARK: Frame

public extension UIView {
    var left: CGFloat {
        get {
            return frame.minX
        }
        set {
            frame = CGRect(newValue, frame.minY, frame.width, frame.height)
        }
    }
    
    var right: CGFloat {
        get {
            return frame.maxX
        }
        set {
            frame = CGRect(newValue - frame.width, frame.minY, frame.width, frame.height)
        }
    }
    
    var top: CGFloat {
        get {
            return frame.minY
        }
        set {
            frame = CGRect(frame.minX, newValue, frame.width, frame.height)
        }
    }
    
    var bottom: CGFloat {
        get {
            return frame.maxY
        }
        set {
            frame = CGRect(frame.minX, newValue - frame.height, frame.width, frame.height)
        }
    }
    
    var width: CGFloat {
        get {
            return frame.width
        }
        set {
            frame = CGRect(frame.minX, frame.minY, newValue, frame.height)
        }
    }
    
    var height: CGFloat {
        get {
            return frame.height
        }
        set {
            frame = CGRect(frame.minX, frame.minY, frame.width, newValue)
        }
    }
}

//MARK: Subview

public extension UIView {
    func viewWithClass(_ ofClass: AnyClass) -> UIView? {
        return isKind(of: ofClass) ? self : subviews.first { $0.viewWithClass(ofClass) != nil }
    }
}

//MARK: Animation

public enum AnimationType: Int {
    case fade = 0,                   //淡入淡出
    push,//推挤
    reveal,//揭开
    moveIn,//覆盖
    cube,//立方体
    suckEffect,//吮吸
    oglFlip,//翻转
    rippleEffect,//波纹
    pageCurl,//翻页
    pageUnCurl,//反翻页
    cameraIrisHollowOpen,       //开镜头
    cameraIrisHollowClose,      //关镜头
    curlDown,                   //下翻页
    curlUp,                     //上翻页
    flipFromLeft,               //左翻转
    flipFromRight,              //右翻转
    easeInEaseOut,              //类似UIAlertView弹出的效果
    easeInEaseIn               //类似UIAlertView消失的效果
}

extension UIView: CAAnimationDelegate {
    public func animation(_ type: AnimationType, subtype: String?) -> AnyObject? {
        switch (type) {
        case .fade:
            return catransition(CATransitionType.fade.rawValue, subtype: subtype)
        case .push:
            return catransition(CATransitionType.push.rawValue, subtype: subtype)
        case .reveal:
            return catransition(CATransitionType.reveal.rawValue, subtype: subtype)
        case .moveIn:
            return catransition(CATransitionType.moveIn.rawValue, subtype: subtype)
        case .cube:
            return catransition("cube", subtype: subtype)
        case .suckEffect:
            return catransition("cusuckEffectbe", subtype: subtype)
        case .oglFlip:
            return catransition("oglFlip", subtype: subtype)
        case .rippleEffect:
            return catransition("rippleEffect", subtype: subtype)
        case .pageCurl:
            return catransition("pageCurl", subtype: subtype)
        case .pageUnCurl:
            return catransition("pageUnCurl", subtype: subtype)
        case .cameraIrisHollowOpen:
            return catransition("cameraIrisHollowOpen", subtype: subtype)
        case .cameraIrisHollowClose:
            return catransition("cameraIrisHollowClose", subtype: subtype)
        case .curlDown:
            antransition(.curlDown)
        case .curlUp:
            antransition(.curlUp)
        case .flipFromLeft:
            antransition(.flipFromLeft)
        case .flipFromRight:
            antransition(.flipFromRight)
        case .easeInEaseOut:
            alpha = 1;
            let animation = CAKeyframeAnimation.init(keyPath: "transform")
            animation.duration = 0.2;
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            var values = AnyArray()
            values.append(CATransform3DMakeScale(0.1, 0.1, 1.0))
            values.append(CATransform3DMakeScale(1.1, 1.1, 1.0))
            values.append(CATransform3DMakeScale(0.9, 0.9, 0.9))
            values.append(CATransform3DMakeScale(1.0, 1.0, 1.0))
            animation.values = values
            animation.timingFunction = CAMediaTimingFunction(name:.easeInEaseOut)
            layer.add(animation, forKey: nil)
            return animation
        case .easeInEaseIn:
            let animation = CAKeyframeAnimation.init(keyPath: "transform")
            animation.delegate = self;
            animation.duration = 0.2;
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            var values = AnyArray()
            values.append(CATransform3DMakeScale(1.0, 1.0, 1.0))
            values.append(CATransform3DMakeScale(0.9, 0.9, 0.9))
            values.append(CATransform3DMakeScale(1.1, 1.1, 1.0))
            values.append(CATransform3DMakeScale(0.1, 0.1, 1.0))
            animation.values = values
            animation.timingFunction = CAMediaTimingFunction(name:.easeInEaseOut)
            layer.add(animation, forKey: nil)
            return animation
        }
        return nil;
    }
    
    public func catransition(_ type: String?, subtype: String?) -> CATransition? {
        let animation = CATransition()//创建CATransition对象
        animation.duration = 0.5//设置运动时间
        animation.type = CATransitionType(rawValue: type!)//设置运动type
        if (subtype != nil) {
            animation.subtype = subtype.map { CATransitionSubtype(rawValue: $0) };//设置子类
        }
        
        //设置运动速度
        animation.timingFunction = CAMediaTimingFunction(name:.easeInEaseOut)
        layer.add(animation, forKey: "animation")
        return animation;
    }
    
    public func antransition(_ transition: UIView.AnimationTransition) {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationTransition(transition, for: self, cache: true)
        })
    }
}

//MARK: Mutex Touch

//针对按钮点击、多点触摸等做的互斥锁，该方法应该在按钮点击、触摸手势等的响应事件开始调用
//若返回false，表示当前已有按钮点击、触摸手势等事件生效，应提前结束按钮点击、触摸手势等响应
//若返回true，则表示已handle了当前时间段的按钮点击、触摸手势等事件响应
public var MutexTouch: Bool {
    return UIView.MutexTouchClass.shared.startTouchHandling()
}

public func MutexTouch(_ interval: TimeInterval) -> Bool {
    return UIView.MutexTouchClass.shared.startTouchHandling(interval)
}

extension UIView {
    class MutexTouchClass: NSObject {
        class var shared: MutexTouchClass {
            if sharedInstance == nil {
                sharedInstance = MutexTouchClass()
            }
            return sharedInstance!
        }
        
        private static var sharedInstance: MutexTouchClass?
        
        private override init() {
            super.init()
        }
        
        //MARK: Lock & unlock on views
        
        @objc func resetViewEnabled(_ timer: Timer) {
            if let view = timer.userInfo as? UIView {
                view.isUserInteractionEnabled = true
            }
        }
        
        let maskButton = UIButton(type: .custom)
        
        @objc func resetButtonEnabled(_ timer: Timer) {
            if let maskButton = timer.userInfo as? UIButton {
                maskButton.removeFromSuperview()
            }
        }
        
        private var isTouchHandling = false
        
        func startTouchHandling(_ interval: TimeInterval = 0.3) -> Bool {
            guard !isTouchHandling else { return false }
            isTouchHandling = true
            perform(#selector(resetTouchHandling),
                    with: nil,
                    afterDelay: interval,
                    inModes: [.common])
            return true
        }
        
        @objc func resetTouchHandling() {
            isTouchHandling = false
        }
    }
    
    /**
     *  将UIView的userInteractionEnabled置为NO一段时间，
     *  后面会调用SRCommon.shared的方法将userInteractionEnabled恢复
     *  用于[UIViewController showToast]方法中
     *
     *  @param view   view
     *  @param second second
     */
    func unableTimed(_ duration: TimeInterval = 20) {
        isUserInteractionEnabled = false
        weak var weakView = self
        Timer.scheduledTimer(timeInterval: duration,
                             target: MutexTouchClass.shared,
                             selector: #selector(MutexTouchClass.resetViewEnabled(_:)),
                             userInfo: weakView,
                             repeats: false)
    }
    
    /**
     *  使用增加子视图的方式覆盖现有的button
     *
     *  @param button
     */
    func unableTimed(button: UIButton?) {
        guard let button = button else { return }
        
        let maskButton = MutexTouchClass.shared.maskButton
        maskButton.frame = button.frame
        button.superview?.addSubview(maskButton)
        weak var weakButton = maskButton
        Timer.scheduledTimer(timeInterval: 1.0,
                             target: MutexTouchClass.shared,
                             selector: #selector(MutexTouchClass.resetButtonEnabled(_:)),
                             userInfo: weakButton,
                             repeats: false)
    }
}

//MARK: Main thread guard

extension UIView {
    static var isMainThreadGuarded = false
    
    public static func mainThreadGuardSwizzleMethods() {
        guard !isMainThreadGuarded else { return }
        SRKit.methodSwizzling(UIView.self,
                              originalSelector: #selector(UIView.setNeedsLayout),
                              swizzledSelector: Selector(("mainThreadGuardSetNeedsLayout")))
        SRKit.methodSwizzling(UIView.self,
                              originalSelector: #selector(UIView.setNeedsDisplay as (UIView) -> () -> Void),
                              swizzledSelector: Selector(("mainThreadGuardSetNeedsDisplay")))
        SRKit.methodSwizzling(UIView.self,
                              originalSelector: #selector(UIView.setNeedsDisplay(_:)),
                              swizzledSelector: Selector(("mainThreadGuardSetNeedsDisplay:")))
        isMainThreadGuarded = true
    }
    
    func mainThreadGuardSetNeedsLayout() {
        assert(Thread.isMainThread, "call UIView.setNeedsLayout() not in main thread")
        self.mainThreadGuardSetNeedsLayout()
    }
    
    func mainThreadGuardSetNeedsDisplay() {
        assert(Thread.isMainThread, "call UIView.setNeedsDisplay() not in main thread")
        self.mainThreadGuardSetNeedsDisplay()
    }
    
    func mainThreadGuardSetNeedsDisplay(_ rect: CGRect) {
        assert(Thread.isMainThread, "call UIView.setNeedsDisplay(_:) not in main thread")
        self.mainThreadGuardSetNeedsDisplay(rect)
    }
}

