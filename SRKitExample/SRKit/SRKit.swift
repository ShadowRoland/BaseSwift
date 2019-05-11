//
//  SRKit.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
import KeychainSwift

public class SRKit {
    private static let shared = SRKit()
    private init() {
        LogInfo("\(ScreenScale)")
    }
    
    public static let newActionNotification = Notification.Name(rawValue: "SRKit.newAction")
    public static let didEndStateMachinePageEventNotification = Notification.Name("SRKit.didEndStateMachinePageEvent") //跨页面的通知
}

//MARK: Environment

public var Environment: RunEnvironment = .develop
public enum RunEnvironment {
    case develop,  //开发环境，debug
    test,  //测试环境，release
    production  //生产环境，release
}

public var BaseHttpURL: String = ""

//MARK: - 数据类型定义和声明

public typealias ParamDictionary = [String : Any]
public typealias EnumInt = Int

public typealias ParamEncoding = ParameterEncoding
public typealias ParamHeaders = HTTPHeaders

//MARK: - 文件系统相关

fileprivate var homeDirectory: String!
//资源文件目录
public var HomeDirectory: String {
    if homeDirectory == nil {
        homeDirectory = String(NSHomeDirectory())
    }
    return homeDirectory
}

//默认文档目录
fileprivate var documentsDirectory: String!
public var DocumentsDirectory: String {
    if documentsDirectory == nil {
        documentsDirectory = String(NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                        .userDomainMask,
                                                                        true).first!)
    }
    return documentsDirectory
}

fileprivate var resourceDirectory: String!
public var ResourceDirectory: String {
    if resourceDirectory == nil {
        resourceDirectory = Bundle.main.resourcePath!.appending(pathComponent: "Resource")
    }
    return resourceDirectory
}

//日志文件目录
//let LogfilesDirectory      [kDocumentsDirectory stringByAppendingPathComponent:@"Log"]
//所有用户目录
fileprivate var userDirectory: String!
public var UserDirectory: String {
    get {
        if userDirectory == nil {
            userDirectory = DocumentsDirectory.appending(pathComponent: "User")
        }
        return userDirectory
    }
    set {
        userDirectory = newValue
    }
}

//数据库文件路径
fileprivate var databaseFilePath: String!
public var DatabaseFilePath: String {
    get {
        if databaseFilePath == nil {
            databaseFilePath = DocumentsDirectory.appending(pathComponent: "app.db")
        }
        return databaseFilePath
    }
    set {
        databaseFilePath = newValue
    }
}

//MARK: - 设备与系统信息相关

fileprivate var devieModel: String!
public var DevieModel: String {
    if devieModel == nil {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        devieModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier! + String(UnicodeScalar(UInt8(value)))
        }
    }
    return devieModel
}

fileprivate var deviceId: String!
public var DeviceId: String {
    if deviceId == nil {
        let keychain = KeychainSwift()
        if let string = keychain.get("devieId") {
            deviceId = string
        } else {
            let string = UIDevice.current.identifierForVendor!.uuidString.lowercased()
            deviceId = string.replacingOccurrences(of: "-", with: "")
            keychain.set(deviceId, forKey: "deviceId")
        }
    }
    return deviceId
}

fileprivate var osVersion: String!
public var OSVersion: String {
    if osVersion == nil {
        osVersion = UIDevice.current.systemName + UIDevice.current.systemVersion
    }
    return osVersion
}

fileprivate var appVersion: String!
public var AppVersion: String {
    if appVersion == nil {
        appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    }
    return appVersion
}

public enum ScreenScaleType: Int {
    case none
    case iPad                   //iPad的屏幕
    case iPhone4                //iPhone4，及iPhone4以前手机
    case iPhone5                //iPhone5，5S的屏幕
    case iPhone6                //iPhone6的屏幕
    case iPhone6P               //iPhone6 plus的屏幕
    case iPhoneX                //iPhoneX的屏幕
    case iPhoneXR               //iPhoneX的屏幕
    case iPhoneXMax             //iPhoneX的屏幕
    case unknown
}

