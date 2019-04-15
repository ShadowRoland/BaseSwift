//
//  UITableView+SRExtension.swift
//  BaseSwift
//
//  Created by Gary on 2018/8/8.
//  Copyright © 2018年 shadowR. All rights reserved.
//

import UIKit

public extension UITableView {
    var visibleContentRect: CGRect {
        return CGRect(0,
                      contentOffset.y + contentInset.top,
                      self.width,
                      self.height - contentInset.top - contentInset.bottom)
    }
}
