//
//  QRCodeReaderViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/10.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import AVFoundation
import Cartography

class QRCodeReaderViewController: BaseViewController {
    var device: AVCaptureDevice!
    var input: AVCaptureDeviceInput!
    var output: AVCaptureMetadataOutput!
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var previewView: UIView!
    var constraintGroup = ConstraintGroup()
    var scanRectView: UIView!
    var scanEdgeView: UIView!
    var scanRect: CGRect!
    var scanLineView: UIView!
    var isScanLineMoving = false
    var isScanLineMovable = true
    var currentDetectedCount = 0 // current count for detection
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        defaultNavigationBar("Scan QR Code".localized)
        pageBackGestureStyle = .none
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotifyDefault.add(self,
                          selector: #selector(didBecomeActive(_:)),
                          name: .UIApplicationDidBecomeActive)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        session?.startRunning()
        if scanLineView != nil && isScanLineMovable {
            scanLineView.layer.removeAllAnimations()
            scanLineStartMoving()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stopRunning()
        if scanLineView != nil {
            scanLineView.layer.removeAllAnimations()
        }
    }
    
    override func viewDidLayoutSubviews() {
        if scanRectView != nil {
            scanRect = scanRectView.frame //可探测区域
        }
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    struct Const {
        static let scanSize = CGSize(Common.screenSize().width * 2.0 / 3.0,
                                     Common.screenSize().width * 2.0 / 3.0)
        static let maskBackgroundColor = UIColor(white: 0, alpha: 0.7)
        static let edgeLineLength = scanSize.width / 8.0
        static let edgeLineThickness = 5.0 as CGFloat
        static let maxDetectedCount = 20 // the max count for detection
        static let scanLineHeight = 30.0 as CGFloat
        static let scanLineMoveDuration = 3.0 as TimeInterval
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        initPreviewView()
        initScanRectView()
        initScanLineView()
        initMaskViews()
        initScanEdgeView()
    }
    
    //为了追求scanRectView与scanRect保持一致，故建立一个视图previewView，其位置与previewLayer保持一致
    func initPreviewView() {
        previewView = UIView()
        view.addSubview(previewView)
        constraintGroup = constrain(previewView,
                                    self.car_topLayoutGuide,
                                    replace: constraintGroup) { (view, topLayoutGuide) in
            view.top == topLayoutGuide.bottom
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.trailing == view.superview!.trailing
        }
    }
    
    //扫描区域
    func initScanRectView() {
        scanRectView = UIView()
        previewView.addSubview(scanRectView)
        constrain(scanRectView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == Const.scanSize.width
            view.height == Const.scanSize.height
        }
        scanRectView.clipsToBounds = true
    }
    
    func initScanLineView() {
        scanLineView = UIView()
        scanRectView.addSubview(scanLineView)
        scanLineView.frame =
            CGRect(0, -Const.scanLineHeight, Const.scanSize.width, Const.scanLineHeight)
        scanLineView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        scanLineView.backgroundColor = UIColor(white: 1.0, alpha: 0.18)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(0, 0, Const.scanSize.width, Const.scanLineHeight)
        gradientLayer.backgroundColor = UIColor.clear.cgColor
        gradientLayer.startPoint = CGPoint(0, 0)
        gradientLayer.endPoint = CGPoint(0, 1.0)
        gradientLayer.colors = [UIColor.clear.cgColor,
                                UIColor.green.cgColor]
        scanLineView.layer.addSublayer(gradientLayer)
    }
    
    //灰色透明背景
    func initMaskViews() {
        //topMaskView
        constrain(maskView(), scanRectView) { (view1, view2) in
            view1.top == view1.superview!.top
            view1.bottom == view2.top
            view1.leading == view1.superview!.leading
            view1.trailing == view1.superview!.trailing
        }
        //bottomMaskView
        constrain(maskView(), scanRectView) { (view1, view2) in
            view1.top == view2.bottom
            view1.bottom == view1.superview!.bottom
            view1.leading == view1.superview!.leading
            view1.trailing == view1.superview!.trailing
        }
        //leftMaskView
        constrain(maskView(), scanRectView) { (view1, view2) in
            view1.top == view2.top
            view1.bottom == view2.bottom
            view1.leading == view1.superview!.leading
            view1.trailing == view2.leading
        }
        //rightMaskView
        constrain(maskView(), scanRectView) { (view1, view2) in
            view1.top == view2.top
            view1.bottom == view2.bottom
            view1.leading == view2.trailing
            view1.trailing == view1.superview!.trailing
        }
    }
    
    func maskView() -> UIView {
        let maskView = UIView()
        previewView.addSubview(maskView)
        maskView.backgroundColor = Const.maskBackgroundColor
        return maskView
    }
    
    //扫描区域四角
    func initScanEdgeView() {
        scanEdgeView = UIView()
        previewView.addSubview(scanEdgeView)
        constrain(scanEdgeView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == Const.scanSize.width + 2.0 * Const.edgeLineThickness
            view.height == Const.scanSize.height + 2.0 * Const.edgeLineThickness
        }
        scanEdgeView.backgroundColor = UIColor.clear
        
        //左上角落的两根线
        constrain(edgeLineView()) { (view) in
            view.top == view.superview!.top
            view.leading == view.superview!.leading
            view.width == Const.edgeLineThickness
            view.height == Const.edgeLineLength
        }
        constrain(edgeLineView()) { (view) in
            view.top == view.superview!.top
            view.leading == view.superview!.leading + Const.edgeLineThickness
            view.width == Const.edgeLineLength - Const.edgeLineThickness
            view.height == Const.edgeLineThickness
        }
        
        //右上角落的两根线
        constrain(edgeLineView()) { (view) in
            view.top == view.superview!.top
            view.trailing == view.superview!.trailing
            view.width == Const.edgeLineThickness
            view.height == Const.edgeLineLength
        }
        constrain(edgeLineView()) { (view) in
            view.top == view.superview!.top
            view.trailing == view.superview!.trailing - Const.edgeLineThickness
            view.width == Const.edgeLineLength - Const.edgeLineThickness
            view.height == Const.edgeLineThickness
        }
        
        //右下角落的两根线
        constrain(edgeLineView()) { (view) in
            view.bottom == view.superview!.bottom
            view.trailing == view.superview!.trailing
            view.width == Const.edgeLineThickness
            view.height == Const.edgeLineLength
        }
        constrain(edgeLineView()) { (view) in
            view.bottom == view.superview!.bottom
            view.trailing == view.superview!.trailing - Const.edgeLineThickness
            view.width == Const.edgeLineLength - Const.edgeLineThickness
            view.height == Const.edgeLineThickness
        }
        
        //左下角落的两根线
        constrain(edgeLineView()) { (view) in
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.width == Const.edgeLineThickness
            view.height == Const.edgeLineLength
        }
        constrain(edgeLineView()) { (view) in
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading + Const.edgeLineThickness
            view.width == Const.edgeLineLength - Const.edgeLineThickness
            view.height == Const.edgeLineThickness
        }
    }
    
    func edgeLineView() -> UIView {
        let edgeLineView = UIView()
        scanEdgeView.addSubview(edgeLineView)
        edgeLineView.backgroundColor = UIColor.white
        return edgeLineView
    }
    
    //通过摄像头扫描
    func scanWithCamera() {
        do {
            device = AVCaptureDevice.default(for: .video)
            input = try AVCaptureDeviceInput(device: device)
            output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            session = AVCaptureSession()
            if Common.screenSize().width < 500.0 {
                session?.sessionPreset = .vga640x480
            } else {
                session?.sessionPreset = .high
            }
            
            session?.addInput(input)
            session?.addOutput(output)
            output.metadataObjectTypes = [.qr]
            
            //设置可探测区域
            previewLayer = AVCaptureVideoPreviewLayer(session:session!)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = CGRect(0,
                                        topLayoutGuide.length,
                                        ScreenWidth(),
                                        ScreenHeight() - topLayoutGuide.length)
            view.layer.addSublayer(previewLayer)
            
            initView()
            
            //开始捕获
            session?.startRunning()
            scanLineStartMoving()
        } catch {
            let appName = Bundle.main.localizedString(forKey: "CFBundleDisplayName",
                                                      value: nil,
                                                      table: "InfoPlist")
            let message = String(format: "Please allow %@ to access your camera in the \"Settings - Privacy - Camera\" option on your phone.".localized, appName)
            //打印错误消息
            let alert = SRAlertController(title: "Alert".localized,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        constraintGroup = constrain(previewView,
                                    self.car_topLayoutGuide,
                                    replace: constraintGroup) { (view, topLayoutGuide) in
            view.top == topLayoutGuide.bottom
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.trailing == view.superview!.trailing
        }
        previewLayer.frame = CGRect(0,
                                    topLayoutGuide.length,
                                    ScreenWidth(),
                                    ScreenHeight() - topLayoutGuide.length)
        switch UIDevice.current.orientation {
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
            
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
            
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
            
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
            
        default:
            break
        }
    }
    
    //MARKL: Application become active
    
    @objc func didBecomeActive(_ notification: Notification) {
        guard isFront else {
            return
        }
        
        if scanLineView != nil && isScanLineMovable {
            scanLineView.layer.removeAllAnimations()
            scanLineStartMoving()
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        scanWithCamera()
    }
    
    func scanLineStartMoving() {
        isScanLineMoving = false
        isScanLineMovable = true
        DispatchQueue.main.async {
            self.scanLineMove()
        }
    }
    
    func scanLineMove() {
        guard !isScanLineMoving else {
            return
        }
        
        isScanLineMoving = true
        scanLineView.frame =
            CGRect(0, -Const.scanLineHeight, Const.scanSize.width, Const.scanLineHeight)
        UIView.setAnimationCurve(.linear)
        UIView.animate(withDuration: Const.scanLineMoveDuration,
                       animations:
            { [weak self] in
                if let strongSelf = self, strongSelf.isScanLineMovable {
                    strongSelf.scanLineView.frame =
                        CGRect(0,
                               Const.scanSize.height,
                               Const.scanSize.width,
                               Const.scanLineHeight)
                }
        }) { [weak self] (finished) in
            if finished {
                self?.isScanLineMoving = false
                if let strongSelf = self, strongSelf.isScanLineMovable {
                    DispatchQueue.main.async {
                        strongSelf.scanLineMove()
                    }
                }
            }
        }
    }
}

//MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeReaderViewController: AVCaptureMetadataOutputObjectsDelegate {
    //摄像头捕获
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!,
                       from connection: AVCaptureConnection!) {
        metadataObjects.forEach {
            if let codeObject = $0 as? AVMetadataMachineReadableCodeObject,
                let obj = previewLayer.transformedMetadataObject(for: codeObject) as? AVMetadataMachineReadableCodeObject {
                if scanRect.contains(obj.bounds) {
                    currentDetectedCount = currentDetectedCount + 1
                    if currentDetectedCount > Const.maxDetectedCount {
                        session?.stopRunning()
                        
                        //输出结果
                        let alert = SRAlertController(title: nil,
                                                      message: codeObject.stringValue,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK".localized,
                                                      style: .default,
                                                      handler:
                            { [weak self] action in
                                //继续扫描
                                self?.session?.startRunning()
                                self?.scanLineStartMoving()
                        }))
                        scanLineView.layer.removeAllAnimations()
                        present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