fileprivate var screenScale: ScreenScaleType? = nil
public var ScreenScale: ScreenScaleType {
    if screenScale != nil {
        return screenScale!
    }
    
    if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
        screenScale = .iPad
    }
    
    let size: CGSize = UIScreen.main.currentMode!.size
    if size.equalTo(CGSize(width: 640, height: 960)) {
        screenScale = .iPhone4
    } else if size.equalTo(CGSize(width: 640, height: 1136)) {
        screenScale = .iPhone5
    } else if size.equalTo(CGSize(width: 750, height: 1334)) {
        screenScale = .iPhone6
    } else if size.equalTo(CGSize(width: 1242, height: 2208)) {
        screenScale = .iPhone6P
    } else if size.equalTo(CGSize(width: 1125, height: 2436)) {
        screenScale = .iPhoneX
    } else if size.equalTo(CGSize(width: 828, height: 1792)) {
        screenScale = .iPhoneXR
    } else if size.equalTo(CGSize(width: 1242, height: 2688)) {
        screenScale = .iPhoneXMax
    } else {
        screenScale = .unknown
    }
    
    switch screenScale! {
    case .iPhoneX, .iPhoneXR, .iPhoneXMax:
        StatusBarHeight = 44.0
        NavigationHeaderHeight = StatusBarHeight + NavigationBarHeight
        TabBarHeight = 83.0
        SafeInsetTop = 34.0
        SafeInsetBottom = 34.0
    default:
        break
    }
    
    return screenScale!
}

public func screenSize(_ interfaceOrientation: UIInterfaceOrientationMask = .portrait) -> CGSize {
    let size: CGSize = (UIScreen.main.currentMode?.size)!
    if interfaceOrientation == .portrait {
        return size.width < size.height
            ? CGSize(size.width / 2.0, size.height / 2.0)
            : CGSize(size.height / 2.0, size.width / 2.0);
    } else {
        return size.width > size.height
            ? CGSize(size.width / 2.0, size.height / 2.0)
            : CGSize(size.height / 2.0, size.width / 2.0);
    }
}

//MARK: - 应用程序可配置项

//MARK: 屏幕旋转
public var ShouldAutorotate = false
public var SupportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait
public var PreferredInterfaceOrientationForPresentation: UIInterfaceOrientation = .portrait

//MARK: 是否只在WLAN下显示图片
public var isOnlyShowImageInWLAN: Bool {
    get {
        return UserStandard[USKey.isAllowShowImageInWLAN] == nil
    }
    set {
        UserStandard[USKey.isAllowShowImageInWLAN] = true
    }
}

//MARK: 是否允许使用指纹登录，默认允许
public var canAuthenticateToLogin: Bool {
    get {
        return UserStandard[USKey.forbidAuthenticateToLogin] == nil
    }
    set {
        UserStandard[USKey.forbidAuthenticateToLogin] = true
    }
}

//MARK: - 存储在UserDefault中的数据Key

public struct USKey {
    public static let appIsFirstRun                  = "SRKit.USKey.appIsFirstRun"
    public static let baseHttpURL                    = "SRKit.USKey.baseHttpURL"
    public static let currentUserInfo                = "SRKit.USKey.currentUserInfo"
    public static let currentDeviceToken             = "SRKit.USKey.currentDeviceToken"
    public static let currentToken                   = "SRKit.USKey.currentToken"
    public static let currentUserId                  = "SRKit.USKey.currentUserId"
    public static let currentLoginPassword           = "SRKit.USKey.currentLoginPassword"
    public static let dbVersion                      = "SRKit.USKey.dbVersion"
    public static let isFreeInterfaceOrientations    = "SRKit.USKey.isFreeInterfaceOrientations"
    public static let isAllowShowImageInWLAN         = "SRKit.USKey.isAllowShowImageInWLAN"
    public static let forbidAuthenticateToLogin      = "SRKit.USKey.forbidAuthenticateToLogin"
}

