//
//  CustomCalloutView.swift
//  BaseSwift
//
//  Created by Gary on 2017/6/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import QuartzCore

protocol CustomCalloutDelegate: class {
    func didShow(_ calloutView: CustomCalloutView!)
    func didHide(_ calloutView: CustomCalloutView!)
    func distance(of calloutView: CustomCalloutView!) -> String!
    func selectedRoutePlanningType(of calloutView: CustomCalloutView!) -> RoutePlanningType!
    func calloutView(_ calloutView: CustomCalloutView!, didSelected routePlanningType: RoutePlanningType)
    func startNavigate(_ calloutView: CustomCalloutView!, type routePlanningType: RoutePlanningType)
}

extension CustomCalloutDelegate {
    func didShow(_ calloutView: CustomCalloutView!) {
        
    }
    
    func didHide(_ calloutView: CustomCalloutView!) {
        
    }
    
    func distance(of calloutView: CustomCalloutView!) -> String! {
        return nil
    }
    
    func selectedRoutePlanningType(of calloutView: CustomCalloutView!) -> RoutePlanningType! {
        return .none
    }
    
    func calloutView(_ calloutView: CustomCalloutView!, didSelected routePlanningType: RoutePlanningType) {
        
    }
    
    func startNavigate(_ calloutView: CustomCalloutView!, type routePlanningType: RoutePlanningType) {
        
    }
}

enum RoutePlanningType: Int {
    case none = 0,
    car,
    bus,
    foot,
    bike
}

class CustomCalloutView: UIView {
    private(set) var poi: AMapPOI!
    private weak var delegate: CustomCalloutDelegate?
    var selectedRoutePlanningType: RoutePlanningType = .foot {
        didSet {
            if selectedRoutePlanningType == oldValue {
                return
            }
            
            trafficButton(oldValue)?.backgroundColor = UIColor.clear
            trafficButton(selectedRoutePlanningType)?.backgroundColor = UIColor.yellow
            durationLabel.text = selectedRoutePlanningType == .none
                ? "Choose the way to arrive".localized
                : "Computing".localized
        }
    }

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var busButton: UIButton!
    @IBOutlet weak var footButton: UIButton!
    @IBOutlet weak var bikeButton: UIButton!
    
    struct Const {
        static let width = 220.0 as CGFloat
        static let padding = 10.0 as CGFloat
        static let paddingBottom = 20.0 as CGFloat
        static let addressMarginVertical = 5.0 as CGFloat
        static let phoneMarginBottom = 3.0 as CGFloat
        static let intervalHeight = 30.0 as CGFloat
        static let trafficHeight = 40.0 as CGFloat
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
        backgroundColor = UIColor.clear
    }

    override func draw(_ rect: CGRect) {
        draw(UIGraphicsGetCurrentContext()!)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    func draw(_ context: CGContext) {
        context.setLineWidth(2.0)
        context.setFillColor(UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8).cgColor)
        drawPath(context)
        context.fillPath()
    }
    
