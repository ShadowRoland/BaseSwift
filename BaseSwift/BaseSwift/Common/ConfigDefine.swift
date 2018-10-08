//
//  ConfigDefine.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation
import UIKit

//MARK: DEBUG，入口类型
var Entrance: EntranceStyle = .none
public enum EntranceStyle {
    case none,
    simple,
    sns,
    news,
    aggregation
}

//MARK: 生产环境的参数
let BaseServerURLProduction = "https://api.xxxxxx.com/internal"

//MARK: 配置参数
let ConfigFilePath = ResourceDirectory.appending(pathComponent: "json/config.json")

//MARK: - 应用程序可配置项

//MARK: Scheme

struct Scheme {
    //MARK: Application，其他应用调用本应用，对应Info.plist中的"URL types"配置参数
    static let base = "baseswift"
    static let base2 = "shadowbaseswift" //可选
    
    //MARK: Third application，本应用调用其他应用的scheme
    static let baseSwift4QQ = "baseswift4qq" //QQ分享，需要注册后使用申请的appkey替换
    static let baseSwift4Wechat = "baseswift4wechat" //微信分享，微信支付，需要注册后使用申请的appkey替换
    static let baseSwift4Weibo = "baseswift4weibo" //微博分享，需要注册后使用申请的appkey替换
    static let baseSwift4Alipay = "baseswift4alipay" //支付宝支付，可自定义
    
    static let amap = "iosamap" //高德地图
    static let baiduMap = "baidumap" //百度地图
}

//MARK: - Action

/*
 * 系统应用、第三方应用、推送通知等调用本应用时的操作
 */
class Action {
    static let more = "more" //跳转到更多页面
    static let profile = "profile" //跳转到个人页面
    static let setting = "setting" //跳转到设置页面
    static let openWebpage = "openWebpage" //打开指定的网页
    
    //应用内部事件对应的外部的调用参数，一般来说是一(应用内部事件)对多（外部调用参数）的关系
    class func actions(_ option: Int) -> [String] {
        switch option {
        case Event.Option.showMore:
            return [more]
            
        case Event.Option.showProfile:
            return [profile]
            
        case Event.Option.showSetting:
            return [setting]
            
        case Event.Option.openWebpage:
            return [openWebpage]
            
        default:
            return []
        }
    }
}

//MARK: - Event

//此处事件使用Int而不使用Enum是为了兼容State machine中event
class Event {
    static let showAdvertisingGuard = 1
    static let showAdvertising = 2
    
    //根据外部的调用参数（推送，第三方应用，peek & pop）返回的应用内部事件
    struct Option {
        static let showMore = 1000
        static let showProfile = showMore + 1
        static let showSetting = showProfile + 1
        static let openWebpage = showSetting + 1
        
        //以上的Option事件务必保持递增状态，以便返回形势简单的range，供遍历
        static let range = showMore ... openWebpage
    }
    
    //根据外部的调用参数（推送，第三方应用，peek & pop）返回的应用内部事件
    class func option(_ action: String) -> Int? {
        if Action.more == action {
            return Option.showMore
        } else if Action.profile == action {
            return Option.showProfile
        } else if Action.setting == action {
            return Option.showSetting
        } else if Action.openWebpage == action {
            return Option.openWebpage
        }
        
        return nil
    }
}

//MARK: 在UserDefault使用的KEY

//格式为前缀"USKey" + 带语意的后缀
extension USKey {
    static let config = "config"
    static let showGuide = "showGuide"
    static let showAdvertisingGuide = "showAdvertisingGuide"
    static let serverConfig = "serverConfig"
    static let lastLoginUserName = "lastLoginUserName"
    static let lastLoginPassword = "lastLoginPassword"
    static let sinaCookie = "sinaCookie"
    static let newsChannels = "newsChannels"
    static let searchSuggestionHistory = "searchSuggestionHistory"
    static let enterAggregationEntrance = "enterAggregationEntrance"
}

////自定义的通知名
extension Notification.Name {
    public struct This {
        //public static let navigationController = Notification.Name(rawValue: "navigationController")//给导航栏的通知
        static let refreshProfile = Notification.Name("This.refreshProfile")
        static let reloadProfile = Notification.Name("This.reloadProfile")
    }
}

public enum IntForBool: Int {
    case False = 0,//否
    True = 1//是
}

//MARK: - 资源

public enum ResourceSize {
    case min,
    normal,
    max
}

public struct Resource {
    public static func defaultImage(_ size: ResourceSize) -> UIImage {
        switch size {
        case .min:
            return UIImage(named: "default_image_min")!
        case .normal:
            return UIImage(named: "default_image")!
        case .max:
            return UIImage(named: "default_image_max")!
        }
    }
    
    public static func defaultHeadPortrait(_ size: ResourceSize) -> UIImage {
        switch size {
        case .min:
            return UIImage(named: "default_avatar_min")!
        case .normal:
            return UIImage(named: "default_avatar")!
        case .max:
            return UIImage(named: "default_avatar_max")!
        }
    }
}

let VideosDirectory = DocumentsDirectory.appending(pathComponent: "Videos")
let VideosCacheDirectory = DocumentsDirectory.appending(pathComponent: "VideosCache")

