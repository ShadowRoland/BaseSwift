//
//  CGSize+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Foundation

public extension UIFont {
    class func system(_ size: CGFloat) -> UIFont {
        return  UIFont.systemFont(ofSize: size)
    }
    
    struct Preferred {
        public static var headline: UIFont {
            return UIFont.preferredFont(forTextStyle: .headline)
        }
        
        public static var subheadline: UIFont {
            return UIFont.preferredFont(forTextStyle: .subheadline)
        }
        
        public static var body: UIFont {
            return UIFont.preferredFont(forTextStyle: .body)
        }
        
        public static var footnote: UIFont {
            return UIFont.preferredFont(forTextStyle: .footnote)
        }
        
        public static var caption1: UIFont {
            return UIFont.preferredFont(forTextStyle: .caption1)
        }
        
        public static var caption2: UIFont {
            return UIFont.preferredFont(forTextStyle: .caption2)
        }
    }
}