    func drawPath(_ context: CGContext) {
        let rect = bounds
        let radius = 6.0 as CGFloat
        let arrorHeight = 10.0 as CGFloat
        let minX = rect.minX
        let midX = rect.midX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY - arrorHeight
        
        context.move(to: CGPoint(x: midX + arrorHeight, y: maxY))
        context.addLine(to: CGPoint(x: midX, y: maxY + arrorHeight))
        context.addLine(to: CGPoint(x: midX - arrorHeight, y: maxY))
        
        context.addArc(tangent1End: CGPoint(x: minX, y: maxY),
                       tangent2End: CGPoint(x: minX, y: minY),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: minX, y: minX),
                       tangent2End: CGPoint(x: maxX, y: minY),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: maxX, y: minY),
                       tangent2End: CGPoint(x: maxX, y: maxX),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: maxX, y: maxY),
                       tangent2End: CGPoint(x: midX, y: midX),
                       radius: radius)
        
        context.closePath()
    }
    
    func trafficButton(_ type: RoutePlanningType) -> UIButton? {
        switch type {
        case .car:
            return carButton
            
        case .bus:
            return busButton
            
        case .foot:
            return footButton
            
        case .bike:
            return bikeButton
            
        default:
            return nil
        }
    }
    
    func hitView(_ point: CGPoint) -> UIView? {
        if isHitView(phoneButton, point: point) {
            return phoneButton
        } else if isHitView(navigateButton, point: point) {
            return navigateButton
        } else if isHitView(carButton, point: point) {
            return carButton
        } else if isHitView(busButton, point: point) {
            return busButton
        } else if isHitView(footButton, point: point) {
            return footButton
        } else if isHitView(bikeButton, point: point) {
            return bikeButton
        } else {
            return nil
        }
    }
    
    func isHitView(_ subview: UIView!, point: CGPoint) -> Bool {
        return subview.bounds.contains(subview.convert(point, from: superview))
    }
    
    @IBAction func clickPhoneButton(_ sender: Any) {
        DispatchQueue.main.async {
            UIApplication.shared.openURL(URL(string: "tel://\(self.phoneLabel.text!)")!)
        }
    }
    
    @IBAction func clickNavigateButton(_ sender: Any) {
        delegate?.startNavigate(self, type: selectedRoutePlanningType)
    }
    
    @IBAction func clickCarButton(_ sender: Any) {
        selectedRoutePlanningType = selectedRoutePlanningType == .car ? .none : .car
        delegate?.calloutView(self, didSelected: selectedRoutePlanningType)
    }
    
    @IBAction func clickBusButton(_ sender: Any) {
        selectedRoutePlanningType = selectedRoutePlanningType == .bus ? .none : .bus
        delegate?.calloutView(self, didSelected: selectedRoutePlanningType)
    }
    
    @IBAction func clickFootButton(_ sender: Any) {
        selectedRoutePlanningType = selectedRoutePlanningType == .foot ? .none : .foot
        delegate?.calloutView(self, didSelected: selectedRoutePlanningType)
    }
    
    @IBAction func clickBikeButton(_ sender: Any) {
        selectedRoutePlanningType = selectedRoutePlanningType == .bike ? .none : .bike
        delegate?.calloutView(self, didSelected: selectedRoutePlanningType)
    }
    
    func show(_ annotationView: MAAnnotationView, poi: AMapPOI!, delegate: CustomCalloutDelegate?) {
        phoneLabel.adjustsFontSizeToFitWidth = true
        durationLabel.adjustsFontSizeToFitWidth = true
        navigateButton.layer.borderColor = UIColor.white.cgColor
        navigateButton.layer.borderWidth = 2.0
        navigateButton.layer.cornerRadius = 5.0
        navigateButton.clipsToBounds = true
        
        self.poi = poi
        self.delegate = delegate
        
        let width = Const.width - Const.padding
        var text = poi.name
        var nameHeight = 0 as CGFloat
        if let text = text, !text.isEmpty {
            nameHeight = ceil(text.textSize(nameLabel.font, maxWidth: width).height)
        }
        nameLabel.text = text
        nameHeightConstraint.constant = nameHeight
        
        text = ""
        if let distance = self.delegate?.distance(of: self), !distance.isEmpty {
            text = "From you".localized + distance + " "
        } else {
            if poi.distance < 1000 {
                text = "From you".localized + String(int: poi.distance) + Config.Unit.metre + " "
            } else {
                text = "From you".localized + String(format: "%.2f", Float(poi.distance) / 1000.0) + Config.Unit.kilometre2 + " "
            }
        }
        text = text! + poi.address
        var addressHeight = 0 as CGFloat
        if let text = text, !text.isEmpty {
            addressHeight =
                ceil(text.textSize(addressLabel.font, maxWidth: width).height)
        }
        addressLabel.text = text
        addressHeightConstraint.constant = addressHeight
        
        text = poi.tel
        var phoneWidth = 0 as CGFloat
        var phoneHeight = 0 as CGFloat
        if let text = text, !text.isEmpty {
            let size = text.textSize(phoneLabel.font, maxWidth: width)
            phoneWidth = min(width, ceil(size.width))
            phoneHeight = ceil(size.height)
        }
        phoneLabel.text = text
        phoneWidthConstraint.constant = phoneWidth
        phoneHeightConstraint.constant = phoneHeight
        
        selectedRoutePlanningType = .none
        if let type = self.delegate?.selectedRoutePlanningType(of: self) {
            selectedRoutePlanningType = type
        }
        
        annotationView.addSubview(self)
        frame = CGRect(0,
                        0,
                        Const.width,
                        Const.padding
                            + nameHeight
                            + 2.0 * Const.addressMarginVertical + addressHeight
                            + phoneHeight + Const.phoneMarginBottom
                            + Const.intervalHeight
                            + Const.trafficHeight
                            + Const.paddingBottom)
        center = CGPoint(annotationView.width / 2.0 + annotationView.calloutOffset.x,
                         -self.height / 2.0 + annotationView.calloutOffset.y)
    }
    
    func hide() {
        removeFromSuperview()
        delegate?.didHide(self)
        delegate = nil
    }
}
