//
//  swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/16.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import Toast
import SwiftyJSON
import CocoaLumberjack
import KeychainSwift

open class BaseCommon: NSObject {
    
    //MARK: - Device & OS System
    
    private static var _devieModel: String?
    
    open class func devieModel() -> String {
        if _devieModel == nil {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            _devieModel = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else {
                    return identifier
                }
                return identifier! + String(UnicodeScalar(UInt8(value)))
            }
        }
        
        return _devieModel!
    }
    
    private static var _screenScale: ScreenScale = .none
    
    @discardableResult
    open class func screenScale() -> ScreenScale {
        if _screenScale == .none {
            let size: CGSize = UIScreen.main.currentMode!.size
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                _screenScale = .iPad
            } else if size.equalTo(CGSize(width: 640, height: 960)) {
                _screenScale = .iPhone4
            } else if size.equalTo(CGSize(width: 640, height: 1136)) {
                _screenScale = .iPhone5
            } else if size.equalTo(CGSize(width: 750, height: 1334)) {
                _screenScale = .iPhone6
            } else if size.equalTo(CGSize(width: 1242, height: 2208)) {
                _screenScale = .iPhone6P
            } else if size.equalTo(CGSize(width: 1125, height: 2436)) {
                _screenScale = .iPhoneX
                StatusBarHeight = 44.0
                NavigationHeaderHeight = StatusBarHeight + NavigationBarHeight
                TabBarHeight = 83.0
                SafeInsetTop = 34.0
                SafeInsetBottom = 34.0
            } else {
                _screenScale = .unknown
            }
            DispatchQueue.main.async {
                LogInfo("Current screen size: \(size.width), \(size.height)")
            }
        }
        return _screenScale
    }
    
    private static var screenPortraitSize: CGSize?
    private static var screenLandscapeSize: CGSize?
    
    open class func screenSize(_ interfaceOrientation: UIInterfaceOrientationMask = .portrait) -> CGSize {
        if screenPortraitSize == nil {
            let size: CGSize = (UIScreen.main.currentMode?.size)!
            if size.width < size.height {
                screenPortraitSize = CGSize(width: size.width / 2.0, height: size.height / 2.0)
                screenLandscapeSize = CGSize(width: size.height / 2.0, height: size.width / 2.0)
            } else {
                screenPortraitSize = CGSize(width: size.height / 2.0, height: size.width / 2.0)
                screenLandscapeSize = CGSize(width: size.width / 2.0, height: size.height / 2.0)
            }
        }
        if interfaceOrientation == .portrait {
            return screenPortraitSize!
        } else {
            return screenLandscapeSize!
        }
    }
    
    //移动设备的唯一uuid，在登录时判断是否换移动设备
    private static var _uuid: String?
    
    open class func uuid() -> String {
        guard BaseCommon._uuid == nil else {
            return BaseCommon._uuid!
        }
        
        let keychain = KeychainSwift()
        if let string = keychain.get("uuid") {
            BaseCommon._uuid = string
        } else {
            let string = UIDevice.current.identifierForVendor!.uuidString.lowercased()
            BaseCommon._uuid = string.replacingOccurrences(of: "-", with: "")
            keychain.set(BaseCommon._uuid!, forKey: "uuid")
        }
        return BaseCommon._uuid!
    }
    
    //MARK: Current
    
    //推送的deviceToken
    private static var deviceToken = EmptyString
    
    open class func currentDeviceToken() -> String {
        if deviceToken == EmptyString,
            let token = UserStandard[USKey.currentDeviceToken] as? String {
            deviceToken = token
        }
        return deviceToken
    }
    
    open class func updateDeviceToken(_ deviceToken: String) {
        BaseCommon.deviceToken = deviceToken
        UserStandard[USKey.currentDeviceToken] = deviceToken
    }
    
    //MARK: - File System
    
    open class func readJsonFile(_ filePath: String) -> AnyObject? {
        var data: Data?
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            LogWarn(String(format: "read JSON file failed!\nerror: %@\nfile path: %@",
                           error.localizedDescription,
                           filePath))
            return nil
        }
        
        var object: AnyObject?
        do {
            object = try JSON(data: data!).rawValue as AnyObject?
        } catch {
            LogWarn(String(format: "convert data to JSON failed!\nerror: %@\nfile path: %@",
                           error.localizedDescription,
                           filePath))
        }
        return object
    }
    
    open class func jsonString(_ jsonObject: Any?) -> String? {
        guard let jsonObject = jsonObject else { return nil }
        return JSON(jsonObject).rawString()
    }
    
    open class func jsonData(_ jsonObject: Any?) -> Data? {
        guard let jsonObject = jsonObject else { return nil }
        
        var data: Data?
        do {
            //try data = JSONSerialization.data(withJSONObject: jsonObject,
            //                                  options: .prettyPrinted)
            try data = JSON(jsonObject).rawData()
        } catch {
            LogError(String(format: "JSON object to data by SwiftyJSON failed! \nError: %@\nJSON object: %@",
                            error.localizedDescription,
                            jsonObject as? CVarArg ?? EmptyString))
            return nil
        }
        
        return data
    }
    
    open class func fileSize(_ atPath: String?) -> UInt64 {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: atPath!, isDirectory: &isDirectory) else {
            return 0
        }
        return fileSize(atPath!, isDirectory: isDirectory.boolValue)
    }
    
    class func fileSize(_ atPath: String, isDirectory: Bool) -> UInt64 {
        if !isDirectory {
            let attributes = try! FileManager.default.attributesOfItem(atPath: atPath)
            return attributes[FileAttributeKey.size] as? UInt64 ?? 0
        }
        
        let totalSize = FileManager.default.subpaths(atPath: atPath)?.reduce(0, {
            $0 + fileSize(atPath.appending(pathComponent: $1))
        })
        return totalSize ?? 0
    }
    
    //MARK: - Text Size
    
    open class func fitSize(_ text: String?,
                            font: UIFont,
                            maxWidth: CGFloat? = nil,
                            maxHeight: CGFloat? = nil) -> CGSize {
        return fitSize(text ?? EmptyString,
                       attibutes: [.font : font],
                       options: nil,
                       maxWidth: maxWidth,
                       maxHeight: maxHeight)
    }
    
    //从iOS 10以后，取width和height时需要再加上ceil才准确
    open class func fitSize(_ text: String,
                            attibutes: [NSAttributedStringKey : Any],
                            options: NSStringDrawingOptions? = nil,
                            maxWidth: CGFloat? = nil,
                            maxHeight: CGFloat? = nil) -> CGSize {
        return (text as NSString).boundingRect(with: CGSize(width: maxWidth ?? CGFloat.greatestFiniteMagnitude,
                                                            height: maxHeight ?? CGFloat.greatestFiniteMagnitude),
                                               options: options ?? .calculateTextSize,
                                               attributes: attibutes,
                                               context: nil).size
    }
    
    //MARK: - String
    
    open class func isEmptyString(_ string: Any?) -> Bool {
        guard let string = string as? String else { return true }
        return string.trim.isEmpty
    }
    
    //MARK: - Alert & Toast & Pop view
    
    @discardableResult
    public class func showAlert(title: String? = nil,
                                message: String? = nil,
                                type: AlertType = .info) -> SRAlert? {
        let str1 = NonNull.string(title)
        let str2 = NonNull.string(message)
        if str1 == EmptyString && str2 == EmptyString {
            LogWarn("the parameter 'title' and 'message' of Common.showAlert are all empty")
            return nil
        }
        
        let alert = SRAlert()
        Keyboard.hide {
            alert.show(type, title: str1, message: str2, closeButtonTitle: "OK".localized)
        }
        return alert
    }
    
    @discardableResult
    open class func showToast(_ message: String?,
                              _ inView: UIView = UIApplication.shared.keyWindow!,
                              _ duration: TimeInterval = 2.0) -> Bool {
        guard !isEmptyString(message) else { return false }
        
        var positionInWindow: CGPoint!
        if Keyboard.isVisible {
            let keyboardHeight = Keyboard.keyboardHeight + 5.0
            if keyboardHeight <= ScreenHeight() / 2.0 {
                positionInWindow = CGPoint(x: ScreenWidth() / 2.0, y: ScreenHeight() / 2.0)
            } else {
                positionInWindow = CGPoint(x: ScreenWidth() / 2.0,
                                           y: ScreenHeight() - ToastHeightAboveBottom)
            }
        } else {
            positionInWindow = CGPoint(x: ScreenWidth() / 2.0,
                                       y: ScreenHeight() - ToastHeightAboveBottom)
        }
        inView.makeToast(message!,
                         duration: duration,
                         position: inView.convert(positionInWindow, from: inView.window))
        return true
    }
    
    //MARK: - Lock & unlock on views
    
    /**
     *  将UIView的userInteractionEnabled置为NO一段时间
     *  后面会调用CommonShare的方法将userInteractionEnabled恢复
     *  用于UIViewController.showToast方法中
     *
     *  @param view   view
     */
    open class func unableTimed(_ view: UIView?) {
        unableTimed(view, duration: 1.0)
    }
    
    /**
     *  将UIView的userInteractionEnabled置为NO一段时间，
     *  后面会调用CommonShare的方法将userInteractionEnabled恢复
     *  用于[UIViewController showToast]方法中
     *
     *  @param view   view
     *  @param second second
     */
    open class func unableTimed(_ view: UIView?, duration: TimeInterval) {
        guard let view = view else { return }
        
        view.isUserInteractionEnabled = false
        weak var weakView = view
        Timer.scheduledTimer(timeInterval: duration,
                             target: CommonShare,
                             selector: #selector(CommonInstance.resetViewEnabled(_:)),
                             userInfo: weakView,
                             repeats: false)
    }
    
    /**
     *  使用增加子视图的方式覆盖现有的button
     *
     *  @param button
     */
    open class func unableTimed(button: UIButton?) {
        guard let button = button else { return }
        
        let maskButton = CommonShare.maskButton
        maskButton.frame = button.frame
        button.superview?.addSubview(maskButton)
        weak var weakButton = maskButton
        Timer.scheduledTimer(timeInterval: 1.0,
                             target: CommonShare,
                             selector: #selector(CommonInstance.resetButtonEnabled(_:)),
                             userInfo: weakButton,
                             repeats: false)
    }
    
    //针对按钮点击、多点触摸等做的互斥锁，该方法应该在按钮点击、触摸手势等的响应事件开始调用
    //若返回false，表示当前已有按钮点击、触摸手势等事件生效，应提前结束按钮点击、触摸手势等响应
    //若返回true，则表示已handle了当前时间段的按钮点击、触摸手势等事件响应
    open class func mutexTouch() -> Bool {
        return CommonShare.startTouchHandling()
    }
    
    //MARK: - Navigation Bar Button Item
    
    open class func navigationBarButtonItem(_ setting: [NavigartionBar.ButtonItemKey : Any],
                                            target: Any? = nil,
                                            action: Selector? = nil,
                                            tag: NSInteger? = nil) -> UIBarButtonItem? {
        guard let style = setting[.style] as? NavigartionBar.ButtonItemStyle else {
            return nil
        }
        
        var customView: UIView?
        switch style {
        case .text:
            guard  let title = setting[.title] as? String else {
                break
            }
            
            var width = Common.fitSize(title,
                                       font: UIFont.text,
                                       maxHeight: NavigartionBar.buttonItemHeight).width
            width = min(width, ScreenWidth() / 2.0)
            
            let button = UIButton(frame: CGRect(0, 0, width, NavigartionBar.buttonItemHeight))
            button.title = title
            if let font = setting[.font] as? UIFont {
                button.titleFont = font
            } else {
                button.titleFont = UIFont.text
            }
            if let textColor = setting[.textColor] as? UIColor {
                button.titleColor = textColor
            } else {
                button.titleColor = NavigartionBar.tintColor
            }
            if let target = target, let action = action {
                button.clicked(target, action: action)
            }
            if let tag = tag {
                button.tag = tag
            }
            customView = button
            
        case .image:
            guard let normal = setting[.image] as? UIImage,
                normal.size.width > 0 && normal.size.height > 0 else {
                    break
            }
            
            let height = NavigartionBar.buttonItemHeight
            let button = UIButton(frame: CGRect(0,
                                                0,
                                                height * normal.size.height / normal.size.width,
                                                height))
            button.image = normal
            
            if let highlighted = setting[.highlightedImage] as? UIImage {
                button.setImage(highlighted, for: .highlighted)
            }
            
            if let target = target, let action = action {
                button.clicked(target, action: action)
            }
            if let tag = tag {
                button.tag = tag
            }
            customView = button
            
        case .textAndImage:
            guard let title = setting[.title] as? String,
                let normal = setting[.backgroundImage] as? UIImage,
                normal.size.width > 0 && normal.size.height > 0 else {
                    break
            }
            
            let height = NavigartionBar.buttonItemHeight
            var titleWidth = Common.fitSize(title, font: UIFont.text, maxHeight:height).width
            titleWidth = min(titleWidth, ScreenWidth() / 2.0)
            let imageWidth = height * normal.size.height / normal.size.width
            let width = max(titleWidth, imageWidth)
            
            let button = UIButton(frame: CGRect(0, 0, width, height))
            button.title = title
            if let font = setting[.font] as? UIFont {
                button.titleFont = font
            } else {
                button.titleFont = UIFont.text
            }
            if let textColor = setting[.textColor] as? UIColor {
                button.titleColor = textColor
            } else {
                button.titleColor = NavigartionBar.tintColor
            }
            if let target = target, let action = action {
                button.clicked(target, action: action)
            }
            if let tag = tag {
                button.tag = tag
            }
            button.backgroundImage = normal
            if let highlighted = setting[.highlightedBackgroundImage] as? UIImage {
                button.setBackgroundImage(highlighted, for: .highlighted)
            }
            customView = button
            
        case .custom:
            guard let view = setting[.customView] as? UIView else {
                break
            }
            
            let width = view.width
            let height = view.height
            if width == 0 || height == 0 { break }
            view.frame = CGRect(0,
                                0,
                                NavigartionBar.buttonItemHeight * height / width,
                                NavigartionBar.buttonItemHeight)
            
        default: break
        }
        
        if let customView = customView {
            return UIBarButtonItem(customView: customView)
        }
        
        return nil
    }
    
    //MARK: - ViewController
    
    open class func viewController(_ identifier: String,
                                   storyboard: String,
                                   bundle: Bundle? = nil) -> UIViewController {
        return UIStoryboard(name: storyboard,
                            bundle: bundle ?? Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
    
    open class func frontVC() -> UIViewController? {
        var window = UIApplication.shared.keyWindow
        if window != nil && window!.windowLevel != UIWindowLevelNormal {
            if let normalWindow = UIApplication.shared.windows.first(where: {
                $0.windowLevel == UIWindowLevelNormal
            }) {
                window = normalWindow
            }
        }
        
        if let next = window?.subviews.first?.next as? UIViewController {
            return next
        } else {
            return window?.rootViewController
        }
    }
    
    //MARK: SubmitButton
    
    //获取一个默认格式的提交按钮，类似于登录的大按钮
    open class func submitButton(_ title: String,
                                 normalColor: UIColor? = nil,
                                 highlightedColor: UIColor? = nil) ->UIButton {
        let button = UIButton(type: UIButtonType.custom)
        button.frame = SubmitButton.frame
        button.layer.cornerRadius = SubmitButton.cornerRadius
        button.clipsToBounds = true
        button.titleColor = SubmitButton.titleColor
        button.titleFont = SubmitButton.font
        button.title = title
        if let normalColor = normalColor {
            button.setBackgroundImage(UIImage.rect(normalColor, size: button.bounds.size),
                                      for: .normal)
            if let highlightedColor = highlightedColor {
                button.setBackgroundImage(UIImage.rect(highlightedColor, size: button.bounds.size),
                                          for: .highlighted)
            } else {
                button.setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                                       size: button.bounds.size),
                                          for: .highlighted)
            }
        } else {
            defaultBackgroundColor(submitButton: button)
        }
        return button
    }
    
    //改变提交按钮的样式，如果按钮没有设置BackgroundImage，将提供默认的样式
    //原因是若只设置了按钮的BackgroundColor的话，将没有点击效果的样式
    open class func change(submitButton: UIButton,
                           enabled: Bool,
                           normalColor: UIColor? = nil,
                           highlightedColor: UIColor? = nil) {
        let button = submitButton
        if button.currentBackgroundImage == nil {
            if let normalColor = normalColor {
                button.setBackgroundImage(UIImage.rect(normalColor, size: button.bounds.size),
                                          for: .normal)
                if let highlightedColor = highlightedColor {
                    button.setBackgroundImage(UIImage.rect(highlightedColor,
                                                           size: button.bounds.size),
                                              for: .highlighted)
                } else {
                    button.setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                                           size: button.bounds.size),
                                              for: .highlighted)
                }
            } else {
                defaultBackgroundColor(submitButton: button)
            }
        }
        button.isEnabled = enabled
    }
    
    open class func defaultBackgroundColor(submitButton: UIButton) {
        submitButton.setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorNormal,
                                                     size: submitButton.bounds.size),
                                        for: .normal)
        submitButton.setBackgroundImage(UIImage.rect(SubmitButton.backgroundColorHighlighted,
                                                     size: submitButton.bounds.size),
                                        for: .highlighted)
        submitButton.backgroundColor = UIColor.clear
    }
}
