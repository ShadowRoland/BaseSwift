//
//  SRPickerView.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/9.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Cartography

public protocol SRPickerViewDelegate: class {
    func pickerView(didCancel pickerView: SRPickerView)
    func pickerView(didConfirm pickerView: SRPickerView)
}

extension SRPickerViewDelegate {
    func pickerView(didCancel pickerView: SRPickerView) { }
    func pickerView(didConfirm pickerView: SRPickerView) { }
}

public class SRPickerView: UIView {
    public var pickerView: UIPickerView! { return _pickerView }
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    public weak var delegate: SRPickerViewDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            if let delegate = newValue as? UIPickerViewDelegate {
                pickerView.delegate = delegate
            }
        }
    }
    
    public weak var dataSource: UIPickerViewDataSource? {
        get {
            return _dataSource
        }
        set {
            pickerView.dataSource = newValue
        }
    }
    
    private weak var _delegate: SRPickerViewDelegate?
    private weak var _dataSource: UIPickerViewDataSource?
    private var titleLabel: UILabel!
    private var cancelButton: UIButton!
    private var confirmButton: UIButton!
    private var _pickerView: UIPickerView!
    
    struct Const {
        static let pickerViewHeight = 160.0 as CGFloat
        static let titleLabelMargin = 10.0 as CGFloat
        static let buttonWidth = C.subviewMargin + 50.0 as CGFloat
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect())
        initView()
    }
    
    init() {
        super.init(frame: CGRect())
        initView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        backgroundColor = .clear
        let maskView = UIView()
        maskView.backgroundColor = C.maskBackgroundColor
        addSubview(maskView)
        constrain(maskView) { $0.edges == inset($0.superview!.edges, 0) }
        
        let bottomView = UIView()
        bottomView.backgroundColor = .groupTableViewBackground
        bottomView.isUserInteractionEnabled = true
        addSubview(bottomView)
        constrain(bottomView) { (view) in
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.trailing == view.superview!.trailing
            view.height == C.tableCellHeight + Const.pickerViewHeight
        }
        
        cancelButton = UIButton(type: .custom)
        cancelButton.title = "[SR]Cancel".srLocalized
        cancelButton.titleColor = .darkText
        cancelButton.contentEdgeInsets = UIEdgeInsets(0, C.subviewMargin, 0, 0)
        cancelButton.clicked(self, action: #selector(clickCancelButton(_:)))
        bottomView.addSubview(cancelButton)
        constrain(cancelButton) { (view) in
            view.top == view.superview!.top
            view.leading == view.superview!.leading
            view.width == Const.buttonWidth
            view.height == C.tableCellHeight
        }
        
        confirmButton = UIButton(type: .custom)
        confirmButton.title = "[SR]OK".srLocalized
        confirmButton.titleColor = .darkText
        confirmButton.contentEdgeInsets = UIEdgeInsets(0, 0, 0, C.subviewMargin)
        confirmButton.clicked(self, action: #selector(clickConfirmButton(_:)))
        bottomView.addSubview(confirmButton)
        constrain(confirmButton) { (view) in
            view.top == view.superview!.top
            view.trailing == view.superview!.trailing
            view.width == Const.buttonWidth
            view.height == C.tableCellHeight
        }
        
        titleLabel = UILabel()
        titleLabel.font = C.Font.text
        titleLabel.textColor = UIColor(hue: 224.0, saturation: 50.0, brightness: 63.0)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        //titleLabel.adjustsFontSizeToFitWidth = true
        bottomView.addSubview(titleLabel)
        constrain(titleLabel) { (view) in
            view.top == view.superview!.top
            view.height == C.tableCellHeight
        }
        constrain(titleLabel, cancelButton) { (view1, view2) in
            view1.leading == view2.trailing + Const.titleLabelMargin
        }
        constrain(titleLabel, confirmButton) { (view1, view2) in
            view2.leading == view1.trailing + Const.titleLabelMargin
        }
        
        _pickerView = UIPickerView()
        bottomView.insertSubview(_pickerView, at: 0)
        constrain(_pickerView) { (view) in
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.trailing == view.superview!.trailing
            view.height == Const.pickerViewHeight
        }
    }
    
    //MARK: - 事件响应

    @objc func clickCancelButton(_ sender: Any) {
        guard MutexTouch else { return }
        _delegate?.pickerView(didCancel: self)
        removeFromSuperview()
    }
    
    @objc func clickConfirmButton(_ sender: Any) {
        guard MutexTouch else { return }
        _delegate?.pickerView(didConfirm: self)
        removeFromSuperview()
    }
}