//MARK: - 常用的常量值

public var PerformDelay = 0.1 as TimeInterval
public var DelayPerformForOldDevice = 0.5 as TimeInterval
public var ViewControllerTransitionInterval = 0.3 as TimeInterval //视图切换动画
public var ReuseIdentifier = "SRKit.reuseIdentifier"
public var AppCallUrlSchemeKey = "scheme"
//var Description = "description"
public var HtmlTextFormat = "<span style=\"font-family: sans-serif;font-size: 15px;margin: 0;padding: 0\">%@</span>"
public var HtmlTitleFormat = "<p style=\"text-align: center;line-height: 120%%;font-family: sans-serif;font-size: 15px;\">%@</p>"

//MARK: - 本地化语言

public let isZhHans = NSLocale.preferredLanguages.first!.hasPrefix("zh-Hans")

//MARK: - 格式化

public class DateFormat {
    public static var date = date1
    public static var date1 = "yyyy-MM-dd"
    public static var date2 = "yyyy/MM/dd"
    public static var localDate = "[SR]LocalDate".srLocalized
    public static var time = time1
    public static var time1 = "yyyy-MM-dd HH:mm:ss"
    public static var time2 = "yyyy-MM-dd HH:mm:ss.SSS"
    public static var time3 = "yyyy/MM/dd HH:mm:ss"
    public static var time4 = "HH:mm:ss"
    public static var time5 = "HH:mm:ss.SSS"
    public static var full = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
}

//MARK: - 视图相关的常量和工具

public var ScreenWidth: CGFloat { return UIScreen.main.bounds.size.width }
public var ScreenHeight: CGFloat { return UIScreen.main.bounds.size.height }

public extension UIFont {
    static var title = UIFont.medium(18.0)
    static var heavyTitle = UIFont.bold(18.0)
    static var text = UIFont.system(15.0)
    static var detail = UIFont.system(14.0)
    static var tip = UIFont.system(13.0)
}

public extension NSObject.property {
    static let text: NSObject.property = NSObject.property("text")
    static let placeholder: NSObject.property = NSObject.property("placeholder")
    static let font: NSObject.property = NSObject.property("font")
    static let isEnabled: NSObject.property = NSObject.property("isEnabled")
}

public var StatusBarHeight = 20.0 as CGFloat //状态栏默认高度
public var NavigationBarHeight = 44.0 as CGFloat //导航栏默认高度（竖屏）
public var NavigationHeaderHeight = StatusBarHeight + NavigationBarHeight //导航栏上部默认高度（竖屏）
public var TabBarHeight = 49.0 as CGFloat //TabBar默认高度
public var SafeInsetTop = 0 as CGFloat //iPhone X顶部预留的安全间距
public var SafeInsetBottom = 0 as CGFloat //iPhone X底部部预留的安全
public var TabBarImageHeight = 50.0 / 2.0 as CGFloat //TabBar图片的默认高度
public var TableCellHeight = 44.0 as CGFloat //UITableViewCell的默认高度
public var SectionHeaderTopHeight = 20.0 as CGFloat //列表的第一个Section的HeaderView的高度
public var SectionHeaderHeight = 30.0 as CGFloat //列表的非第一个Section的HeaderView的高度
public var SectionHeaderGroupNoHeight = 0.5 as CGFloat //列表Gourp模式下Section的HeaderView最小高度
public var TableCellSeperatorColor = UIColor(white: 215.0) //UITableViewCell分割线的近似颜色
public var ToastHeightAboveBottom = 100.0 as CGFloat //Toast底部栏高度
public var MaskAlpha = 0.7 as CGFloat //默认灰底背景透明度
public var MaskBackgroundColor = UIColor(white: 0.5, alpha: MaskAlpha) //默认灰底背景色
public var LabelHeight = 21.0 as CGFloat //默认的UILabel控件的高度
public var SeperatorLineThickness = 0.5 as CGFloat //分割线粗细
public var SeperatorLineColor = UIColor(197.0, 197.0, 212.0) //分割线颜色
public var SubviewMargin = 15.0 as CGFloat //子视图内的默认外间距，多用于水平方向

