//
//  BaseConfig.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit
import CocoaLumberjack

#if RUN_PRODUCTION
let RunInEnvironment: RunEnvironment = .production
#else
#if DEBUG
let RunInEnvironment: RunEnvironment = .develop
#else
let RunInEnvironment: RunEnvironment = .test
#endif
#endif

public enum RunEnvironment {
    case develop,  //开发环境，debug
    test,  //测试环境，release
    production  //生产环境，release
}

//MARK: - 数据类型定义和声明

public typealias ParamDictionary = [String : Any]
public func EmptyParams() -> ParamDictionary { return [:] as ParamDictionary }
public typealias EnumInt = Int

//MARK: - 文件系统相关

//资源文件目录
let HomeDirectory = String(NSHomeDirectory())
let ResourceDirectory = Bundle.main.resourcePath!.appending(pathComponent: "Resource")
//默认文档目录
let DocumentsDirectory =
    String(NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                               .userDomainMask,
                                               true).first!)

//日志文件目录
//let LogfilesDirectory      [kDocumentsDirectory stringByAppendingPathComponent:@"Log"]
//所有用户目录
let UserDirectory = DocumentsDirectory.appending(pathComponent: "User")

//数据库文件路径
let DatabaseFilePath = DocumentsDirectory.appending(pathComponent: "app.db")

//MARK: - 系统信息相关
let OSVersion = UIDevice.current.systemName + UIDevice.current.systemVersion
let DevieModel = Common.devieModel()
let AppVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

public enum ScreenScale: Int {
    case none
    case iPad                   //iPad的屏幕
    case iPhone4                //iPhone4，及iPhone4以前手机
    case iPhone5                //iPhone5，5S的屏幕
    case iPhone6                //iPhone6的屏幕
    case iPhone6P               //iPhone6 plus的屏幕
    case iPhoneX                //iPhoneX的屏幕
    case unknown
}

//MARK: - 应用程序可配置项

//MARK: 屏幕旋转
var ShouldAutorotate = false
var SupportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait
var PreferredInterfaceOrientationForPresentation: UIInterfaceOrientation = .portrait

//MARK: 是否只在WLAN下显示图片
var isOnlyShowImageInWLAN = UserStandard[USKey.isAllowShowImageInWLAN] == nil

//MARK: 是否允许使用指纹登录，默认允许
var canAuthenticateToLogin = UserStandard[USKey.forbidAuthenticateToLogin] == nil

//MARK: - 存储在UserDefault中的数据Key

public struct USKey {
    static let appIsFirstRun                  = "AppIsFirstRun"
    static let baseServerURL                  = "BaseServerURL"
    static let currentUserInfo                = "CurrentUserInfo"
    static let currentDeviceToken             = "currentDeviceToken"
    static let currentToken                   = "CurrentToken"
    static let currentUserId                  = "CurrentUserId"
    static let currentLoginPassword           = "CurrentLoginPassword"
    static let dbVersion                      = "DBVersion"
    static let isFreeInterfaceOrientations    = "isFreeInterfaceOrientations"
    static let isAllowShowImageInWLAN         = "isAllowShowImageInWLAN"
    static let forbidAuthenticateToLogin      = "forbidAuthenticateToLogin"
}

//自定义的通知名
extension Notification.Name {
    public struct Base {
        static let newAction = Notification.Name("Base.newAction")
        static let didEndStateMachineEvent = Notification.Name("Base.didEndStateMachineEvent") //FIXME: FOR DEBUG，跨页面的通知
    }
}

//MARK: - 常用的常量值

let EmptyString = "" //空字符串
var PerformDelay = 0.1 as TimeInterval
var DelayPerformForOldDevice = 0.5 as TimeInterval
var ViewControllerTransitionInterval = 0.3 as TimeInterval //视图切换动画
var ReuseIdentifier = "reuseIdentifier"
var AppCallUrlSchemeKey = "scheme"
//var Description = "description"
var HtmlTextFormat = "<span style=\"font-family: sans-serif;font-size: 15px;margin: 0;padding: 0\">%@</span>"
var HtmlTitleFormat = "<p style=\"text-align: center;line-height: 120%%;font-family: sans-serif;font-size: 15px;\">%@</p>"

