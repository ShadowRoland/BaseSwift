//
//  String+SRExtension.swift
//  BaseSwift
//
//  Created by Shadow on 2017/12/22.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

public func isEmptyString(_ string: Any?) -> Bool {
    guard let string = string as? String else { return true }
    return string.trim.isEmpty
}

//MARK: - String from others

public extension String {
    init(object: AnyObject) {
        if let arg = object as? CVarArg {
            self.init(format: "%@", arg)
        } else {
            self.init()
        }
    }
    
    init(pointer: AnyObject) {
        if let arg = pointer as? CVarArg {
            self.init(format: "%p", arg)
        } else {
            self.init()
        }
    }
    
    init(int: Int) {
        self.init(format: "%d", int)
    }
    
    init(uint: UInt) {
        self.init(format: "%u", uint)
    }
    
    init(long: CLong) {
        self.init(format: "%lu", long)
    }
    
    init(longLong: CLongLong) {
        self.init(format: "%lld", longLong)
    }
    
    init(float: Float) {
        self.init(format: "%f", float)
    }
    
    init(double: Double) {
        self.init(format: "%f", double)
    }
    
    init(class object: Any) {
        if let arg = type(of: object) as? CVarArg {
            self.init(format: "%@", arg)
        } else {
            self.init()
        }
    }
    
    init(date: Date?, format: String? = "yyyy-MM-dd HH:mm:ss") {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            self.init(formatter.string(from: date))
        } else {
            self.init()
        }
    }
    
    init(timestamp: TimeInterval, format: String? = nil) {
        self.init(date: Date(timeIntervalSince1970: timestamp > 9999999999 ? timestamp / 1000 : timestamp),
                  format: format ?? "yyyy-MM-dd HH:mm:ss")
    }
}

//MARK: - String to other, or other to string

public extension String {
    var fullRange: Range<String.Index> {
        return startIndex ..< endIndex
    }
    
    var color: UIColor {
        var string = trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).uppercased()
        
        if (string.hasPrefix("#")) {
            string = string.substring(from: 1)
        }
        
        let length = string.count
        switch length {
        case 1, 2: //"#6" -> "#666666", "#6E" -> "#6E6E6E"
            var hexInt = 0 as CUnsignedInt
            Scanner(string: string).scanHexInt32(&hexInt)
            return UIColor(white: CGFloat(hexInt) / (length == 1 ? 15.0 : 255.0), alpha: 1.0)
            
        case 3, 4: //"#6E9" -> "#66EE99", "#6E9A" -> "#66EE99AA"
            var red = 0 as CUnsignedInt
            var green = 0 as CUnsignedInt
            var blue = 0 as CUnsignedInt
            var alpha = 15 as CUnsignedInt
            Scanner(string: string[0 ..< 1]).scanHexInt32(&red)
            Scanner(string: string[1 ..< 2]).scanHexInt32(&green)
            Scanner(string: string[2 ..< 3]).scanHexInt32(&blue)
            if length == 4 {
                Scanner(string: string[3 ..< 4]).scanHexInt32(&alpha)
            }
            return UIColor(red: CGFloat(red) / 15.0,
                           green: CGFloat(green) / 15.0,
                           blue: CGFloat(blue) / 15.0,
                           alpha: CGFloat(alpha) / 15.0)
            
        case 6, 8: //"#FE5B30", "#FE5B30AA"
            var red = 0 as CUnsignedInt
            var green = 0 as CUnsignedInt
            var blue = 0 as CUnsignedInt
            var alpha = 255 as CUnsignedInt
            Scanner(string: string[0 ... 1]).scanHexInt32(&red)
            Scanner(string: string[2 ... 3]).scanHexInt32(&green)
            Scanner(string: string[4 ... 5]).scanHexInt32(&blue)
            if length == 8 {
                Scanner(string: string[6 ... 7]).scanHexInt32(&alpha)
            }
            return UIColor(red: CGFloat(red) / 255.0,
                           green: CGFloat(green) / 255.0,
                           blue: CGFloat(blue) / 255.0,
                           alpha: CGFloat(alpha) / 255.0)
            
        default:
            return UIColor()
        }
    }
    
    func date(_ format: String? = nil) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format ?? "yyyy-MM-dd HH:mm:ss"
        return  formatter.date(from: self)
    }
    
    init(jsonObject: Any?) {
        self.init()
        if let jsonObject = jsonObject {
            append(JSON(jsonObject).rawString() ?? "")
        }
    }
    
    var jsonObject: Any? {
        if let data = data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return JSON(data).rawValue
        } else {
            return nil
        }
    }
    
    var fileJsonObject: Any? {
        var data: Data? = nil
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: self))
        } catch {
            LogWarn(String(format: "Read JSON file failed!\nerror: %@\nfile path: %@",
                           error.localizedDescription,
                           self))
            return nil
        }
        
        var object: AnyObject? = nil
        do {
            object = try JSON(data: data!).rawValue as AnyObject?
        } catch {
            LogWarn(String(format: "Convert data to JSON failed!\nerror: %@\nfile path: %@",
                           error.localizedDescription,
                           self))
        }
        return object
    }
    
    var fileSize: UInt64 {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: self, isDirectory: &isDirectory) else {
            return 0
        }
        
        if !isDirectory.boolValue {
            let attributes = try? FileManager.default.attributesOfItem(atPath: self)
            return attributes?[.size] as? UInt64 ?? 0
        }
        
        let totalSize = FileManager.default.subpaths(atPath: self)?.reduce(0, {
            $0 + self.appending(pathComponent: $1).fileSize
        })
        return totalSize ?? 0
    }
    
    func textSize(_ font: UIFont, maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) -> CGSize {
        return textSize(attibutes: [.font : font],
                        options: nil,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight)
    }
    
    func textSize(attibutes: [NSAttributedString.Key : Any],
                  options: NSStringDrawingOptions? = nil,
                  maxWidth: CGFloat? = nil,
                  maxHeight: CGFloat? = nil) -> CGSize {
        return (self as NSString).boundingRect(with: CGSize(width: maxWidth ?? CGFloat.greatestFiniteMagnitude,
                                                            height: maxHeight ?? CGFloat.greatestFiniteMagnitude),
                                               options: options ?? .calculateTextSize,
                                               attributes: attibutes,
                                               context: nil).size
    }
}

