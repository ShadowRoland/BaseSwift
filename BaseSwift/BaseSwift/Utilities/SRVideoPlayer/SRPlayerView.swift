//
//  SRPlayerView.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/8.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import AVFoundation

class SRPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self.self
    }
}
