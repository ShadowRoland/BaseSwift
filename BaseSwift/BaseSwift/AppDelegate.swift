//
//  AppDelegate.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/13.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import UserNotifications
import CocoaLumberjack
import SlideMenuControllerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print(try! String(contentsOfFile: ResourceDirectory.appending(pathComponent: "welcome.txt"),
                          encoding: String.Encoding.utf8))
        Common.screenScale()
        DispatchQueue.global(qos: .default).async {
            TitleChoiceModel.updatesChoicesDic()
            Division.update()
        }
        
        initLogger()
        if let options = launchOptions {
            if let string = Common.jsonString(options) {
                LogInfo("\(#function), launchOptions: \(string)")
            } else {
                LogInfo("\(#function), launchOptions: \(String(describing: options))")
            }
        } else {
            LogInfo("\(#function)")
        }

        initBFModules()
        initHttpServer()
        
        initShare()
        initMap()
        
        if UserStandard[USKey.isFreeInterfaceOrientations] == nil {
            ShouldAutorotate = false
            SupportedInterfaceOrientations = .portrait
        } else {
            ShouldAutorotate = true
            SupportedInterfaceOrientations = [.portrait, .landscape]
        }
        
        createShortcutItems()
        
        //引导页与广告页交替
        if UserStandard[USKey.showGuide] != nil { //本次显示引导页
            UserStandard[USKey.showAdvertisingGuide] = nil //本次不显示广告页
            UserStandard[USKey.showGuide] = nil //下次不显示广告页
            
            let vc = Common.viewController("AppGuideViewController", storyboard: "Main")
            self.window?.rootViewController = SRNavigationController(rootViewController: vc)
            self.window?.makeKeyAndVisible()
        } else {
            UserStandard[USKey.showAdvertisingGuide] = true //本次显示广告页
            UserStandard[USKey.showGuide] = true //下次显示广告页
            if UserStandard[USKey.enterAggregationEntrance] != nil {
                createSlideMenu()
            }
        }
        
        registerForRemoteNotifications()
        
        //其他程序调起程序添加了启动参数，
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            let _ = self.application(application, handleOpen: url)
        } else if let options = launchOptions {
            self.application(application, handleOptions: options)
        }
        
        ///*
        NSSetUncaughtExceptionHandler { exception in
            print("Exception Handling: ", exception)
            print("Exception Handling callStackSymbols: ")
            exception.callStackSymbols.forEach { print($0) }
        }
        //*/
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: Application notification
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        LogInfo("\(#function), token: \(token)")
        Common.updateDeviceToken(token)
    }
    
    /*
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LogError("\(#function), error: \(error.localizedDescription)")
    }
    */
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        var string = Common.jsonString(userInfo)
        string = !Common.isEmptyString(string) ? string : String(describing: userInfo)
        LogInfo("\(#function), userInfo:\n\(string!)")
        self.application(application, handleOptions: userInfo)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        let userInfo = notification.userInfo
        var string = Common.jsonString(userInfo)
        string = !Common.isEmptyString(string) ? string : String(describing: userInfo)
        LogInfo("\(#function), userInfo:\n\(string!)")
        if let userInfo = notification.userInfo {
            self.application(application, handleOptions: userInfo)
        }
    }
    
    //MARK: Application call & response
    
    //called by spotlight, universal link
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL {
            restorationHandler(nil)
            return self.application(application, handleOpen: url)
        }
        return true
    }
    
    //called by third application
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let sourceApplication =
            options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String {
            LogInfo("called by \(sourceApplication)")
        }
        return application(app, handleOpen: url)
    }
    
    //called by 3D touch peek & pop
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let userInfo = shortcutItem.userInfo {
            self.application(application, handleOptions: userInfo)
        }
    }
    
    //MARK: - 处理应用的url
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        LogInfo("\(#function), url: \(url.absoluteString)")
        
        //调用本应用
        if Scheme.base == url.scheme || Scheme.base2 == url.scheme {
            self.application(application, handleOptions: url.queryDictionary)
            return true
        }
        
        /* QQ第三方库文件添加到工程后放开注释
        //QQ分享回调
        if Scheme.baseSwift4QQ == url.scheme {
            if QQApiInterface.handleOpen(url,
                                         delegate: SRShareToolDefaultDelegate.shared.qqDelegate) {
                Common.showAlert(message: "Share Success")
            }
            return true
        }
        ****************************/

        /* 微信第三方库文件添加到工程后放开注释
        //微信分享、支付回调
        if Scheme.baseSwift4Wechat == url.scheme {
            if WXApi.handleOpen(url, delegate: SRShareToolDefaultDelegate.shared) {
                Common.showAlert(message: "Share Success")
            }
            return true
        }
        ****************************/
        
        /* 微博第三方库文件添加到工程后放开注释
        //微博分享回调
        if Scheme.baseSwift4Weibo == url.scheme {
            if WeiboSDK.handleOpen(url, delegate: SRShareToolDefaultDelegate.shared) {
                Common.showAlert(message: "Share Success")
            }
            return true
        }
        ****************************/
        
        return false
    }
    
    //MARK: - 处理应用的指令，指令可能来源于推送（本地&远程），其他程序调用，指压peek & pop等
    
    private var options: [AnyHashable : Any]?
    
    /* options格式为
     * { "action" : "xxx",
     *   "alert" : "您有新的消息",
     *   "url" : "http://xxxxx",
     *   "..." : "..."
     *  }
     *  action为必填，其他可选
     *  alert为苹果推送自带的推送文字参数
     */
    func application(_ application: UIApplication, handleOptions options: [AnyHashable : Any]) {
        guard let action = options[ParamKey.action] as? String,
            Action.more == action
                || Action.profile == action
                || Action.setting == action
                || Action.openWebpage == action else {
                    return
        }
        
        self.options = options
        if UIApplication.shared.applicationState == .active { //应用位于前台时收到推送，此时弹出提示询问是否需要执行推送的操作
            DispatchQueue.main.async {
                Keyboard.hide {
                    let alert = SRAlert()
                    alert.addButton("See".localized,
                                    backgroundColor: NavigartionBar.backgroundColor,
                                    action:
                        {
                            self.handleOptions()
                    })
                    var message = "You have a new message".localized
                    if let string = self.options?[ParamKey.message] as? String {
                        message = string
                    }
                    alert.show(.notice,
                               title: EmptyString,
                               message: message,
                               closeButtonTitle: "Cancel".localized)
                }
            }
        } else {
            handleOptions()
        }
    }
    
    func handleOptions() {
        Common.updateActionParams(self.options as? ParamDictionary)
        if let action = Common.currentActionParams()?[ParamKey.action] as? String,
            Event.Option.openWebpage == Event.option(action) {
            let rootVC = Common.rootVC
            let vc = rootVC?.navigationController?.viewControllers.last as? BaseViewController
            vc?.stateMachine.append(option: Event.Option.openWebpage)
            return
        }
        
        DispatchQueue.main.async {
            NotifyDefault.post(Notification.Name.Base.newAction)
        }
    }
    
    //MARK: - Register remote notifications
    
    func registerForRemoteNotifications() {
        let setting = UIUserNotificationSettings(types: [.alert, .badge, .sound],
                                                 categories: nil)
        UIApplication.shared.registerUserNotificationSettings(setting)
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            let options = UNAuthorizationOptions(arrayLiteral: [.alert, .badge, .sound])
            center.requestAuthorization(options: options) { (granted, error) in
                if granted {
                    print("iOS request notification success")
                } else {
                    print(" iOS 10 request notification fail")
                }
            }
        }
        
        UIApplication.shared.registerForRemoteNotifications()
    }

    //MARK: - 应用初始化
    
    //日志系统初始化
    func initLogger() {
        if RunInEnvironment == .production {
            CocoaLumberjack.defaultDebugLevel = .info
        }
        DDLog.add(DDASLLogger.sharedInstance)
        
        let fileLogger = DDFileLogger() as DDFileLogger
        fileLogger.rollingFrequency = TimeInterval(60 * 60 * 24)   // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 20
        DDLog.add(fileLogger)
    }
    
    func initBFModules() {
        let _ = ProfileManager(.profile)
        let _ = HttpManager.shared
        let _ = IMManager(.im)
    }
    
    func initHttpServer() {
        guard RunInEnvironment != .production else { return }
        SRHttpServer.shared.start()
    }
    
    func initShare() {
        //let _ = WeiboSDK.registerApp(Scheme.baseSwift4Weibo) /* 微博第三方库文件添加到工程后放开注释 */
    }
    
    func initMap() {
        AMapServices.shared().apiKey = "c84cb6b30fb6b475abe2d7cee8231323"
    }
    
    //MARK: - 业务处理
    
    func createShortcutItems() {
        guard #available(iOS 9.1, *) else {
            return
        }
        
        let moreItem =
            UIApplicationShortcutItem(type: "More".localized,
                                      localizedTitle: "More".localized,
                                      localizedSubtitle: nil,
                                      icon: nil,
                                      userInfo: [ParamKey.action : Action.more])
        let profileItem =
            UIApplicationShortcutItem(type: "Profile".localized,
                                      localizedTitle: "Profile".localized,
                                      localizedSubtitle: "Please Login".localized,
                                      icon: UIApplicationShortcutIcon(type: .contact),
                                      userInfo: [ParamKey.action : Action.profile])
        let settingItem =
            UIApplicationShortcutItem(type: "Setting".localized,
                                      localizedTitle: "Setting".localized,
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(templateImageName: "settings"),
                                      userInfo: [ParamKey.action : Action.setting])
        let openWebpageItem =
            UIApplicationShortcutItem(type: "Open webpage".localized,
                                      localizedTitle: "Open webpage".localized,
                                      localizedSubtitle: "Death is a surprise party".localized,
                                      icon: UIApplicationShortcutIcon(type: .bookmark),
                                      userInfo: [ParamKey.action : Action.openWebpage,
                                                 ParamKey.url : "http://www.gzbz.com.cn/dead_men/"])
        UIApplication.shared.shortcutItems = [moreItem,
                                              profileItem,
                                              settingItem,
                                              openWebpageItem].reversed()
    }

    func createSlideMenu() {
        Entrance = .aggregation
        
        SlideMenuOptions.leftViewWidth = 240.0
        let mainMenuVC = Common.viewController("MainMenuViewController", storyboard: "Aggregation")
            as! MainMenuViewController
        let leftMenuVC = Common.viewController("LeftMenuViewController", storyboard: "Aggregation")
            as! LeftMenuViewController
        let navigationVC = SRNavigationController(rootViewController: mainMenuVC)
        let aggregationVC = AggregationViewController(mainViewController: navigationVC,
                                                      leftMenuViewController: leftMenuVC)
        aggregationVC.automaticallyAdjustsScrollViewInsets = true
        aggregationVC.delegate = mainMenuVC
        
        leftMenuVC.aggregationVC = aggregationVC
        leftMenuVC.mainMenuVC = mainMenuVC
        mainMenuVC.aggregationVC = aggregationVC
        mainMenuVC.leftMenuVC = leftMenuVC
        
        self.window?.rootViewController = aggregationVC
        self.window?.makeKeyAndVisible()
    }
}

//MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        var string = Common.jsonString(userInfo)
        string = !Common.isEmptyString(string) ? string : String(describing: userInfo)
        LogInfo("\(#function), userInfo:\n\(string!)")
        self.application(UIApplication.shared,
                         handleOptions: response.notification.request.content.userInfo)
    }
}