//MARK: - 在系统提供的Navigation Bar上做自定义

public class NavigationBar {
    static public var buttonItemHeight = NavigationBarHeight
    static public var titleTextAttributes: [NSAttributedString.Key : Any] =
        [.foregroundColor : UIColor.black, .font : UIFont.title]
    static public var tintColor = UIColor.black
    static public var backgroundColor = UIColor.white
    static  var _backgroundColor: UIColor?
    private static var _backgroundImage: UIImage?
    static var backgroundImage: UIImage {
        if _backgroundImage == nil || _backgroundColor !== backgroundColor {
            _backgroundColor = backgroundColor
            _backgroundImage = UIImage.rect(_backgroundColor!,
                                            size: CGSize(ScreenWidth, NavigationBarHeight))
        }
        return _backgroundImage!
    }
    
    //导航栏在视图控制器中的显示方式，默认为不隐藏导航栏，建议在viewDidLoad中重新设置
    public enum Appear {
        case visible //显示
        case hidden //隐藏
        case custom //自定义显示和隐藏，自行在子类视图的viewWillAppear与viewDidAppear中展示
    }
    
    //按钮样式
    public enum ButtonItemStyle: Int {
        case text                //纯文字
        case image               //纯图片
        //case textAndImage        //文字和图片
        case custom              //自定义
    }
    
    public static let buttonFullSetting: [NavigationBar.ButtonItemKey : Any] =
        [.style : NavigationBar.ButtonItemStyle.text,
         .title: "",
         .font: "",
         .textColor: "",
         .image: "",
         //.highlightedImage: "",
            //.backgroundImage: "",
            //.highlightedBackgroundImage: "",
            .customView: ""]
    
    public struct ButtonItemKey : RawRepresentable, Hashable {
        public typealias RawValue = String
        public var rawValue: String
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static let style = ButtonItemKey("SRKit.style") //用于在Setting中的key，不可为空
        public static let title = ButtonItemKey("SRKit.title") //按钮标题，内容为String类型，在样式为text和textAndImage时有效，不可为空
        public static let font = ButtonItemKey("SRKit.font") //按钮标题字体，内容为UIFont类型，在样式为text和textAndImage时有效，可为空
        public static let textColor = ButtonItemKey("SRKit.textColor") //按钮标题颜色，内容为UIColor类型，在样式为text和textAndImage时有效，可为空
        public static let image = ButtonItemKey("SRKit.normal.image") //按钮图片，内容为UIImage类型, 在样式为image时有效，其中normal不能为空，highlighted可为空
        //static let highlightedImage = ButtonItemKey("highlighted.image")
        //static let backgroundImage = ButtonItemKey("normal.backgroundImage") //按钮背景图片，内容为UIImage类型, 在样式为textAndImage时有效，其中normal不能为空，highlighted可为空
        //static let highlightedBackgroundImage = ButtonItemKey("highlighted.backgroundImage")
        public static let customView = ButtonItemKey("SRKit.customView") //自定义的视图，内容为UIView类型，在样式为custom有效，不可为空
    }
    
