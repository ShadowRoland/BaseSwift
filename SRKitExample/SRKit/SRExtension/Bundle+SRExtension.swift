//
//  Bundle+SRExtension.swift
//  SRKit
//
//  Created by Gary on 2019/4/15.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit

extension Bundle {    
    static var srBundle: Bundle!
    class var sr: Bundle {
        if Bundle.srBundle == nil {
            Bundle.srBundle = Bundle(path: Bundle(for: SRKit.self).path(forResource: "SRKit", ofType: "bundle")!)
        }
        return Bundle.srBundle
    }
}
