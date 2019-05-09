//
//  Config.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

public typealias Event = SRKit.Event
public typealias TableLoadData = Config.TableLoadData

public class Config {
    //MARK: DEBUG，入口类型
    static var entrance: EntranceStyle = .none
    public enum EntranceStyle {
        case none,
        simple,
        sns,
        news,
        aggregation
    }
    
    //MARK: 生产环境的参数
    static let BaseServerURLProduction = "https://api.xxxxxx.com/internal"
    
    //MARK: 环境配置参数
    static let envFilePath = ResourceDirectory.appending(pathComponent: "json/env.json")
    
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
    
    static let refreshProfileNotification = Notification.Name("This.refreshProfile")
    static let reloadProfileNotification = Notification.Name("This.reloadProfile")
    
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
    
    static let VideosDirectory = DocumentsDirectory.appending(pathComponent: "Videos")
    static let VideosCacheDirectory = DocumentsDirectory.appending(pathComponent: "VideosCache")
    
    //MARK: - 列表加载数据
    
    public class TableLoadData {
        public enum ProgressType {
            case none //不展示加载的转圈
            case clearMask //透明背景的转圈
            case opaqueMask //遮住背景的转圈
        }
        
        public enum Page {
            case new
            case more
        }
        
        static let row = 10
        static let limit = 10
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
}

extension SRKit.Event {
    convenience init?(params: ParamDictionary) {
        let action = params[Param.Key.action] as? String
        if let option = Event.Action.allCases.first(where: { $0.rawValue == action })?.option {
            self.init(option, params: params)
        } else {
            return nil
        }
    }
}

extension SRKit.Event.Option {
    static let showAdvertisingGuard = Event.Option(1)
    static let showAdvertising = Event.Option(2)
    
    static let openWebpage = Event.Option(1000) //打开指定的网页
    static let showMore = Event.Option(1001) //跳转到更多页面
    static let showProfile = Event.Option(1002) //跳转到个人页面
    static let showSetting = Event.Option(1003) //跳转到设置页面
}

extension SRKit.Event.Action: Swift.CaseIterable {
    static let openWebpage = Event.Action("openWebpage", option: .openWebpage)
    static let more = Event.Action("more", option: .showMore)
    static let profile = Event.Action("profile", option: .showProfile)
    static let setting = Event.Action("setting", option: .showSetting)
    
    public static var allCases: [SRKit.Event.Action] {
                return [.openWebpage,
                        .more,
                        .profile,
                        .setting]
    }
}

//MARK: 在UserDefault使用的KEY

//格式为前缀"USKey" + 带语意的后缀
extension USKey {
    static let env = "env"
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

//MARK: 参数名

extension Param.Key {
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