    public class func buttonItem(_ setting: [ButtonItemKey : Any],
                                 target: Any? = nil,
                                 action: Selector? = nil,
                                 tag: NSInteger? = nil) -> UIBarButtonItem? {
        var style: ButtonItemStyle = .text
        if let itemStyle = setting[.style] as? ButtonItemStyle {
            style = itemStyle
        }
        
        var item: UIBarButtonItem?
        switch style {
        case .text:
            guard  let title = setting[.title] as? String else {
                return nil
            }
            
            item = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
            var attributes : [NSAttributedString.Key : Any] =
                [.font : UIFont.text, .foregroundColor : tintColor]
            
            if let font = setting[.font] as? UIFont {
                attributes[.font] = font
            }
            if let textColor = setting[.textColor] as? UIColor {
                attributes[.foregroundColor] = textColor
            }
            
            item?.setTitleTextAttributes(attributes, for: .normal)
            
        case .image:
            guard let normal = setting[.image] as? UIImage,
                normal.size.width > 0 && normal.size.height > 0 else {
                    return nil
            }
            
            let item = UIBarButtonItem(image: normal, style: .plain, target: target, action: action)
            if let tag = tag {
                item.tag = tag
            }
            
            return item
            
        case .custom:
            guard let view = setting[.customView] as? UIView else {
                break
            }
            
            let gestureRecognizers = view.gestureRecognizers
            gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
            view.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
            item = UIBarButtonItem(customView: view)
        }
        
        if let tag = tag {
            item?.tag = tag
        }
        
        return item
    }
}

//提交按钮的样式
public class SubmitButton {
    public static var frame                        = CGRect(0,
                                                            0,
                                                            ScreenWidth - SubviewMargin,
                                                            TableCellHeight) //默认尺寸
    public static var cornerRadius                 = 5.0 as CGFloat //圆角
    public static var backgroundColorNormal        = UIColor(0, 191.0, 255.0) //提交按钮正常状态的颜色
    public static var backgroundColorHighlighted   = UIColor(175.0, 238.0, 238.0) //提交按钮高亮状态的颜色
    public static var titleColor                   = UIColor.white
    public static var font                         = UIFont.Preferred.headline
}

public class Param {
    public struct Key {
        //Common
        public static let id = "id"
        public static let status = "status"
        public static let type = "type"
        public static let image = "image"
        public static let img = "img"
        public static let width = "width"
        public static let height = "height"
        public static let video = "video"
        public static let title = "title"
        public static let text = "text"
        public static let alert = "alert"
        public static let url = "url"
        public static let link = "link"
        public static let message = "message"
        public static let description = "description"
        public static let timestamp = "timestamp"
        public static let date = "date"
        public static let version = "version"
        
        //MARK: Device
        public static let os = "os"
        public static let deviceModel = "deviceModel"
        public static let deviceId = "deviceId"
        public static let deviceToken = "deviceToken"
        
        //MARK: Action
        public static let action = "action"
        public static let sender = "sender"
        public static let recipient = "recipient"
        public static let event = "event"
        
        //MARK: Profile
        public static let userId = "userId"
    }
    
    public struct DefaultValue {
        
    }
}

//MARK: - Event
extension SRKit {
    public class Event: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
        public var option: Option
        public var params: ParamDictionary?
        public weak var sender: AnyObject?
        public init(_ option: Option, params: ParamDictionary? = nil, sender: AnyObject? = nil) {
            self.option = option
            self.params = params
            self.sender = sender
        }
        
        public static func == (lhs: Event, rhs: Event) -> Bool {
            return lhs.option == rhs.option
        }
        
        public var description: String {
            return "option: \(option.rawValue), params: \(String(jsonObject: params)), sender: \(String(describing: sender))"
        }
        
        public var debugDescription: String {
            return description
        }
        
        // 根据外部的调用参数（推送，第三方应用，peek & pop）返回的应用内部事件，以及内部定义的d独有事件
        public struct Option : RawRepresentable, Hashable {
            public typealias RawValue = Int
            public var rawValue: Int
            
            public init(_ rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public static func == (lhs: Option, rhs: Option) -> Bool {
                return lhs.rawValue == rhs.rawValue
            }
        }
        
        // 系统应用、第三方应用、推送通知等调用本应用时的操作
        public struct Action : RawRepresentable, Hashable {
            public typealias RawValue = String
            public var rawValue: String
            public var option: Option?
            
            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(_ rawValue: String, option: Option) {
                self.rawValue = rawValue
                self.option = option
            }
            
            public static func ==(lhs: Action, rhs: Action) -> Bool {
                return lhs.rawValue == rhs.rawValue
            }
        }
    }
}