//MARK: - Substring

public extension String {
    //string[a ..< b]
    subscript(range: CountableClosedRange<Int>) -> String {
        let lower = index(startIndex, offsetBy: range.lowerBound)
        let upper = index(startIndex, offsetBy: range.upperBound + 1)
        //return substring(with: Range<String.Index>(uncheckedBounds: (lower: lower,
        //                                                             upper: upper)))
        return String(self[Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))])
    }
    
    //string[a ... b]
    subscript(range: Range<Int>) -> String {
        let lower = index(startIndex, offsetBy: range.lowerBound)
        let upper = index(startIndex, offsetBy: range.upperBound)
        return String(self[Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))])
    }
    
    func substring(from: Int) -> String {
        return self[min(from, count) ..< count]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< min(to, count)]
    }
    
    func substring(from: Int, length: Int) -> String {
        let start = min(from, count)
        let end = min(start + count, count)
        return self[from ..< end]
    }
    
    func substring(from:Int, to:Int) -> String {
        let start = min(from, count)
        let end = max(start, min(to + 1, count))
        return self[start ..< end]
    }
}

//MARK: - String format

public extension String {
    //"   aa bb   " -> "aa bb"
    var trim: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    //"   aa bb   " -> "aabb"
    var condense: String {
        return components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined()
    }
    
    //文件路径
    func appending(pathComponent: String?) -> String {
        guard let pathComponent = pathComponent, !pathComponent.isEmpty else {
            return self
        }
        return String((self as NSString).appendingPathComponent(pathComponent))
    }
    
    func appending(urlComponent: String?) -> String {
        guard let component = urlComponent?.trim, !component.isEmpty else {
            return self
        }
        
        let trimString = trim
        if trimString.hasSuffix("/") {
            if component.hasPrefix("/") {
                return trimString + component.substring(from: 1)
            } else {
                return trimString + component
            }
        } else {
            if component.hasSuffix("/") {
                return trimString + component
            } else {
                return trimString + "/" + component
            }
        }
    }
    
    var htmlText: String {
        return String(format: HtmlTextFormat,
                      (self as NSString).replacingOccurrences(of: "\n", with: "<br>"))
    }
    
    //html字符串转换为NSAttributedString
    var attributedString: NSAttributedString? {
        return NSAttributedString(htmlData: data(using: String.Encoding.utf8)!,
                                  options:[NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.html,
                                           NSAttributedString.DocumentAttributeKey.characterEncoding :  String.Encoding.utf8.rawValue],
                                  documentAttributes: nil)
    }
}

//MARK: - 常用的正则表达式

public extension String {
    struct Regex {
        public static let number = "^[\\d]+$"
        public static let numberValue = "^[+-]?[\\d]+(\\.[\\d]+)?$"
        public static let uNumberValue = "^[+]?[\\d]+(\\.[\\d]+)?$" //正数
        
        public static var account = "^\\w{1,16}$"
        public static var accountInputing = "^\\w+$"
        public static var password = "^[0-9a-zA-Z!@#$%*()_+^&]{6,20}$"
        public static var passwordInputing = "^[0-9a-zA-Z!@#$%*()_+^&]+$"
        public static var verificationCode = "^[0-9a-zA-Z]+$"
        public static var email = "[A-Z0-9a-z_%]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        public static var chinaId = "^(^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}([0-9]|X)$)|(^[1-9]\\d{7}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}$)$" //中华人民共和国第一代和第二代身份证号码
        public static var chinaIdInputing = "^[0-9xX]+$"
    }
}

