//
//  UIImage+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension UIImage {
    convenience init?(_ name: String) {
        self.init(named: name)
    }
}

//MARK: 形状

public extension UIImage {
    //画长方形图
    static func rect(_ color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    //画圆图
    static func circle(_ color: UIColor, radius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: CGPoint(), size: CGSize(2.0 * radius, 2.0 * radius))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        context.setFillColor(color.cgColor)
        context.setLineWidth(0)
        context.addArc(center: CGPoint(x: radius, y: radius),
                       radius: radius,
                       startAngle: 0,
                       endAngle: 2.0 * CGFloat.pi,
                       clockwise: true)
        context.drawPath(using: CGPathDrawingMode.eoFillStroke)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    //画圆柱截面饼图
    static func cylinder(_ color: UIColor, size: CGSize) -> UIImage? {
        guard size.width != size.height else {
            return circle(color, radius: size.width / 2.0)
        }
        
        let radius = min(size.width, size.height) / 2.0
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        context.setFillColor(color.cgColor)
        context.setLineWidth(0)
        context.addArc(center: CGPoint(x: radius, y: radius),
                       radius: radius,
                       startAngle: 0,
                       endAngle: 2 * CGFloat.pi,
                       clockwise: true)
        context.drawPath(using: CGPathDrawingMode.eoFillStroke)
        if size.width > size.height {
            context.addArc(center: CGPoint(x: size.width - radius, y: radius),
                           radius: radius,
                           startAngle: 0,
                           endAngle: 2.0 * CGFloat.pi,
                           clockwise: true)
            context.drawPath(using: CGPathDrawingMode.eoFillStroke)
            context.addRect(CGRect(x: radius,
                                   y: 0,
                                   width: size.width - size.height,
                                   height: size.height))
            context.drawPath(using: CGPathDrawingMode.fillStroke)
        } else {
            context.addArc(center: CGPoint(x: radius, y: size.height - radius),
                           radius: radius,
                           startAngle: 0 * CGFloat.pi,
                           endAngle: 2.0 * CGFloat.pi,
                           clockwise: true)
            context.drawPath(using: CGPathDrawingMode.eoFillStroke)
            context.addRect(CGRect(x: 0,
                                   y: radius,
                                   width: size.height - size.width,
                                   height: size.width))
            context.drawPath(using: CGPathDrawingMode.fillStroke)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    //画渐变色图片
    static func gradient(_ fromColor: UIColor, toColor: UIColor, size: CGSize) -> UIImage? {
        return gradient([fromColor, toColor], locations: [0.0, 1.0], size: size)
    }
    
    static func  gradient(_ colors: [UIColor], locations: [CGFloat], size: CGSize) -> UIImage? {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors.map { $0.cgColor } as CFArray,
                                        locations: locations) else
        {
            return nil
        }
        
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        
        let startPoint = CGPoint(rect.minX, rect.minY)
        let endPoint = CGPoint(rect.maxX, rect.maxY)
        
        context.drawLinearGradient(gradient,
                                   start: startPoint,
                                   end: endPoint,
                                   options: .drawsAfterEndLocation)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

//MARK: 图片处理

extension UIImage {
    //按宽高比裁剪图片
    func cropped(_ ratio: CGFloat) -> UIImage {
        guard ratio > 0 && size.width != size.height * ratio else { //数字无效或者比例一致，直接返回
            return self
        }
        
        let width = size.width
        let height = size.height
        //待参见的区域
        var rect = CGRect(0, 0, width, height * ratio)
        if width > height * ratio { //图片较胖
            rect.origin.x = (width - height * ratio) / 2.0
            rect.size.width = height * ratio
        } else { //图片较瘦
            rect.origin.y = (height - (width / ratio)) / 2.0
            rect.size.height = width / ratio
        }
        
        return UIImage(cgImage: cgImage!.cropping(to: rect)!,
                       scale: scale,
                       orientation: imageOrientation)
    }
    
    /**
     *  等比例压缩图片并限制图片字节数
     *
     *  @param maxSize 压缩后图片的最大尺寸
     *  @param maxLength 压缩后图片的最大字节数，为0表示无限制
     */
    func compressedJPGData(_ maxSize: CGSize, maxLength: Int = 0) -> Data? {
        let image = compressed(maxSize)
        if maxLength <= 0 {
            return UIImageJPEGRepresentation(image, 1.0)
        }
        
        var quality = 1.0 as CGFloat
        var data = UIImageJPEGRepresentation(image, quality)
        while (data != nil && data!.count > maxLength && quality > 0) {
            quality -= 0.1
            data = UIImageJPEGRepresentation(image, quality)
        }
        
        return data
    }
    
    /**
     *  等比例压缩图片
     *
     *  @param maxSize 压缩后图片的最大尺寸
     */
    func compressed(_ maxSize: CGSize) -> UIImage {
        guard size.width > 0 && size.height > 0 && maxSize.width > 0 && maxSize.height > 0 else {
            return self
        }
        
        return resized(size.fitSize(maxSize: maxSize))
    }
    
    func resized(_ size: CGSize) -> UIImage {
        guard size.width > 0 && size.height > 0 else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(0, 0, size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
