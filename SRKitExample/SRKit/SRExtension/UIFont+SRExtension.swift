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
    class func light(_ size: CGFloat) -> UIFont {
        return  .systemFont(ofSize: size, weight: .light)
    }
    
    class func system(_ size: CGFloat) -> UIFont {
        return  .systemFont(ofSize: size)
    }
    
    class func medium(_ size: CGFloat) -> UIFont {
        return  .systemFont(ofSize: size, weight: .medium)
    }
    
    class func bold(_ size: CGFloat) -> UIFont {
        return  .systemFont(ofSize: size, weight: .bold)
    }
    
    struct Preferred {
        public static var headline: UIFont {
            return .preferredFont(forTextStyle: .headline)
        }
        
        public static var subheadline: UIFont {
            return .preferredFont(forTextStyle: .subheadline)
        }
        
        public static var body: UIFont {
            return .preferredFont(forTextStyle: .body)
        }
        
        public static var footnote: UIFont {
            return .preferredFont(forTextStyle: .footnote)
        }
        
        public static var caption1: UIFont {
            return .preferredFont(forTextStyle: .caption1)
        }
        
        public static var caption2: UIFont {
            return .preferredFont(forTextStyle: .caption2)
        }
    }
}