//MARK: - 日志
/* 在笔者所使用的版本中，swift下的DDLogxxx()函数不会主动打印控制台信息，所以特意自己添加了打印信息print语句
 * 打印信息print语句前面添加的宏标记在swift中需要自己添加，操作是
 * TARGET -> Build Setting -> Other Swift Flags的Debug状态加一个 -D DEBUG
 * 若后续更新的DDLogxxx()函数支持打印控制台信息，请删除自己添加的打印信息print语句
 */

public func LogDebug(_ message: @autoclosure () -> String) {
    DDLogDebug(message())
    #if DEBUG
    //print(String(date: Date()) + " " + message())
    #endif
}

public func LogInfo(_ message: @autoclosure () -> String) {
    DDLogInfo(message())
    #if DEBUG
    //print(String(date: Date()) + " " + message())
    #endif
}

public func LogWarn(_ message: @autoclosure () -> String) {
    DDLogWarn(message())
    #if DEBUG
    //print(String(date: Date()) + " " + message())
    #endif
}

public func LogError(_ message: @autoclosure () -> String) {
    DDLogError(message())
    #if DEBUG
    //print(String(date: Date()) + " " + message())
    #endif
}

//MARK: - 本地化语言

let isZhHans = NSLocale.preferredLanguages[0].hasPrefix("zh-Hans")

//MARK: - 格式化

public class DateFormat {
    static let date = date1
    static let date1 = "yyyy-MM-dd"
    static let date2 = "yyyy/MM/dd"
    static let localDate = "LocalDate".localized
    static let time = time1
    static let time1 = "yyyy-MM-dd HH:mm:ss"
    static let time2 = "yyyy-MM-dd HH:mm:ss.SSS"
    static let time3 = "yyyy/MM/dd HH:mm:ss"
    static let time4 = "HH:mm:ss"
    static let time5 = "HH:mm:ss.SSS"
    static let full = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
}

//MARK: - 视图相关的常量和工具

func ScreenWidth() -> CGFloat { return UIScreen.main.bounds.size.width }
func ScreenHeight() -> CGFloat { return UIScreen.main.bounds.size.height }

extension UIFont {
    static let title = UIFont.systemFont(ofSize: 18.0)
    
    static let heavyTitle = UIFont.boldSystemFont(ofSize: 18.0)
    
    static let text = UIFont.systemFont(ofSize: 15.0)
    
    static let detail = UIFont.systemFont(ofSize: 14.0)
    
    static let tip = UIFont.systemFont(ofSize: 13.0)
}

extension ObjectProperty {
    static var text: NSObject.property { return NSObject.property("text") }
    static var placeholder: NSObject.property { return NSObject.property("placeholder") }
    static var font: NSObject.property { return NSObject.property("font") }
    static var isEnabled: NSObject.property { return NSObject.property("isEnabled")}
}

var StatusBarHeight = 20.0 as CGFloat //状态栏默认高度
var NavigationBarHeight = 44.0 as CGFloat //导航栏默认高度（竖屏）
var NavigationHeaderHeight = StatusBarHeight + NavigationBarHeight //导航栏上部默认高度（竖屏）
var TabBarHeight = 49.0 as CGFloat //TabBar默认高度
var SafeInsetTop = 0 as CGFloat //iPhone X顶部预留的安全间距
var SafeInsetBottom = 0 as CGFloat //iPhone X底部部预留的安全
var TabBarImageHeight = 50.0 / 2.0 as CGFloat //TabBar图片的默认高度
var TableCellHeight = 44.0 as CGFloat //UITableViewCell的默认高度
var SectionHeaderTopHeight = 20.0 as CGFloat //列表的第一个Section的HeaderView的高度
var SectionHeaderHeight = 30.0 as CGFloat //列表的非第一个Section的HeaderView的高度
var SectionHeaderGroupNoHeight = 0.5 as CGFloat //列表Gourp模式下Section的HeaderView最小高度
var TableCellSeperatorColor = UIColor(white: 215.0) //UITableViewCell分割线的近似颜色
var ToastHeightAboveBottom = 100.0 as CGFloat //Toast底部栏高度
var MaskAlpha = 0.7 as CGFloat //默认灰底背景透明度
var MaskBackgroundColor = UIColor(white: 0.5, alpha: MaskAlpha) //默认灰底背景色
var LabelHeight = 21.0 as CGFloat //默认的UILabel控件的高度
var SeperatorLineThickness = 0.5 as CGFloat //分割线粗细
var SeperatorLineColor = UIColor(197.0, 197.0, 212.0) //分割线颜色
var SubviewMargin = 15.0 as CGFloat //子视图内的默认外间距，多用于水平方向

