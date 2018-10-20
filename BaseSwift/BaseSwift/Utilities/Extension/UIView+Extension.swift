//
//  UIView+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

//MARK: Frame

public extension UIView {
    var top: CGFloat {
        return frame.origin.x
    }
    
    var bottom: CGFloat {
        return frame.origin.y + frame.size.height
    }
    
    var left: CGFloat {
        return frame.origin.x
    }
    
    var right: CGFloat {
        return frame.origin.x + frame.size.width
    }
    
    var width: CGFloat {
        return frame.size.width
    }
    
    var height: CGFloat {
        return frame.size.height
    }
}

//MARK: Subview

public extension UIView {
    func viewWithClass(_ ofClass: AnyClass) -> UIView? {
        return isKind(of: ofClass) ? self : subviews.first { $0.viewWithClass(ofClass) != nil }
    }
}

//MARK: - TagString

public extension UIView {
    fileprivate struct AssociatedKeys {
        static var tagString = "UIView.TagString"
    }
    
    var tagString: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.tagString) as? String
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.tagString,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
            return catransition(kCATransitionFade, subtype: subtype)
        case .push:
            return catransition(kCATransitionPush, subtype: subtype)
        case .reveal:
            return catransition(kCATransitionReveal, subtype: subtype)
        case .moveIn:
            return catransition(kCATransitionMoveIn, subtype: subtype)
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
            antransition(UIViewAnimationTransition.curlDown)
        case .curlUp:
            antransition(UIViewAnimationTransition.curlUp)
        case .flipFromLeft:
            antransition(UIViewAnimationTransition.flipFromLeft)
        case .flipFromRight:
            antransition(UIViewAnimationTransition.flipFromRight)
        case .easeInEaseOut:
            alpha = 1;
            let animation = CAKeyframeAnimation.init(keyPath: "transform")
            animation.duration = 0.2;
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            var values = Array<Any>()
            values.append(CATransform3DMakeScale(0.1, 0.1, 1.0))
            values.append(CATransform3DMakeScale(1.1, 1.1, 1.0))
            values.append(CATransform3DMakeScale(0.9, 0.9, 0.9))
            values.append(CATransform3DMakeScale(1.0, 1.0, 1.0))
            animation.values = values
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
            layer.add(animation, forKey: nil)
            return animation
        case .easeInEaseIn:
            let animation = CAKeyframeAnimation.init(keyPath: "transform")
            animation.delegate = self;
            animation.duration = 0.2;
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            var values = Array<Any>()
            values.append(CATransform3DMakeScale(1.0, 1.0, 1.0))
            values.append(CATransform3DMakeScale(0.9, 0.9, 0.9))
            values.append(CATransform3DMakeScale(1.1, 1.1, 1.0))
            values.append(CATransform3DMakeScale(0.1, 0.1, 1.0))
            animation.values = values
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
            layer.add(animation, forKey: nil)
            return animation
        }
        return nil;
    }
    
    public func catransition(_ type: String?, subtype: String?) -> CATransition? {
        let animation = CATransition()//创建CATransition对象
        animation.duration = 0.5//设置运动时间
        animation.type = type!//设置运动type
        if (subtype != nil) {
            animation.subtype = subtype;//设置子类
        }
        
        //设置运动速度
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        layer.add(animation, forKey: "animation")
        return animation;
    }
    
    public func antransition(_ transition: UIViewAnimationTransition) {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            UIView.setAnimationCurve(UIViewAnimationCurve.easeInOut)
            UIView.setAnimationTransition(transition, for: self, cache: true)
        })
    }
}
