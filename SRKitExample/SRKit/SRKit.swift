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

//MARK: - 数据类型定义和声明

public typealias AnyArray = Array<Any>
public typealias AnyDictionary = Dictionary<AnyHashable, Any>
public typealias ParamDictionary = [String : Any]
public typealias EnumInt = Int

public typealias ParamEncoding = ParameterEncoding
public typealias ParamHeaders = [String : String]

public let C = Const.self

public var ScreenWidth: CGFloat {
    return C.screenWidth
}

public var ScreenHeight: CGFloat {
    return C.screenHeight
}

public var IsLandscape: Bool {
    return C.isLandscape
}

public class SRKit {
    public static let shared = SRKit()
    public func initialize() { }
    private init() {
        C.initialScreenScale()
    }
    
    public static let newActionNotification = Notification.Name(rawValue: "SRKit.newAction")
    /// 跨页面的通知，通知页面其状态机事件结束
    public static let didEndStateMachinePageEventNotification = Notification.Name("SRKit.didEndStateMachinePageEvent")
    
    /// swizzle
    public class func methodSwizzling(_ ofClass: AnyClass,
                                      originalSelector: Selector,
                                      swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(ofClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(ofClass, swizzledSelector) else {
                return
        }
        
        if class_addMethod(ofClass,
                           originalSelector,
                           method_getImplementation(swizzledMethod),
                           method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(ofClass, swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    /// 主线程保护，建议在DEBUG模式下执行一次，用以定位子线程中调用主线程事件的错误
    public static func mainThreadGuardSwizzle() {
        UIApplication.mainThreadGuardSwizzleMethods()
        UIView.mainThreadGuardSwizzleMethods()
    }
    
}

//MARK: - Event

extension SRKit {
    /// 事件
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
        
        /// 根据外部的调用参数（推送，第三方应用，peek & pop）返回的应用内部事件，以及内部定义的d独有事件
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
        
        /// 系统应用、第三方应用、推送通知等调用本应用时的操作
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

public class Const {
    //    public static let shared = Const()
    //    private init() { }
    
    //MARK: Environment
    
    /// 应用运行的环境
    public static var environment: RunEnvironment = .develop
    public struct RunEnvironment: OptionSet {
        /// Returns the raw bitmask value of the option and satisfies the `RawRepresentable` protocol.
        fileprivate(set) public var rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        /// 开发环境(rawValue: 1 << 0)，默认宏DEBUG生效，自行开发联调用，建议打开所有调试开关
        public static let develop = RunEnvironment(rawValue: 1 << 0)
        
        /// 测试环境(rawValue: 1 << 1)，默认宏RELEASE生效，交付测试用，建议打开部分调试开关
        public static let test = RunEnvironment(rawValue: 1 << 1)
        
        /// 生产环境(rawValue: 1 << 2)，默认宏RELEASE生效，上线生产用，关闭所有调试开关
        public static let production = RunEnvironment(rawValue: 1 << 2)
        
        public static let nonProduction = RunEnvironment(rawValue: ~RunEnvironment.production.rawValue)
    }
    
    /// 发送http请求时默认的http网址，默认为空字符串，需自行调整
    public static var baseHttpURL: String = ""
    
    //MARK: - 文件系统相关
    
    fileprivate static let _homeDirectory: String = String(NSHomeDirectory())
    public static var homeDirectory: String {
        return _homeDirectory
    }
    
    fileprivate static let _documentsDirectory: String = String(NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                                                    .userDomainMask,
                                                                                                    true).first!)
    /// 应用的文档文件夹
    public static var documentsDirectory: String {
        return _documentsDirectory
    }
    
    /// 应用的资源文件文件夹，默认为沙盒下的"Resource"文件夹，可重新调整，新值为绝对路径
    public static var resourceDirectory: String = Bundle.main.resourcePath!.appending(pathComponent: "Resource")
    
    // 日志文件文件夹
    //let LogfilesDirectory      [kDocumentsDirectory stringByAppendingPathComponent:@"Log"]
    
    /// 所有用户文件夹，默认为沙盒下的"User"文件夹，可重新调整，新值为绝对路径
    public static var userDirectory: String = documentsDirectory.appending(pathComponent: "User")
    
    /// 数据库文件，默认为沙盒下的"app.db"文件，可重新调整，新值为绝对路径
    public static var databaseFilePath: String = documentsDirectory.appending(pathComponent: "app.db")
    
    //MARK: - 设备与系统信息相关
    
    fileprivate static let _deviceModel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let deviceModel = Mirror(reflecting: systemInfo.machine).children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return deviceModel
    }()
    public static var deviceModel: String = _deviceModel
    
    fileprivate static var _keyOfDeviceIdInKeyChain = "deviceId"
    fileprivate static var _deviceId: String!
    /// 查询和保存在keyChain中对应的key，默认为"deviceId"
    /// 唯一设备id，先从keychain中查询是否已存在，不存在的话再从identifierForVendor取值（去掉"-"），然后保存在keychain中
    /// 可以实现同一个开发者账号的多个应用之间共用同一个deviceId
    /// 可自行调整，修改后将保存在keychain中
    /// 查询和保存在keyChain中对应的key为KeyOfDeviceIdInKeyChain
    public static var deviceId: String {
        if _deviceId == nil {
            let keychain = KeychainSwift()
            if let string = keychain.get(_keyOfDeviceIdInKeyChain) {
                _deviceId = string
            } else {
                let string = UIDevice.current.identifierForVendor!.uuidString.lowercased()
                _deviceId = string.replacingOccurrences(of: "-", with: "")
                keychain.set(_deviceId, forKey: _keyOfDeviceIdInKeyChain)
            }
        }
        return _deviceId
    }
    
    public static func setDeviceId(_ deviceId: String, key inKeyChain: String = "deviceId") {
        _deviceId = deviceId
        _keyOfDeviceIdInKeyChain = inKeyChain
        KeychainSwift().set(deviceId, forKey: _keyOfDeviceIdInKeyChain)
    }
    
    public static func setKeyOfDeviceIdInKeyChain(_ key: String) {
        _keyOfDeviceIdInKeyChain = key
        let keychain = KeychainSwift()
        if let string = keychain.get(_keyOfDeviceIdInKeyChain) {
            _deviceId = string
        }
        if let deviceId = _deviceId {
            KeychainSwift().set(deviceId, forKey: _keyOfDeviceIdInKeyChain)
        }
    }
    
    /// 操作系统的版本
    public static let osVersion: String = UIDevice.current.systemName + UIDevice.current.systemVersion
    
    /// 应用的版本
    public static let appVersion: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
    
    /// 设备的屏幕类型
    public enum ScreenScaleType: Int {
        case unknown
        case iPad
        case iTV
        case iCar
        /// iPhone4，及iPhone4以前手机
        case iPhone4
        /// iPhone5，5S的屏幕
        case iPhone5
        /// iPhone6的屏幕
        case iPhone6
        /// iPhone6 plus的屏幕
        case iPhone6P
        /// iPhoneX的屏幕
        case iPhoneX
        /// iPhoneX的屏幕
        case iPhoneXR
        /// iPhoneX的屏幕
        case iPhoneXMax
        case iPhoneUnknown
    }
    
    fileprivate static var _screenScale: ScreenScaleType? = nil
    /// 获取设备的屏幕类型
    public static var screenScale: ScreenScaleType {
        initialScreenScale()
        return _screenScale!
    }
    
    fileprivate static func initialScreenScale() {
        if _screenScale != nil {
            return
        }
        
        if #available(iOS 11.0, *),
            let insets = UIApplication.shared.windows.first?.safeAreaInsets,
            insets != .zero {
            _safeInsetBottom = 34.0
            _safeInsetBottomLandscape = 21.0
        }
        
        let idiom = UI_USER_INTERFACE_IDIOM()
        let size: CGSize = UIScreen.main.currentMode!.size
        let isFullScreen = _safeInsetBottom > 0
        switch idiom {
        case .phone:
            if size.equalTo(CGSize(width: 640, height: 960)) {
                _screenScale = .iPhone4
                _navigationBarHeightLandscape = 32.0
            } else if size.equalTo(CGSize(width: 640, height: 1136)) {
                _screenScale = .iPhone5
                _navigationBarHeightLandscape = 32.0
            } else if size.equalTo(CGSize(width: 750, height: 1334)) {
                _screenScale = .iPhone6
            } else if size.equalTo(CGSize(width: 1242, height: 2208)) {
                _screenScale = .iPhone6P
            } else if size.equalTo(CGSize(width: 1125, height: 2436)) && isFullScreen {
                _screenScale = .iPhoneX
                _statusBarHeight = 44.0
                _statusBarHeightNotPortrait = 20.0
            } else if size.equalTo(CGSize(width: 828, height: 1792)) && isFullScreen {
                _screenScale = .iPhoneXR
                _statusBarHeight = 44.0
                _statusBarHeightNotPortrait = 20.0
            } else if size.equalTo(CGSize(width: 1242, height: 2688)) && isFullScreen {
                _screenScale = .iPhoneXMax
                _statusBarHeight = 44.0
                _statusBarHeightNotPortrait = 20.0
            } else {
                _screenScale = .iPhoneUnknown
                if isFullScreen {
                    _statusBarHeight = 44.0
                    _statusBarHeightNotPortrait = 0
                }
            }
            
        case .pad:
            _screenScale = .iPad
            
        case .tv:
            _screenScale = .iTV
            
        case .carPlay:
            _screenScale = .iCar
            
        default:
            _screenScale = .unknown
        }
    }
    
    /// 获取设备的屏幕尺寸，默认获取竖屏的屏幕尺寸
    public static func screenSize(_ isLandscape: Bool = false) -> CGSize {
        let size: CGSize = (UIScreen.main.currentMode?.size)!
        if !isLandscape {
            return size.width < size.height
                ? CGSize(size.width / 2.0, size.height / 2.0)
                : CGSize(size.height / 2.0, size.width / 2.0);
        } else {
            return size.width > size.height
                ? CGSize(size.width / 2.0, size.height / 2.0)
                : CGSize(size.height / 2.0, size.width / 2.0);
        }
    }
    
    //MARK: - 视图相关的常量和工具
    
    /// 实时获取屏幕宽度
    public static var screenWidth: CGFloat { return UIScreen.main.bounds.size.width }
    /// 实时获取屏幕高度
    public static var screenHeight: CGFloat { return UIScreen.main.bounds.size.height }
    /// 实时获取当前屏幕方向
    public static var screenOrientation: UIInterfaceOrientation { return UIApplication.shared.statusBarOrientation }
    public static var isLandscape: Bool { return UIApplication.shared.statusBarOrientation.isLandscape }
    
    /// 状态栏高度
    fileprivate static var _statusBarHeight = 20.0 as CGFloat
    fileprivate static var _statusBarHeightNotPortrait = 20.0 as CGFloat
    public static func statusBarHeight(_ isPortrait: Bool = true) -> CGFloat {
        return isPortrait ? _statusBarHeight : _statusBarHeightNotPortrait
    }
    
    /// 导航栏高度（竖屏）
    fileprivate static var _navigationBarHeight = 44.0 as CGFloat
    fileprivate static var _navigationBarHeightLandscape = 44.0 as CGFloat
    public static func navigationBarHeight(_ isLandscape: Bool = false,
                                           type navigationBarType: UIViewController.NavigationBarType = .system) -> CGFloat {
        if navigationBarType == .system {
            return isLandscape ? _navigationBarHeightLandscape : _navigationBarHeight
        } else if navigationBarType == .sr {
            return SRNavigationBar.height
        } else {
            return 44.0
        }
    }
    
    /// 导航栏上部默认高度（竖屏）, 返回statusBarHeight + navigationBarHeight
    public static func NavigationHeaderHeight(_ isLandscape: Bool = false,
                                              type navigationBarType: UIViewController.NavigationBarType = .system) -> CGFloat {
        return statusBarHeight(isLandscape) + navigationBarHeight(isLandscape, type: navigationBarType)
    }
    
    /// TabBar默认高度, 默认为49.0
    fileprivate static var _tabBarHeight = 49.0 as CGFloat
    fileprivate static var _tabBarHeightLandscape = 49.0 as CGFloat
    public static func tabBarHeight(_ isLandscape: Bool = false) -> CGFloat {
        return isLandscape ? _tabBarHeightLandscape : _tabBarHeight
    }
    
    //    /// 全面屏机型顶部预留的安全间距, 默认为0，也可通过该值是否为0来判断是否为全面屏
    //    fileprivate var _safeInsetTop = 0 as CGFloat
    //    fileprivate var _safeInsetTopLandscape = 0 as CGFloat
    //    public func safeInsetTop(_ orientation: UIInterfaceOrientation = .portrait) -> CGFloat {
    //        return orientation.isPortrait ? _safeInsetTop : _safeInsetTopLandscape
    //    }
    
    /// 全面屏底部机型部预留的安全,  默认为0，也可通过该值是否为0来判断是否为全面屏
    fileprivate static var _safeInsetBottom = 0 as CGFloat
    fileprivate static var _safeInsetBottomLandscape = 0 as CGFloat
    public static func safeInsetBottom(_ isLandscape: Bool = false) -> CGFloat {
        return isLandscape ? _safeInsetBottomLandscape : _safeInsetBottom
    }
    
    /// TabBar图片的默认高度, 默认为50.0 / 2.0
    public static var tabBarImageHeight = 50.0 / 2.0 as CGFloat
    /// UITableViewCell的默认高度, 默认为0，44.0，可自行调整
    public static var tableCellHeight = 44.0 as CGFloat
    /// UITableView或UICollectionView等列表控件的第一个Section的HeaderView的高度, 默认为20.0，可自行调整
    public static var sectionHeaderTopHeight = 20.0 as CGFloat
    /// UITableView或UICollectionView等列表控件的非第一个Section的HeaderView的高度, 默认为30.0，可自行调整
    public static var sectionHeaderHeight = 30.0 as CGFloat
    /// UITableView控件在Gourp模式下Section的HeaderView最小高度, 默认为0.5，可自行调整
    public static var sectionHeaderGroupNoHeight = 0.5 as CGFloat
    /// UITableViewCell等控件分割线的近似颜色, 默认为UIColor(white: 215.0)，可自行调整
    public static var tableCellSeperatorColor = UIColor(white: 215.0)
    /// Toast距离底部的高度, 默认为100.0，可自行调整
    public static var toastHeightAboveBottom = 100.0 as CGFloat
    /// 默认灰底背景透明度, 默认为0.7
    public static var maskAlpha = 0.7 as CGFloat
    /// 默认灰底背景色, 默认为UIColor(white: 0.5, alpha: MaskAlpha)，可自行调整
    public static var maskBackgroundColor = UIColor(white: 0.5, alpha: 0.7)
    /// 默认的UILabel控件的高度, 默认为21.0，可自行调整
    public static var labelHeight = 21.0 as CGFloat
    /// 分割线粗细, 默认为0.5，可自行调整
    public static var seperatorLineThickness = 0.5 as CGFloat
    /// 分割线颜色, 默认为UIColor(197.0, 197.0, 212.0)，可自行调整
    public static var seperatorLineColor = UIColor(197.0, 197.0, 212.0)
    /// 子视图内的默认外间距，多用于水平方向, 默认为15.0，可自行调整
    public static var subviewMargin = 15.0 as CGFloat
    //MARK: - 应用程序可配置项
    
    //MARK: 屏幕旋转
    /// 屏幕是否可旋转，默认为false，修改此项的值会影响SRViewController及子类的默认是否可旋转
    public static var shouldAutorotate = false
    /// 屏幕的支持方向，默认为仅竖屏，修改此项的值会影响SRViewController及子类的屏幕的支持方向
    public static var supportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait
    /// 屏幕的初始方向，默认为仅竖屏，修改此项的值会影响SRViewController及子类的屏幕的初始方向
    public static var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation = .portrait
    
    //MARK: - 常用的常量值
    
    /// 一般设备延迟操作的时间量，默认为0.1，可自行调整
    public static var performDelay = 0.1 as TimeInterval
    /// 相对旧设备的延迟操作的时间量，默认为0.5，可自行调整
    public static var delayPerformForOldDevice = 0.5 as TimeInterval
    /// 页面切换的大约动画时间，默认为0.3，可自行调整
    public static var viewControllerTransitionInterval = 0.3 as TimeInterval
    /// 可复用identifier，默认为"reuseIdentifier"，可自行调整
    public static var reuseIdentifier = "reuseIdentifier"
    /// 同一台设备调用其他应用或其他应用调用本应用scheme对应的key，默认为"scheme"，可自行调整
    public static var appCallUrlSchemeKey = "scheme"
    /// 使用html描述普通文本，可自行调整
    /// 默认值为"<span style=\"font-family: sans-serif;font-size: 15px;margin: 0;padding: 0\">%@</span>"
    public static var htmlTextFormat = "<span style=\"font-family: sans-serif;font-size: 15px;margin: 0;padding: 0\">%@</span>"
    /// 使用html描述普通标题，可自行调整
    /// "<p style=\"text-align: center;line-height: 120%%;font-family: sans-serif;font-size: 15px;\">%@</p>"
    public static var htmlTitleFormat = "<p style=\"text-align: center;line-height: 120%%;font-family: sans-serif;font-size: 15px;\">%@</p>"
    
    //MARK: - 本地化语言
    
    /// 当前预览的首选项是否为汉字
    public static let isZhHans = NSLocale.preferredLanguages.first!.hasPrefix("zh-Hans")
    
    //MARK: - 格式化
    
    /// 日期格式
    public struct DateFormat {
        /// 与date1相同，可自行调整
        public static var date = date1
        /// yyyy-MM-dd，可自行调整
        public static var date1 = "yyyy-MM-dd"
        /// yyyy/MM/dd，可自行调整
        public static var date2 = "yyyy/MM/dd"
        /// 在Localizable.strings中指定"[SR]LocalDate"对应的文本内容
        public static var localDate = "[SR]LocalDate".srLocalized
        /// 与time1相同，可自行调整
        public static var time = time1
        /// yyyy-MM-dd HH:mm:ss，可自行调整
        public static var time1 = "yyyy-MM-dd HH:mm:ss"
        /// yyyy-MM-dd HH:mm:ss.SSS，可自行调整
        public static var time2 = "yyyy-MM-dd HH:mm:ss.SSS"
        /// yyyy/MM/dd HH:mm:ss，可自行调整
        public static var time3 = "yyyy/MM/dd HH:mm:ss"
        /// HH:mm:ss，可自行调整
        public static var time4 = "HH:mm:ss"
        /// HH:mm:ss.SSS，可自行调整
        public static var time5 = "HH:mm:ss.SSS"
        /// yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ，可自行调整
        public static var full = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
    }
    
    /// 常用字体
    public struct Font {
        /// 一般标题的字体，默认为.medium(18.0)，可自行调整
        public static var title: UIFont = .medium(18.0)
        /// 一般粗体标题的字体，默认为.bold(18.0)，可自行调整
        public static var heavyTitle: UIFont = .bold(18.0)
        /// 一般文字的字体，默认为.system(15.0)，可自行调整
        public static var text: UIFont = .system(15.0)
        /// 一般细节文字的字体，默认为.system(14.0)，可自行调整
        public static var detail: UIFont = .system(14.0)
        /// 一般提示文字的字体，默认为.system(13.0)，可自行调整
        public static var tip: UIFont = .system(13.0)
    }
}

//MARK: - 导航栏
/// 导航栏的相关设定
public class NavigationBar {
    /// 导航栏上按钮的高度，默认为44.0，可自行调整
    public static var buttonItemHeight = C.navigationBarHeight()
    /// 导航栏上标题文字的属性，可自行调整
    public static var titleTextAttributes: [NSAttributedString.Key : Any] =
        [.foregroundColor : UIColor.black, .font : Const.Font.title]
    /// tintColor，可自行调整
    public static var tintColor: UIColor = .black
    fileprivate static var _backgroundColor: UIColor?
    fileprivate static var _backgroundColorLandscape: UIColor?
    /// backgroundColor，可自行调整
    public static var backgroundColor: UIColor = .white
    fileprivate static var _backgroundImage: UIImage?
    public static var backgroundImage: UIImage {
        if _backgroundImage == nil || _backgroundColor !== backgroundColor {
            _backgroundColor = backgroundColor
            _backgroundImage =
                UIImage.rect(_backgroundColor!,
                             size: CGSize(Const.screenSize().width, Const.navigationBarHeight()))
        }
        return _backgroundImage!
    }
    fileprivate static var _backgroundImageLandscape: UIImage?
    public static var backgroundImageLandscape: UIImage {
        if _backgroundImageLandscape == nil || _backgroundColorLandscape !== backgroundColor {
            _backgroundColorLandscape = backgroundColor
            _backgroundImageLandscape =
                UIImage.rect(_backgroundColorLandscape!,
                             size: CGSize(Const.screenSize(true).width, Const.navigationBarHeight()))
        }
        return _backgroundImageLandscape!
    }
    
    /// 导航栏在视图控制器中的显示方式，默认为不隐藏导航栏，建议在viewDidLoad中重新设置
    public enum Appear {
        /// 显示
        case visible
        /// 隐藏
        case hidden
        /// 自定义显示和隐藏，设定此项后，若使用了系统的导航栏，SRViewController不再于viewWillAppear和viewDidAppear显示和隐藏导航栏
        /// 自行在SRViewController的子类的viewWillAppear与viewDidAppear中执行
        /// navigationBarAppear = .visible或
        /// navigationBarAppear = .hidden或
        case custom
    }
    
    /// 导航栏上按钮的样式设定
    public enum ButtonItemOption {
        /// 纯文字
        case text([Text])
        /// 纯图片
        case image(UIImage)
        //文字和图片
        //case textAndImage
        /// 自定义视图
        case custom(UIView)
        /// 空白间距
        case space(CGFloat)
        
        public enum Text {
            case title(String)
            case font(UIFont)
            case textColor(UIColor)
            /// 只在navigationType为.sr时有效
            case attributedText(NSAttributedString)
        }
    }
    
    /// 返回一个导航栏上的UIBarButtonItem按钮控件
    /// useCustomView为true时，某些情况下将先生成button，然后通过UIBarButtonItem(customView: button)的方式生成UIBarButtonItem
    public class func buttonItem(_ option: ButtonItemOption,
                                 target: Any? = nil,
                                 action: Selector? = nil,
                                 tag: NSInteger? = nil,
                                 useCustomView: Bool = false) -> UIBarButtonItem? {
        var item: UIBarButtonItem?
        switch option {
        case .text(let array):
            var title: String?
            var font: UIFont?
            var textColor: UIColor?
            var attributedText: NSAttributedString?
            for text in array {
                switch text {
                case .title(let s):
                    title = s
                    
                case .font(let f):
                    font = f
                    
                case .textColor(let t):
                    textColor = t
                    
                case .attributedText(let a):
                    attributedText = a
                }
            }
            if !useCustomView, let title = title {
                item = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
                var attributes : [NSAttributedString.Key : Any] =
                    [.font : Const.Font.text, .foregroundColor : tintColor]
                
                if let font = font {
                    attributes[.font] = font
                }
                
                if let textColor = textColor {
                    attributes[.foregroundColor] = textColor
                }
                
                item?.setTitleTextAttributes(attributes, for: .normal)
            } else {
                let button = UIButton(type: .custom)
                if let attributedText = attributedText {
                    if let font = font {
                        button.titleLabel?.font = font
                    } else {
                        button.titleLabel?.font = Const.Font.text
                    }
                    
                    if let textColor = textColor {
                        button.setTitleColor(textColor, for: .normal)
                    } else {
                        button.setTitleColor(tintColor, for: .normal)
                    }
                    
                    button.titleLabel?.attributedText = attributedText
                } else if let title = title {
                    if let font = font {
                        button.titleLabel?.font = font
                    } else {
                        button.titleLabel?.font = Const.Font.text
                    }
                    
                    if let textColor = textColor {
                        button.setTitleColor(textColor, for: .normal)
                    } else {
                        button.setTitleColor(tintColor, for: .normal)
                    }
                    
                    button.setTitle(title, for: .normal)
                }
                
                if let action = action {
                    button.clicked(target, action: action)
                }
                item = UIBarButtonItem(customView: button)
            }
            
        case .image(let image):
            guard image.size.width > 0 && image.size.height > 0 else {
                break
            }
            
            if !useCustomView {
                item = UIBarButtonItem(image: image, style: .plain, target: target, action: action)
            } else {
                let button = UIButton(type: .custom)
                button.setImage(image, for: .normal)
                if let action = action {
                    button.clicked(target, action: action)
                }
                item = UIBarButtonItem(customView: button)
            }
            
        case .custom(let view):
            item = UIBarButtonItem(customView: view)
            
        case .space(let width):
            if !useCustomView {
                item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                item?.width = width
            } else {
                item = UIBarButtonItem(customView: UIView(frame: CGRect(0, 0, width, 0)))
            }
        }
        
        if let tag = tag {
            item?.tag = tag
        }
        
        return item
    }
}

//MARK: -

/// 提交大按钮的样式，一般位于页面底部
public class SubmitButton {
    /// 默认尺寸为CGRect(0, 0, ScreenWidth - C.subviewMargin, C.tableCellHeight)，可自行调整
    public static var frame = CGRect(0,
                                     0,
                                     ScreenWidth - C.subviewMargin,
                                     C.tableCellHeight)
    /// 圆角，默认为5.0，可自行调整
    public static var cornerRadius: CGFloat = 5.0
    /// 提交按钮正常状态的颜色，默认为UIColor(0, 191.0, 255.0)，可自行调整
    public static var backgroundColorNormal = UIColor(0, 191.0, 255.0)
    /// 提交按钮高亮状态的颜色，默认为UIColor(175.0, 238.0, 238.0)，可自行调整
    public static var backgroundColorHighlighted = UIColor(175.0, 238.0, 238.0)
    /// 标题字体颜色，默认为.white，可自行调整
    public static var titleColor: UIColor = .white
    /// 标题字体，默认为UIFont.preferred.headline，可自行调整
    public static var font = UIFont.preferred.headline
}

//MARK: -

/// 参数
public struct Param {
    /// 将常用的参数名常量化，可通过Extension的方式增加常量参数名
    public struct Key {
        //MARK: Common
        /// "id"
        public static let id = "id"
        /// "status"
        public static let status = "status"
        /// "type"
        public static let type = "type"
        /// "image"
        public static let image = "image"
        /// "width"
        public static let width = "width"
        /// "height"
        public static let height = "height"
        /// "video"
        public static let video = "video"
        /// "title"
        public static let title = "title"
        /// "text"
        public static let text = "text"
        /// "alert"
        public static let alert = "alert"
        /// "url"
        public static let url = "url"
        /// "link"
        public static let link = "link"
        /// "message"
        public static let message = "message"
        /// "description"
        public static let description = "description"
        /// "timestamp"
        public static let timestamp = "timestamp"
        /// "date"
        public static let date = "date"
        /// "version"
        public static let version = "version"
        
        //MARK: Device
        /// "os"
        public static let os = "os"
        /// "deviceModel"
        public static let deviceModel = "deviceModel"
        /// "deviceId"
        public static let deviceId = "deviceId"
        /// "deviceToken"
        public static let deviceToken = "deviceToken"
        
        //MARK: Action
        /// "action"
        public static let action = "action"
        /// "sender"
        public static let sender = "sender"
        /// "event"
        public static let event = "event"
    }
    
    /// 将常用的默认参数值常量化，可通过Extension的方式增加常量参数值
    public struct DefaultValue {
        
    }
}

//MARK: -

/// 存储在UserDefault中的参数名，可通过Extension的方式增加常量参数名
public struct UDKey {
    
}

/// NSObject属性，常用控件属性的读取和替换
public extension NSObject.property {
    /// NSObject.property("text")
    static let text: NSObject.property = NSObject.property("text")
    /// NSObject.property("placeholder")
    static let placeholder: NSObject.property = NSObject.property("placeholder")
    /// NSObject.property("font")
    static let font: NSObject.property = NSObject.property("font")
    /// NSObject.property("isEnabled")
    static let isEnabled: NSObject.property = NSObject.property("isEnabled")
}
