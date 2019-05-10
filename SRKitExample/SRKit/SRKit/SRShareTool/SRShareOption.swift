//
//  SRShareOption.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/12.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

//目前仅支持分享链接，如需分享其他资源（图片，视频，位置），仍需要定制
public class SRShareOption {
    private(set) var title: String?
    private(set) var description: String?
    private(set) var url: String?
    private(set) var image: UIImage?
    
    public init(title: String? = nil,
                description: String? = nil,
                url: String? = nil,
                image: UIImage? = nil) {
        self.title = title
        self.description = title
        self.url = url
        self.image = image
    }
}
