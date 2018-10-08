//
//  CustomAnnotationView.swift
//  BaseSwift
//
//  Created by Gary on 2017/6/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class CustomAnnotationView: MAPinAnnotationView {
    weak var delegate: CustomCalloutDelegate?
    var poi: AMapPOI!
    var calloutView: CustomCalloutView?
    
    deinit {
        calloutView?.hide()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        guard isSelected != selected else {
            return
        }
        
        if selected {
            if calloutView == nil {
                calloutView = Bundle.main.loadNibNamed("CustomCalloutView",
                                                       owner: nil,
                                                       options: nil)?.first as? CustomCalloutView
            }
            calloutView!.show(self, poi: poi, delegate: delegate)
        } else {
            calloutView?.hide()
        }
        
        super.setSelected(selected, animated: animated)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == nil, let calloutView = calloutView, calloutView.superview == self {
            return calloutView.hitView(point)
        }
        
        return view
    }
}