//MARK: - Regex

public extension String {
    //正则表达式匹配
    func regex(_ match: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", match).evaluate(with: self)
    }
    
    var isAccount: Bool { return regex(String.Regex.account) } //账号匹配
    
    var isPassword: Bool { return regex(String.Regex.password) } //密码匹配
    
    var isEmail: Bool { return regex(String.Regex.email) } //邮箱匹配
    
    var isNumberValue: Bool { return regex(String.Regex.numberValue) } //数值匹配
    
    var isChinaId: Bool { return regex(String.Regex.chinaId) } //中国居民身份证号码匹配
    
    func isMobileNumber(regionCode: String) -> Bool {
        let phoneUtil = NBPhoneNumberUtil()
        let countryCode = phoneUtil.getCountryCode(forRegion: regionCode).intValue
        guard countryCode != 0 else {
            print("regionCode is invalid: \(regionCode)")
            return false
        }
        return isMobileNumber(countryCode: countryCode,
                              regionCode: regionCode,
                              phoneUtil: phoneUtil)
    }
    
    func isMobileNumber(countryCode: Int) -> Bool {
        let phoneUtil = NBPhoneNumberUtil()
        guard let regionCode =
            phoneUtil.getRegionCode(forCountryCode: NSNumber(value: countryCode)),
            !isEmptyString(regionCode) else {
                print("countryCode is invalid: \(countryCode)")
                return false
        }
        return isMobileNumber(countryCode: countryCode,
                              regionCode: regionCode,
                              phoneUtil: phoneUtil)
    }
    
    private func isMobileNumber(countryCode: Int,
                                regionCode: String,
                                phoneUtil: NBPhoneNumberUtil) -> Bool {
        var string = trim
        let code = String(int: countryCode)
        string = string.replacingOccurrences(of: ("^[+＋]?0]?" + code),
                                             with: code,
                                             options: .regularExpression,
                                             range: fullRange)
        var phoneNumber: NBPhoneNumber?
        do {
            phoneNumber = try phoneUtil.parse(string, defaultRegion: regionCode)
            //let formattedString = try phoneUtil.format(phoneNumber, numberFormat: .E164)
            //NSLog("[%@]", formattedString)
        } catch  {
            print(error.localizedDescription)
            return false
        }
        return phoneUtil.isNumberGeographical(phoneNumber!)
    }
}

//MARK: - 数字格式

public extension String {
    //千位逗号分隔符格式
    var commaJoined: String {
        var count = 0
        var ll = CLongLong(self)
        guard ll != nil else {
            return self
        }
        while ll != 0 {
            count += 1
            ll = ll! / 10
        }
        
        let array = components(separatedBy: ".")
        var string: String = String(array[0])
        var formatString = ""
        while count > 3 {
            count -= 3
            let range = string.index(string.endIndex, offsetBy: -3) ..< string.endIndex
            formatString = "," + string[range] + formatString
            string.removeSubrange(range)
        }
        formatString = string + formatString
        
        //补充浮点数的位数
        return array.count > 1
            ? formatString.appendingFormat(".%@", array[1]) //不再对小数进行分割
            : formatString
    }
    
    //使用K(千)做单位，最多到B(十亿)，应该足够了……应该吧
    //decimalPlaces: 最多保留的位数
    func thousands(_ decimalPlaces: UInt = 0) -> String {
        if let uint = UInt(self) {
            return uint.thousands(decimalPlaces)
        }
        return self
    }
    
    //使用万做单位，最多到亿
    func tenThousands(_ decimalPlaces: UInt = 0) -> String {
        if let uint = UInt(self) {
            return uint.tenThousands(decimalPlaces)
        }
        return self
    }
}

//MARK: - Localize

public extension String {
    var localized: String {
        //return NSLocalizedString(self, comment:"")
        return Bundle.main.localizedString(forKey: self, value: nil, table: "Localizable")
    }
}

public extension NSStringDrawingOptions {
    static var calculateTextSize: NSStringDrawingOptions {
        return [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine]
    }
}

extension String {
    static var srBundle: Bundle!
    var srLocalized: String {
        if String.srBundle == nil {
            var language = NSLocale.preferredLanguages.first!
            if language.hasPrefix("en") {
                language = "en"
            } else if language.hasPrefix("zh-Hans") {
                language = "zh-Hans"
            }
            String.srBundle = Bundle(path: Bundle.sr.path(forResource: language, ofType: "lproj")!)
        }
        return Bundle.main.localizedString(forKey: self,
                                           value: String.srBundle.localizedString(forKey: self,
                                                                                  value: nil,
                                                                                  table: ""),
                                           table: "")
    }
}