//MARK: - 在系统提供的Navigation Bar上做自定义

public class NavigartionBar {
    static var buttonItemHeight = NavigationBarHeight
    static var backgroundBlurAlpha = 0.2 as CGFloat
    static var tintColor = UIColor.white
    static var backgroundColor = UIColor(red: 255.0 / 255.0,
                                         green: 127.0 / 255.0,
                                         blue: 0 / 255.0,
                                         alpha: 1.0)
    
    //导航栏在视图控制器中的显示方式，默认为不隐藏导航栏，建议在viewDidLoad中重新设置
    public enum Appear {
        case visible //显示
        case hidden //隐藏
        case custom //自定义显示和隐藏，自行在子类视图的viewWillAppear与viewDidAppear中展示
    }
    
    //按钮样式
    public enum ButtonItemStyle: Int {
        case none
        case text                //纯文字
        case image               //纯图片
        //case textAndImage        //文字和图片
        case custom              //自定义
    }
    
    static let buttonFullSetting: [NavigartionBar.ButtonItemKey : Any] =
        [.style : NavigartionBar.ButtonItemStyle.none,
         .title: EmptyString,
         .font: EmptyString,
         .textColor: EmptyString,
         .image: EmptyString,
         //.highlightedImage: EmptyString,
         //.backgroundImage: EmptyString,
         //.highlightedBackgroundImage: EmptyString,
         .customView: EmptyString]
    
    public struct ButtonItemKey : RawRepresentable, Equatable, Hashable {
        public typealias RawValue = String
        public var rawValue: String
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var hashValue: Int { return self.rawValue.hashValue }
        
        static let style = ButtonItemKey("style") //用于在Setting中的key，不可为空
        static let title = ButtonItemKey("title") //按钮标题，内容为String类型，在样式为text和textAndImage时有效，不可为空
        static let font = ButtonItemKey("font") //按钮标题字体，内容为UIFont类型，在样式为text和textAndImage时有效，可为空
        static let textColor = ButtonItemKey("textColor") //按钮标题颜色，内容为UIColor类型，在样式为text和textAndImage时有效，可为空
        static let image = ButtonItemKey("normal.image") //按钮图片，内容为UIImage类型, 在样式为image时有效，其中normal不能为空，highlighted可为空
        //static let highlightedImage = ButtonItemKey("highlighted.image")
        //static let backgroundImage = ButtonItemKey("normal.backgroundImage") //按钮背景图片，内容为UIImage类型, 在样式为textAndImage时有效，其中normal不能为空，highlighted可为空
        //static let highlightedBackgroundImage = ButtonItemKey("highlighted.backgroundImage")
        static let customView = ButtonItemKey("customView") //自定义的视图，内容为UIView类型，在样式为custom有效，不可为空
    }
}

//提交按钮的样式
public class SubmitButton {
    static var frame                        = CGRect(0,
                                                     0,
                                                     ScreenWidth() - SubviewMargin,
                                                     TableCellHeight) //默认尺寸
    static var cornerRadius                 = 5.0 as CGFloat //圆角
    static var backgroundColorNormal        = UIColor(0, 191.0, 255.0) //提交按钮正常状态的颜色
    static var backgroundColorHighlighted   = UIColor(175.0, 238.0, 238.0) //提交按钮高亮状态的颜色
    static var titleColor                   = UIColor.white
    static var font                         = UIFont.Preferred.headline
}