//MARK: - 列表加载时的常用变量名和参数

public struct TableLoadData {
    public enum ProgressType {
        case none //不展示加载的转圈
        case clearMask //透明背景的转圈
        case opaqueMask //遮住背景的转圈
    }
    
    static let key = "loadType"
    static let new = "new"
    static let more = "more"
    static let page = "page"
}

//MARK: - http请求、解析等参数

//MARK: 参数默认值

public struct ParamDefaultValue {
    static let constValue = 1
    static let limit = 10
    static let separatorComma = ","//逗号分隔符
}

//MARK: - 计量单位

public struct Unit {
    //MARK: Quantity
    
    static let ten = "ten".localized
    static let hundred = "hundred".localized
    static let thousand = "thousand".localized
    static let tenThousand = "tenThousand".localized
    static let million = "million".localized
    static let hundredMillion = "hundredMillion".localized
    static let billion = "billion".localized
    
    //MARK: Date & Time
    
    static let year = "year".localized
    static let month = "month".localized
    static let day = "day".localized
    static let hour = "hour".localized
    static let hour2 = "hour".localized
    static let minute = "minute".localized
    static let minute2 = "minute2".localized
    static let second = "second".localized
    
    //MARK: Length
    
    static let metre = "metre".localized
    static let kilometre = "kilometre".localized
    static let kilometre2 = "kilometre2".localized
    static let mile = "mile".localized
    static let centimetre = "centimetre".localized
    
    //MARK: Area
    
    static let squareMeter = "㎡".localized
    
    //MARK: Weight
    
    static let kilogram = "kilogram".localized
    
    static let gram = "gram".localized
    
    //MARK: Others
    
    static let yuan = "yuan".localized
    static let person = "person".localized
}

//MARK: 参数名

public struct ParamKey {
    //Common
    static let status = "status"
    static let type = "type"
    static let image = "image"
    static let img = "img"
    static let width = "width"
    static let height = "height"
    static let video = "video"
    static let title = "title"
    static let text = "text"
    static let alert = "alert"
    static let url = "url"
    static let link = "link"
    static let message = "message"
    static let description = "description"
    static let timestamp = "timestamp"
    static let date = "date"
    static let version = "version"
    
    //MARK: Device
    static let os = "os"
    static let deviceModel = "deviceModel"
    static let deviceId = "deviceId"
    static let deviceToken = "deviceToken"

    //MARK: Action
    static let action = "action"
    static let sender = "sender"
    static let recipient = "recipient"
    static let event = "event"
    
    //MARK: Table
    static let id = "id"
    static let limit = "limit"
    static let offset = "offset"
    static let total = "total"
    static let page = "page"
    static let list = "list"
    static let selected = "selected"
    
    //MARK: Profile
    static let user = "user"
    static let token = "token"
    static let session = "session"
    static let userId = "userId"
    static let userName = "userName"
    static let name = "name"
    static let first = "first"
    static let middle = "middle"
    static let last = "last"
    static let password = "password"
    static let newPassword = "newPassword"
    static let nickname = "nickname"
    static let remarkName = "remarkName"
    static let letter = "letter"
    static let headPortrait = "headPortrait"
    static let headPortraitImage = "headPortraitImage"
    static let portraitUri = "portraitUri"
    static let balance = "balance"
    static let badge = "badge"
    static let phone = "phone"
    static let countryCode = "countryCode"
    
    static let signature = "signature"
    static let gender = "gender"
    static let bool = "bool"
    static let birthDate = "birthDate"
    static let nativePlace = "nativePlace"
    static let location = "location"
    static let faceValue = "faceValue"
    static let weight = "weight"
    static let dickLength = "dickLength"
    static let fuckDuration = "fuckDuration"
    static let houseArea = "houseArea"
    static let bust = "bust"
    static let waistline = "waistline"
    static let hipline = "hipline"
    static let annualIncome = "annualIncome"
    static let sexualOrientation = "sexualOrientation"
    static let transvestism = "transvestism"
    static let tofuCurdTaste = "tofuCurdTaste"
    static let loveGames = "loveGames"
    static let stayWebs = "stayWebs"
    static let preferredTopics = "preferredTopics"

    static let pId = "pId"

    //MARK: Address
    static let address = "address"
    static let country = "country"
    static let province = "province"
    static let city = "city"
    static let region = "region"
    static let street = "street"
    static let roomNo = "roomNo"
    static let postcode = "postcode"
    static let areaCode = "areaCode"
    
    //MARK: Message
    static let detail = "detail"
    static let blogType = "blogType"
    static let thumbnail = "thumbnail"
    static let images = "images"
    static let videos = "videos"
    static let share = "share"
    static let like = "like"
    static let liked = "liked"
    static let comment = "comment"
    
    //MARK: News
    static let base = "base"
    static let docID = "docID"
    static let source = "source"
    static let count = "count"
    static let mediaTypes = "mediaTypes"
    static let jsonCallback = "jsoncallback"
    static let callback = "callback"
    static let code = "code"
    static let data = "data"
    static let cb = "_cb"
    static let t = "_t"
    static let key = "key"
    
    //MARK: MAP
    static let distance = "distance"
    static let interval = "interval"
}
