//
//  CGSize+Extension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation

public extension UIFont {
    public class func system(_ size: CGFloat) -> UIFont {
        return  UIFont.systemFont(ofSize: size)
    }
    
    public struct Preferred {
        public static var headline: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        }
        
        public static var subheadline: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
        }
        
        public static var body: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        }
        
        public static var footnote: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        }
        
        public static var caption1: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        }
        
        public static var caption2: UIFont {
            return UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        }
    }
}
