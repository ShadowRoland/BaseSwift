//
//  ProfileDetailViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SwiftyJSON
//import MWPhotoBrowser
import SDWebImage
import Alamofire

class ProfileDetailForm: ProfileForm {
    var isMultiple = false //是否可以多选
    var isShowSelectAll = true //在可多选的情况下是否显示全选的选项
}

extension SRIndexPathConfigKey {
    public static let isMultiple: SRIndexPathConfigKey = SRIndexPathConfigKey("isMultiple")
    public static let isShowSelectAll: SRIndexPathConfigKey = SRIndexPathConfigKey("isShowSelectAll")
}

class ProfileDetailViewController: BaseViewController {
    var isFirstDidLoadSuccess = false //第一次加载已成功
    lazy var indexPathSet: SRIndexPathSet = SRIndexPathSet()
    var lastSection = IntegerInvalid
    var lastSectionWillAdd = IntegerInvalid
    var lastRow = IntegerInvalid
    weak var currentItem: ProfileDetailForm?
    
    lazy var profile: ParamDictionary = EmptyParams()
    lazy var editingProfile: ParamDictionary = EmptyParams()
    var isEditingProfile = false
    
    lazy var genderChoices: [TitleChoiceModel] = TitleChoiceModel.choices(ParamKey.gender)!
    lazy var sexualOrientationChoices: [TitleChoiceModel] =
        TitleChoiceModel.choices(ParamKey.sexualOrientation)!
    lazy var boolChoices: [TitleChoiceModel] = TitleChoiceModel.choices(ParamKey.bool)!
    lazy var tofuCurdTastChoices: [TitleChoiceModel] =
        TitleChoiceModel.choices(ParamKey.tofuCurdTaste)!
    lazy var loveGamesChoices: [TitleChoiceModel] = TitleChoiceModel.choices(ParamKey.loveGames)!
    lazy var stayWebsChoices: [TitleChoiceModel] = TitleChoiceModel.choices(ParamKey.stayWebs)!
    lazy var preferredTopicsChoices: [TitleChoiceModel] =
        TitleChoiceModel.choices(ParamKey.preferredTopics)!
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - UITableViewCell
    
    //MARK: Base Section
    
    lazy var headPortraitCell: UITableViewCell = {
        let cell = tableCell("headPortraitCell")
        let contentView = cell.contentView
        headPortraitImageView = contentView.viewWithTag(Const.imageViewTag) as? UIImageView
        cleanHeadPortraitButton = contentView.viewWithTag(Const.clearButtonTag) as? UIButton
        cleanHeadPortraitButton.clicked(self, action: #selector(cleanHeadPortrait))
        headPortraitTopConstraint =
            contentView.constraints.first { "headPortraitTopConstraint" == $0.identifier }
        headPortraitTrailingConstraint =
            contentView.constraints.first { "headPortraitTrailingConstraint" == $0.identifier }
        return cell
    }()
    weak var headPortraitImageView: UIImageView!
    weak var headPortraitTopConstraint: NSLayoutConstraint!
    weak var headPortraitTrailingConstraint: NSLayoutConstraint!
    weak var cleanHeadPortraitButton: UIButton!
    
    lazy var nicknameCell: UITableViewCell = tableCell("nicknameCell")
    lazy var signatureCell: UITableViewCell = tableCell("signatureCell")
    lazy var userNameCell: UITableViewCell = tableCell("userNameCell")
    lazy var phoneCell: UITableViewCell = tableCell("phoneCell")
    
    //MARK: Profile Section
    lazy var genderCell: UITableViewCell = tableCell("genderCell")
    lazy var birthDateCell: UITableViewCell = tableCell("birthDateCell")
    lazy var nativePlaceCell: UITableViewCell = tableCell("nativePlaceCell")
    lazy var locationCell: UITableViewCell = tableCell("locationCell")
    lazy var faceValueCell: UITableViewCell = tableCell("faceValueCell")
    lazy var heightCell: UITableViewCell = tableCell("heightCell")
    lazy var weightCell: UITableViewCell = tableCell("weightCell")
    lazy var dickLengthCell: UITableViewCell = tableCell("dickLengthCell")
    lazy var fuckDurationCell: UITableViewCell = tableCell("fuckDurationCell")
    lazy var houseAreaCell: UITableViewCell = tableCell("houseAreaCell")
    lazy var bustCell: UITableViewCell = tableCell("bustCell")
    lazy var waistlineCell: UITableViewCell = tableCell("waistlineCell")
    lazy var hiplineCell: UITableViewCell = tableCell("hiplineCell")
    lazy var annualIncomeCell: UITableViewCell = tableCell("annualIncomeCell")
    
    //MARK: Extra Section
    lazy var sexualOrientationCell: UITableViewCell = tableCell("sexualOrientationCell")
    lazy var transvestismCell: UITableViewCell = tableCell("transvestismCell")
    lazy var tofuCurdTasteCell: UITableViewCell = tableCell("tofuCurdTasteCell")
    lazy var loveGamesCell: UITableViewCell = tableCell("loveGamesCell")
    lazy var stayWebsCell: UITableViewCell = tableCell("stayWebsCell")
    lazy var preferredTopicsCell: UITableViewCell = tableCell("preferredTopicsCell")
    
    func tableCell(_ identifier: String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    var headPortraitURL: URL?
    //weak var photoBrowser: MWPhotoBrowser?
    //var photoBrowserGR: UITapGestureRecognizer?
    //var photos: [MWPhoto] = []
    
    weak var popover: SRPopover?
    var pickerView: SRPickerView!
    
    var faceImageUrl: String!
    var faceImageCookie: String!
    var faceImageContainerView: UIView!
    var faceImageView: UIImageView!
    var faceImageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        defaultNavigationBar("Profile".localized)
        setNavigationBarRightButtonItems()
        
        tableView.tableFooterView = UIView()
        initSections()
        
        showProgress()
        getProfileDetail()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 视图初始化
    
    struct Const {
        static let titleViewTag = 100
        static let inputTextViewTag = 102
        static let showTextViewTag = 101
        static let imageViewTag = 103
        static let clearButtonTag = 104
        
        static let titleViewFont = UIFont.text
        static let inputTextViewFont = UIFont.system(13)
        static let showTextViewFont = inputTextViewFont
        
        static let nicknameMaxLength = 24
        static let signatureMaxLength = 100
        static let signatureMargin = 2.0 as CGFloat
        
        static let headPortraitCellHeight = 100.0 as CGFloat
        static let headPortraitSize = CGSize(1024.0, 1024.0)
        static let editedHeadPortraitFileName = "editedHeadPortrait.png"
        static let testingFaceValueFileName = "testingFace.jpg"
    }
    
    func setNavigationBarRightButtonItems() {
        if !isEditingProfile {
            var setting = NavigartionBar.buttonFullSetting
            setting[.style] = NavigartionBar.ButtonItemStyle.text
            setting[.title] = "Edit".localized
            navBarRightButtonSettings = [setting]
        } else {
            var setting = NavigartionBar.buttonFullSetting
            setting[.style] = NavigartionBar.ButtonItemStyle.text
            setting[.title] = "Submit".localized
            navBarRightButtonSettings = [setting]
        }
    }
    
    func initSections() {
        indexPathSet.removeAll()
        lastSection = IntegerInvalid
        initBaseSection()
        initProfileSection()
        updateItemsByGender()
        initExtraSection()
        resetCellStyle()
    }
    
    func resetCellStyle() {
        for member in indexPathSet.enumerated {
            guard let item = member.element as? ProfileDetailForm,
                let cell = item.cell,
                !(cell === headPortraitCell || cell === userNameCell || cell === phoneCell) else {
                    continue
            }
            
            cell.accessoryType = isEditingProfile ? .disclosureIndicator : .none //箭头
            
            //控制右边控件到尾部的距离，有箭头的时候顶边，没箭头的让出一部分
            if let inputTextView = item.inputTextView,
                let constraint = cell.contentView.constraints.first (where: {
                    $0.firstAttribute == .trailing && inputTextView === $0.secondItem as? UIView
                }) {
                constraint.constant = isEditingProfile ? 0 : SubviewMargin
            }
            if let showTextView = item.showTextView,
                let constraint = cell.contentView.constraints.first (where: {
                    $0.firstAttribute == .trailing && showTextView === $0.secondItem as? UIView
                }) {
                constraint.constant = isEditingProfile ? 0 : SubviewMargin
            }
        }
    }
    
    func initBaseSection() {
        lastSectionWillAdd = lastSection
        lastRow = IntegerInvalid
        
        if let item = item(headPortraitCell,
                           config: [.height : Const.headPortraitCellHeight,
                                    .paramKey : ParamKey.headPortrait,
                                    .isIgnoreParamValue : true]) {
            let url = URL(string: item.value as? String ?? EmptyString)
            headPortraitImageView.sd_setImage(with: url,
                                              placeholderImage: Resource.defaultImage(.normal))
            headPortraitImageView.isUserInteractionEnabled = isEditingProfile
            headPortraitURL = url
            headPortraitTrailingConstraint.constant = 0
            cleanHeadPortraitButton.isHidden = true
        }
        
        if let item = item(nicknameCell,
                           config: [.paramKey : ParamKey.nickname,
                                    .textMaxLength : Const.nicknameMaxLength,
                                    .isIgnoreParamValue : true]) {
            item.inputText = item.value as? String ?? EmptyString
            item.inputTextView?.setProperty(.text, value: item.inputText)
        }
        
        if let item = item(signatureCell,
                           config: [.paramKey : ParamKey.signature,
                                    .textMaxLength : Const.signatureMaxLength,
                                    .isIgnoreParamValue : true]) {
            item.inputText = item.value as? String ?? EmptyString
            item.inputTextView?.setProperty(.text, value: item.inputText)
            item.showText = item.inputText
            let label = item.showTextView as! UILabel
            label.text = item.showText
            label.adjustsFontSizeToFitWidth = false
            resetSignatureHeight()
        }
        
        if let item = item(userNameCell,
                           config: [.paramKey : ParamKey.userName,
                                    .isIgnoreParamValue : true]) {
            item.showText = item.value as? String ?? EmptyString
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(phoneCell,
                           config: [.paramKey : ParamKey.phone,
                                    .isIgnoreParamValue : true]) {
            var value: Any?
            if profile.jsonValue(ParamKey.countryCode, type: .number, outValue: &value),
                NonNull.check(value) {
                let phone = "+" + String(object: value as! NSNumber) + (item.value as! String)
                item.showText = phone
                item.showTextView?.setProperty(.text, value: item.showText)
            } else {
                item.showText = item.value as? String ?? EmptyString
                item.showTextView?.setProperty(.text, value: item.showText)
            }
        }
        
        lastSection = lastSectionWillAdd
    }
    
    func initProfileSection() {
        lastSectionWillAdd = lastSection
        lastRow = IntegerInvalid
        
        if let item = item(genderCell,
                           config: [.paramKey : ParamKey.gender,
                                    .paramValueType : JsonValueType.enumInt.rawValue,
                                    .isIgnoreParamValue : true,
                                    .titleChoices : genderChoices]) {
            if !NonNull.check(item.value) {
                item.showText = "Hideyoshi".localized
                item.showTextView?.setProperty(.text, value: item.showText)
            }
        }
        
        if let item = item(birthDateCell,
                           config: [.paramKey : ParamKey.birthDate,
                                    .isRequired : true,
                                    .isIgnoreParamValue : true]) {
            var showText = EmptyString
            if let string = item.value as? String, let date = string.date(DateFormat.full) {
                showText = String(date: date, format: DateFormat.localDate)
            }
            item.showText = showText
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(nativePlaceCell,
                           config: [.paramKey : ParamKey.nativePlace,
                                    .paramValueType : JsonValueType.dictionary.rawValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            let dictionary = NonNull.dictionary(item.value)
            var names = [] as [String]
            if let province = dictionary[ParamKey.province] as? String {
                names.append(province)
            }
            if let city = dictionary[ParamKey.city] as? String {
                names.append(city)
            }
            if let region = dictionary[ParamKey.region] as? String {
                names.append(region)
            }
            let divisions = Division.divisions(names: names)
            var text = EmptyString
            divisions.forEach { text.append($0.name) }
            item.showText = text
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(locationCell,
                           config: [.paramKey : ParamKey.location,
                                    .paramValueType : JsonValueType.dictionary.rawValue,
                                    .isRequired : true,
                                    .isIgnoreParamValue : true]) {
            let dictionary = NonNull.dictionary(item.value)
            var names = [] as [String]
            if let province = dictionary[ParamKey.province] as? String {
                names.append(province)
            }
            if let city = dictionary[ParamKey.city] as? String {
                names.append(city)
            }
            if let region = dictionary[ParamKey.region] as? String {
                names.append(region)
            }
            let divisions = Division.divisions(names: names)
            var text = EmptyString
            divisions.forEach { text.append($0.name) }
            item.showText = text
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(faceValueCell,
                           config: [.paramKey : ParamKey.faceValue,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .isRequired : true,
                                    .isIgnoreParamValue : isEditingProfile]) {
            item.showText = item.value as? String ?? EmptyString
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        let floatRegex = "^[\\d.]+$"
        
        if let item = item(heightCell,
                           config: [.paramKey : ParamKey.height,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isRequired : true,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.centimetre)
                
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.centimetre)
        }
        
        if let item = item(weightCell,
                           config: [.paramKey : ParamKey.weight,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.kilogram)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.kilogram)
        }
        
        if let item = item(dickLengthCell,
                           config: [.paramKey : ParamKey.dickLength,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.centimetre)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.centimetre)
        }
        
        if let item = item(fuckDurationCell,
                           config: [.paramKey : ParamKey.fuckDuration,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : Regex.number,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.minute)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.minute)
        }
        
        if let item = item(houseAreaCell,
                           config: [.paramKey : ParamKey.houseArea,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.squareMeter)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.squareMeter)
        }
        
        if let item = item(bustCell,
                           config: [.paramKey : ParamKey.bust,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.centimetre)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.centimetre)
        }
        
        if let item = item(waistlineCell,
                           config: [.paramKey : ParamKey.waistline,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.centimetre)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.centimetre)
        }
        
        if let item = item(hiplineCell,
                           config: [.paramKey : ParamKey.hipline,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : floatRegex,
                                    .textRegex : Regex.uNumberValue,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text, value: item.inputText + Unit.centimetre)
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.centimetre)
        }
        
        if let item = item(annualIncomeCell,
                           config: [.paramKey : ParamKey.annualIncome,
                                    .paramValueType : JsonValueType.number.rawValue,
                                    .inputRegex : Regex.number,
                                    .textRegex : Regex.uNumberValue,
                                    .textMaxLength : 11,
                                    .isIgnoreParamValue : isEditingProfile]) {
            if !NonNull.check(item.value) {
                item.inputText = EmptyString
                item.inputTextView?.setProperty(.text, value: item.inputText)
            } else {
                let number = item.value as? NSNumber ?? NSNumber(value: 0)
                item.inputText = String(object: number)
                item.inputTextView?.setProperty(.text,
                                                value: item.inputText.tenThousands(number.uintValue))
            }
            item.inputTextView?.setProperty(.placeholder, value: Unit.yuan)
        }
        
        lastSection = lastSectionWillAdd
    }
    
    func initExtraSection() {
        lastSectionWillAdd = lastSection
        lastRow = IntegerInvalid
        
        if let _ = item(sexualOrientationCell,
                        config: [.paramKey : ParamKey.sexualOrientation,
                                 .paramValueType : JsonValueType.array.rawValue,
                                 .isIgnoreParamValue : isEditingProfile,
                                 .titleChoices : sexualOrientationChoices,
                                 .isMultiple : true]) {
        }
        
        if let item = item(transvestismCell,
                           config: [.paramKey : ParamKey.transvestism,
                                    .paramValueType : JsonValueType.bool.rawValue,
                                    .isIgnoreParamValue : isEditingProfile,
                                    .titleChoices : boolChoices]) {
            //adapter bool -> enum
            if let bool = item.value as? Bool {
                item.value = bool ? IntForBool.True.rawValue : IntForBool.False.rawValue
            } else {
                item.value = IntForBool.True.rawValue
            }
            item.showText = item.selectedChoicesTitle!
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let _ = item(tofuCurdTasteCell,
                        config: [.paramKey : ParamKey.tofuCurdTaste,
                                 .paramValueType : JsonValueType.array.rawValue,
                                 .isIgnoreParamValue : isEditingProfile,
                                 .titleChoices : tofuCurdTastChoices,
                                 .isMultiple : true]) {
        }
        
        if let _ = item(loveGamesCell,
                        config: [.paramKey : ParamKey.loveGames,
                                 .paramValueType : JsonValueType.array.rawValue,
                                 .isIgnoreParamValue : isEditingProfile,
                                 .titleChoices : loveGamesChoices,
                                 .isMultiple : true,
                                 .isShowSelectAll : false]) {
        }
        
        if let _ = item(stayWebsCell,
                        config: [.paramKey : ParamKey.stayWebs,
                                 .paramValueType : JsonValueType.array.rawValue,
                                 .isIgnoreParamValue : isEditingProfile,
                                 .titleChoices : stayWebsChoices,
                                 .isMultiple : true,
                                 .isShowSelectAll : false]) {
        }
        
        if let _ = item(preferredTopicsCell,
                        config: [.paramKey : ParamKey.preferredTopics,
                                 .paramValueType : JsonValueType.array.rawValue,
                                 .isIgnoreParamValue : isEditingProfile,
                                 .titleChoices : preferredTopicsChoices,
                                 .isMultiple : true]) {
        }
        
        lastSection = lastSectionWillAdd
    }
    
    //在获取了基本的item后可以做一些adapter的工作
    func item(_ cell: UITableViewCell,
              config: [SRIndexPathConfigKey : Any] = [:]) -> ProfileDetailForm? {
        var paramValueType: JsonValueType = .string
        if let intValue = config[.paramValueType] as? Int,
            let enumInt = JsonValueType(rawValue: intValue) {
            paramValueType = enumInt
        }
        
        var isIgnored = false
        if let isIgnoreParamValue = config[.isIgnoreParamValue] as? Bool {
            isIgnored = isIgnoreParamValue
        }
        
        var isJsonValueValid = false
        var value: Any?
        let paramKey = config[.paramKey] as? String
        if paramKey != nil
            && profile.jsonValue(paramKey!, type: paramValueType, outValue: &value) {
            isJsonValueValid = true
        }
        
        //未编辑模式下，空数据没必要显示
        if !isIgnored && isJsonValueValid {
            if !NonNull.check(value) {
                isJsonValueValid = false
            } else { //根据不同的数据格式来判空
                switch paramValueType {
                case .string:
                    isJsonValueValid = !Common.isEmptyString(value)
                    
                case .number:
                    isJsonValueValid = (value as! NSNumber).doubleValue != 0
                    
                case .array:
                    isJsonValueValid = !(value as! [Any]).isEmpty
                    
                default:
                    break
                }
            }
        }
        
        if !isIgnored && !isJsonValueValid { //没读到参数或者读取的参数不可用，不需要显示
            return nil
        }
        
        var item = ProfileDetailForm()
        item.config = config
        item.cell = cell
        item.value = NonNull.check(value) ? value : nil
        item.isIgnoreParamValue = isIgnored
        item.paramValueType = paramValueType
        item.paramKey = paramKey
        item.paramValue = item.value
        
        //set subviews
        item.titleView = cell.contentView.viewWithTag(Const.titleViewTag)
        item.inputTextView = cell.contentView.viewWithTag(Const.inputTextViewTag)
        item.showTextView = cell.contentView.viewWithTag(Const.showTextViewTag)
        
        value = nil
        if config.jsonValue(configKey: .height, type: .number, outValue: &value),
            NonNull.check(value) {
            item.height = CGFloat((value as! NSNumber).floatValue)
        }
        
        if config.jsonValue(configKey: .width, type: .number, outValue: &value),
            NonNull.check(value) {
            item.width = CGFloat((value as! NSNumber).floatValue)
        }
        
        //修改标签文字
        if let label = item.titleView as? UILabel {
            if config.jsonValue(configKey: .title, type: .string, outValue: &value),
                NonNull.check(value) {
                label.text = value as? String
                label.font = Const.titleViewFont
            }
            item.title = label.text ?? EmptyString
        }
        
        updateInput(&item)
        updateTitleChoices(&item)
        
        lastSectionWillAdd = lastSection + 1
        lastRow += 1
        indexPathSet[IndexPath(row: lastRow, section: lastSectionWillAdd)] = item
        
        return item
    }
    
    //更新由键盘输入控件的item
    func updateInput(_ item: inout ProfileDetailForm) {
        guard let inputTextView = item.inputTextView,
            inputTextView.hasProperty(.text) else {
                return
        }
        
        let config = item.config
        var value: Any?
        if config.jsonValue(configKey: .inputText, type: .string, outValue: &value),
            NonNull.check(value) {
            item.inputText = value as! String
        }
        
        if config.jsonValue(configKey: .placeholder, type: .string, outValue: &value),
            NonNull.check(value) {
            item.placeholder = value as! String
        }
        inputTextView.setProperty(.text, value: item.showText)
        if inputTextView.hasProperty(.font) {
            inputTextView.setProperty(.font, value: Const.inputTextViewFont)
        }
        
        //Set delegate & notification
        if let textField = inputTextView as? UITextField {
            textField.delegate = self
            textField.textAlignment = .right
            NotifyDefault.add(self,
                              selector: #selector(textFieldEditingChanged(_:)),
                              name: .UITextFieldTextDidChange,
                              object: textField)
            if config.jsonValue(configKey: .placeholder, type: .string, outValue: &value),
                NonNull.check(value) {
                textField.placeholder = value as? String
            }
        } else if let textView = inputTextView as? UITextView {
            textView.delegate = self
            NotifyDefault.add(self,
                              selector: #selector(textViewEditingChanged(_:)),
                              name: .UITextFieldTextDidChange,
                              object: textView)
        }
        
        if config.jsonValue(configKey: .showText, type: .string, outValue: &value),
            NonNull.check(value) {
            item.showText = value as! String
        }
        
        //提供默认的显示文字
        if let showTextView = item.showTextView, showTextView.hasProperty(.text) {
            showTextView.setProperty(.text, value: item.showText)
            if showTextView.hasProperty(.font) {
                showTextView.setProperty(.font, value: Const.inputTextViewFont)
            }
            
            if let label = showTextView as? UILabel {
                label.textAlignment = .right
                label.adjustsFontSizeToFitWidth = true
            }
        }
        
        if config.jsonValue(configKey: .isRequired, type: .bool, outValue: &value),
            NonNull.check(value) {
            item.isRequired = value as! Bool
        }
        
        if config.jsonValue(configKey: .inputRegex, type: .string, outValue: &value),
            NonNull.check(value) {
            item.inputRegex = value as? String
        }
        
        if config.jsonValue(configKey: .textRegex, type: .string, outValue: &value),
            NonNull.check(value) {
            item.textRegex = value as? String
        }
        
        if config.jsonValue(configKey: .textRegexDescription, type: .string, outValue: &value),
            NonNull.check(value) {
            item.textRegexDescription = value as? String
        }
        
        if config.jsonValue(configKey: .textMaxLength, type: .number, outValue: &value),
            NonNull.check(value) {
            item.textMaxLength = (value as! NSNumber).intValue
        }
    }
    
    //更新点击后跳转选择页面的item
    func updateTitleChoices(_ item: inout ProfileDetailForm) {
        let config = item.config
        var value: Any?
        if config.jsonValue(configKey: .titleChoices, type: .array, outValue: &value),
            NonNull.check(value) {
            item.titleChoices = value as? [TitleChoiceModel]
        } else {
            return
        }
        
        if config.jsonValue(configKey: .isMultiple, type: .bool, outValue: &value),
            NonNull.check(value) {
            item.isMultiple = value as! Bool
        }
        
        if config.jsonValue(configKey: .isShowSelectAll, type: .bool, outValue: &value),
            NonNull.check(value) {
            item.isShowSelectAll = value as! Bool
        }
        
        item.showText = item.selectedChoicesTitle!
        item.showTextView?.setProperty(.text, value: item.showText)
    }
    
    func resetSignatureHeight() {
        guard let item = indexPathSet[signatureCell] as? ProfileDetailForm,
            let label = item.showTextView as? UILabel else {
                return
        }
        
        let height = Common.fitSize(item.showText, font: label.font, maxWidth: label.width).height
        item.height = max(TableCellHeight, ceil(height) + 2.0 * Const.signatureMargin)
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        if pickerView != nil && pickerView.superview != nil {
            pickerView.frame = pickerView.superview!.bounds
        }
        if popover != nil {
            popover!.dismiss()
        }
        resetSignatureHeight()
        tableView.reloadData()
        layoutFaceImage()
    }
    
    //MARK: - 业务处理
    
    func pageBack() {
        if !isEditingProfile {
            popBack()
            return
        }
        
        Keyboard.hide {
            let alert = SRAlert()
            alert.addButton("Exit".localized,
                            backgroundColor: NavigartionBar.backgroundColor,
                            action:
                { [weak self] in
                    self?.popBack()
            })
            alert.show(.notice,
                       title: "Are you sure?".localized,
                       message: "Profile items data cannot be saved!".localized,
                       closeButtonTitle: "Cancel".localized)
        }
    }
    
    func getProfileDetail() {
        //httpReq(.get(.profileDetail))
        httpRequest(.get(.profileDetail), success: { response in
            self.isFirstDidLoadSuccess = true
            self.dismissProgress()
            if let dictionary =
                (response as? JSON)?[HttpKey.Response.data].rawValue as? ParamDictionary {
                self.profile = dictionary
                self.initSections()
                self.tableView.reloadData()
            }
        }, bfail: { response in
            let message = self.logBFail(.get(.profileDetail), response: response, show: false)
            if !Common.isEmptyString(message) {
                Common.showToast(message)
            }
        })
    }
    
    func checkEmpty() -> Bool {
        for item in indexPathSet.sorted {
            guard let item = item as? ProfileDetailForm, item.isRequired else {
                continue
            }
            
            var isEmpty = false
            if !NonNull.check(item.value) {
                isEmpty = true
            } else {
                switch item.paramValueType {
                case .string:
                    isEmpty = (item.value as! String).isEmpty
                    
                case .array:
                    isEmpty = (item.value as! [Any]).isEmpty
                    
                default:
                    break
                }
            }
            
            if isEmpty {
                Common.showToast(String(format: "%@ can not be empty!".localized, item.title))
                return true
            }
        }
        return false
    }
    
    func checkInvalid() -> Bool {
        for item in indexPathSet.sorted {
            guard let item = item as? ProfileDetailForm, NonNull.check(item.value) else {
                continue
            }
            
            var isInvalid = false
            var invalidAlert = String(format: "Please enter the correct %@!".localized, item.title)
            switch item.paramValueType {
            case .string:
                if !Common.isEmptyString(item.textRegex)
                    && (item.value as! String).regex(item.textRegex!) { //不匹配正则表达式
                    isInvalid = true
                    if !Common.isEmptyString(item.textRegexDescription) { //自定义的描述，比如“密码只能输入6-20的字母、数字和特定符号的组合”
                        invalidAlert = item.textRegexDescription!
                    }
                }
                
            case .number:
                let number = item.value as! NSNumber
                let cell = item.cell
                if cell === heightCell
                    || cell === weightCell
                    || cell === dickLengthCell
                    || cell === fuckDurationCell
                    || cell === houseAreaCell
                    || cell === bustCell
                    || cell === waistlineCell
                    || cell === hiplineCell
                    || cell === annualIncomeCell { //一旦有输入，就必须大于0
                    isInvalid = number.doubleValue <= 0
                }
                
            default:
                break
            }
            
            if isInvalid {
                Common.showToast(invalidAlert)
                return true
            }
        }
        return false
    }
    
    func saveProfileDetail() {
        //准备提交参数
        var profile = editingProfile
        indexPathSet.enumerated.forEach {
            if let item = $0.element as? ProfileDetailForm, let paramKey = item.paramKey {
                //adapter enum -> bool
                if item.cell === transvestismCell {
                    if let enumInt = item.value as? EnumInt {
                        item.value = enumInt == IntForBool.True.rawValue
                    } else if let array = item.value as? [EnumInt], array.count > 0 {
                        item.value = array.first! == IntForBool.True.rawValue
                    } else {
                        item.value = nil
                    }
                }
                profile[paramKey] = NonNull.check(item.value) ? item.value : NSNull() //key存在，value为空，在json中对应的是{key: null}
            }
        }
        
        //头像图片被修改了
        if let headPortraitURL = headPortraitURL, headPortraitURL.scheme == "file" {
            //若使用第三方文件服务器，(国内)如阿里云oss，七牛
            //先使用第三方的sdk将图片上传到文件服务器，然后再将返回的文件url更新头像url再提交post请求
            //阿里云oss上传文件接口参考：
            //https://help.aliyun.com/document_detail/32060.html?spm=5176.doc32055.6.702.T2b5vp
            //七牛上传文件接口参考：
            //https://developer.qiniu.com/kodo/manual/1234/upload-types
            
            //若有自己的图片文件服务器，将图片转成Base64码，使用新的key放到post请求的参数：
            //let directory = Common.currentProfile()!.directory(.upload)!
            //let filePath = directory.appending(pathComponent: Const.editedHeadPortraitFileName)
            //let image = UIImage(contentsOfFile: filePath)
            //let data = UIImagePNGRepresentation(image!)
            //profile[ParamKey.headPortraitImage] = data!.base64EncodedData()
        }
        
        //httpReq(.post(.profileDetail), profile, nil)
        httpRequest(.post(.profileDetail),
                    profile,
                    success:
            { response in
                Common.showToast("Submit successfully".localized)
                self.dismissProgress()
                if let dictionary =
                    (response as? JSON)?[HttpKey.Response.data].rawValue as? ParamDictionary {
                    self.profile = dictionary
                    self.isEditingProfile = false
                    self.pageBackGestureStyle = .page
                    self.initSections()
                    self.tableView.reloadData()
                    self.setNavigationBarRightButtonItems()
                }
        })
    }
    
    func updateHeadPortraitImage() {
        let alert = SRAlertController(title: "Update head portrait".localized,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take photo".localized,
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    let vc = UIImagePickerController()
                    vc.allowsEditing = true
                    vc.sourceType = .camera
                    vc.delegate = self
                    self?.present(vc, animated: true, completion: nil)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo album".localized,
                                          style: .default,
                                          handler:
                { [weak self] (action) in
                    let vc = UIImagePickerController()
                    vc.allowsEditing = true
                    vc.sourceType = .photoLibrary
                    vc.delegate = self
                    self?.present(vc, animated: true, completion: nil)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler:nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showTitleChoicesVC(_ item: ProfileDetailForm) {
        currentItem = item
        let vc = Common.viewController("TitleChoicesViewController",
                                       storyboard: "Utility") as! TitleChoicesViewController
        vc.title = isEditingProfile ? String(format: "Select %@".localized, item.title) : item.title
        vc.titleChoices = item.titleChoicesUpdatedIsSelected
        vc.isMultiple = item.isMultiple
        vc.isShowSelectAll = item.isShowSelectAll
        vc.isEditable = isEditingProfile
        vc.didSelectBlock = { [weak self] selectedTitleChoices in
            guard let strongSelf = self, let currentItem = strongSelf.currentItem else {
                return
            }
            
            let models = selectedTitleChoices ?? []
            var array = [] as [Int]
            models.forEach { array.append(Int($0.id!)!) }
            
            let item = currentItem
            //adapter
            if item.cell === strongSelf.genderCell {
                item.value = array.count == 0 ? NSNull() : array.first
                strongSelf.updateItemsByGender()
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.tableView.reloadRows(at: [
                        strongSelf.indexPathSet[strongSelf.dickLengthCell]!.indexPath,
                        strongSelf.indexPathSet[strongSelf.fuckDurationCell]!.indexPath,
                        strongSelf.indexPathSet[strongSelf.houseAreaCell]!.indexPath,
                        strongSelf.indexPathSet[strongSelf.bustCell]!.indexPath,
                        strongSelf.indexPathSet[strongSelf.waistlineCell]!.indexPath,
                        strongSelf.indexPathSet[strongSelf.hiplineCell]!.indexPath
                        ],
                                                    with: .automatic)
                    strongSelf.tableView.reloadData()
                }
            } else {
                item.value = array
            }
            item.showText = item.selectedChoicesTitle!
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        show(vc)
    }
    
    func popText(_ view: UIView?) {
        guard let view = view, let text = view.value(property: .text) as? String else {
            return
        }
        popover = SRPopover.show(text, forView: view)
    }
    
    //MARK: Picker
    
    func showDatePicker(_ item: ProfileDetailForm) {
        guard pickerView == nil || pickerView.superview == nil else {
            return
        }
        
        Keyboard.hide { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.currentItem = item
            let datePicker = SRDatePicker()
            datePicker.delegate = self
            if let string = strongSelf.currentItem?.value as? String,
                let date = string.date(DateFormat.full) {
                datePicker.currentDate = date
            }
            strongSelf.pickerView = datePicker
            datePicker.show()
        }
    }
    
    func showDivisionPicker(_ item: ProfileDetailForm) {
        guard pickerView == nil || pickerView.superview == nil else {
            return
        }
        
        Keyboard.hide { [weak self] in
            self?.currentItem = item
            let divisionPicker = SRDivisionPicker()
            divisionPicker.delegate = self
            let dictionary = NonNull.dictionary(item.value)
            var names = [] as [String]
            if let province = dictionary[ParamKey.province] as? String {
                names.append(province)
            }
            if let city = dictionary[ParamKey.city] as? String {
                names.append(city)
            }
            if let region = dictionary[ParamKey.region] as? String {
                names.append(region)
            }
            let divisions = Division.divisions(names: names)
            divisionPicker.currentDivisions = divisions.count != 0 ? divisions : Division.default
            self?.pickerView = divisionPicker
            divisionPicker.show()
        }
    }
    
    //MARK: Face value
    
    func testFaceValue() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            Common.showToast("Camera is not available".localized)
            return
        }
        
        let alert = SRAlertController(title: "Test your beauty level".localized,
                                      message: "Use the iPhone self-timer, then upload the photo to the Microsoft ice for color value identification, this operation is best under the Wifi".localized,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK".localized,
                                      style: .default,
                                      handler:
            { [weak self] (action) in
                let vc = UIImagePickerController()
                vc.allowsEditing = true
                vc.sourceType = .camera
                vc.delegate = self
                self?.present(vc, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler:nil))
        present(alert, animated: true, completion: nil)
    }
    
    func uploadFaceImage(_ image: UIImage) {
        guard let data = image.compressedJPGData(CGSize(1920.0, 1080.0),
                                                 maxLength: 200 * 1024) else {
                                                    return
        }
        
        //        httpReq(.post(.uploadFaceImage),
        //                [EmptyString : data.base64EncodedString()],
        //                url: "http://kan.msxiaobing.com/Api",
        //                encoding: CustomEncoding.default)
        httpRequest(.post(.uploadFaceImage),
                    [EmptyString : data.base64EncodedString()],
                    url: "http://kan.msxiaobing.com/Api",
                    encoding: CustomEncoding.default,
                    success:
            { response in
                self.dismissProgress()
                if let dictionary = (response as? JSON)?.rawValue as? ParamDictionary {
                    let host = NonNull.string(dictionary["Host"])
                    let url = NonNull.string(dictionary["Url"])
                    self.faceImageUrl = host + url
                    DispatchQueue.main.async {
                        self.showProgress()
                        if self.faceImageCookie == nil {
                            self.getFaceImageCookie()
                        } else {
                            self.faceImageAnalyze()
                        }
                    }
                }
        })
    }
    
    func getFaceImageCookie() {
        let url = try! "http://kan.msxiaobing.com/ImageGame/Portal?task=yanzhi".asURL()
        SessionManager.default.request(url).response(completionHandler: { [weak self] response in
            guard let strongSelf = self else { return }
            
            if let error = response.error {
                LogError(error.localizedDescription)
                strongSelf.dismissProgress()
                strongSelf.showToast(error.localizedDescription)
                return
            }
            
            let cookie = NonNull.string(response.response?.allHeaderFields["Set-Cookie"])
            var array = [] as [String]
            cookie.components(separatedBy: ";").forEach {
                let components = $0.components(separatedBy: "=")
                if components.count > 0 {
                    let first = components.first!
                    if "cpid" == first || "salt" == first {
                        array.append($0)
                    } else if components.count > 1 {
                        let components2 = first.components(separatedBy: ",")
                        if components2.count > 1 {
                            let second = components2[1].trim
                            if "cpid" == second || "salt" == second {
                                array.append(String(format: "%@=%@", second, components.last!))
                            }
                        }
                    }
                }
            }
            strongSelf.faceImageCookie = array.joined(separator: ";")
            strongSelf.showProgress()
            strongSelf.faceImageAnalyze()
        })
    }
    
    func faceImageAnalyze() {
        //        httpReq(.post(.faceImageAnalyze),
        //                ["MsgId" : String(long: CLong(Date().timeIntervalSince1970)) + "063",
        //                 "CreateTime" : String(long: CLong(Date().timeIntervalSince1970)),
        //                 "Content[imageUrl]" : faceImageUrl],
        //                url: "http://kan.msxiaobing.com/Api",
        //                encoding: URLEncoding.default,
        //                headers: ["Referer" : "https://kan.msxiaobing.com/ImageGame/Portal?task=yanzhi",
        //                          "Cookie" : faceImageCookie])
        httpRequest(.post(.faceImageAnalyze),
                    ["MsgId" : String(long: CLong(Date().timeIntervalSince1970)) + "063",
                     "CreateTime" : String(long: CLong(Date().timeIntervalSince1970)),
                     "Content[imageUrl]" : faceImageUrl],
                    url: "http://kan.msxiaobing.com/Api",
                    encoding: URLEncoding.default,
                    headers: ["Referer" : "https://kan.msxiaobing.com/ImageGame/Portal?task=yanzhi",
                              "Cookie" : faceImageCookie],
                    success:
            { response in
                self.dismissProgress()
                if let json = response as? JSON {
                    if let text = json["content"]["text"].string {
                        self.faceImageLabel.text = text
                        let range = (text as NSString).range(of: "[+-]?[\\d]+(\\.[\\d]+)?",
                                                             options: .regularExpression)
                        if range.location != NSNotFound {
                            let string = (text as NSString).substring(with: range)
                            self.currentItem?.value = NSDecimalNumber(string: string)
                            self.currentItem?.showText = string
                            self.currentItem?.showTextView?.setProperty(.text,
                                                                        value: self.currentItem?.showText)
                        }
                    }
                    if let imageUrl = json["content"]["imageUrl"].string {
                        self.faceImageView.sd_setImage(with: URL(string: imageUrl),
                                                       placeholderImage: self.faceImageView.image!,
                                                       options: [],
                                                       completed:
                            { (_, error, _, _) in
                                if error == nil {
                                    DispatchQueue.main.async { [weak self] in
                                        self?.layoutFaceImage()
                                    }
                                }
                        })
                    }
                }
        })
    }
    
    var isShowingFaceImage: Bool {
        return faceImageContainerView != nil && faceImageContainerView.superview == view
    }
    
    func showFaceImage(_ image: UIImage? = nil, text: String? = nil) {
        if isShowingFaceImage {
            return
        }
        
        if faceImageContainerView == nil {
            faceImageContainerView = UIView()
            faceImageContainerView.backgroundColor = UIColor(white: 0, alpha: MaskAlpha)
            faceImageContainerView.isUserInteractionEnabled = true
            let gr = UITapGestureRecognizer(target: self, action: #selector(hideFaceImage))
            faceImageContainerView.addGestureRecognizer(gr)
            
            faceImageView = UIImageView()
            faceImageContainerView.addSubview(faceImageView)
            
            faceImageLabel = UILabel()
            faceImageContainerView.addSubview(faceImageLabel)
            faceImageLabel.font = UIFont.system(18.0)
            faceImageLabel.textColor = UIColor.white
            faceImageLabel.textAlignment = .center
            faceImageLabel.adjustsFontSizeToFitWidth = true
        }
        
        if let image = image {
            faceImageView.image = image
        }
        if let text = text {
            faceImageLabel.text = text
        }
        
        view.addSubview(faceImageContainerView)
        layoutFaceImage()
        tableView.isScrollEnabled = false
    }
    
    @objc func hideFaceImage() {
        if isShowingFaceImage {
            faceImageContainerView.removeFromSuperview()
            tableView.isScrollEnabled = true
        }
    }
    
    func layoutFaceImage() {
        if !isShowingFaceImage {
            return
        }
        
        faceImageContainerView.frame = tableView.visibleContentRect
        var size = faceImageContainerView.frame.size
        if !Common.isEmptyString(faceImageLabel.text) {
            size.height = faceImageContainerView.height - LabelHeight
        }
        var imageSize: CGSize!
        if let image = faceImageView.image {
            imageSize = image.size
        } else {
            imageSize = CGSize(Common.screenSize().width, Common.screenSize().width)
        }
        faceImageView.frame = CGRect(0, 0, imageSize.fitSize(maxSize: size))
        faceImageView.center = CGPoint(size.width / 2.0, size.height / 2.0)
        if Common.isEmptyString(faceImageLabel.text) {
            faceImageLabel.isHidden = true
        } else {
            faceImageLabel.isHidden = false
            faceImageLabel.frame = CGRect(0, faceImageView.bottom, size.width, LabelHeight)
        }
    }
    
    func updateItemsByGender() {
        var gender: UserModel.Gender?
        if let item = indexPathSet[genderCell] as? ProfileDetailForm,
            NonNull.check(item.value) {
            gender = item.value as! EnumInt == UserModel.Gender.male.rawValue ? .male : .female
        }
        if let item = indexPathSet[dickLengthCell] as? ProfileDetailForm {
            item.height = gender == .male ? TableCellHeight : 0
        }
        if let item = indexPathSet[fuckDurationCell] as? ProfileDetailForm {
            item.height = gender == .male ? TableCellHeight : 0
        }
        if let item = indexPathSet[houseAreaCell] as? ProfileDetailForm {
            item.height = gender == .male ? TableCellHeight : 0
        }
        if let item = indexPathSet[bustCell] as? ProfileDetailForm {
            item.height = gender == .female ? TableCellHeight : 0
        }
        if let item = indexPathSet[waistlineCell] as? ProfileDetailForm {
            item.height = gender == .female ? TableCellHeight : 0
        }
        if let item = indexPathSet[hiplineCell] as? ProfileDetailForm {
            item.height = gender == .female ? TableCellHeight : 0
        }
    }
    
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        
        guard isFirstDidLoadSuccess && !isShowingProgress else {
            return
        }
        
        if !isEditingProfile {
            isEditingProfile = true
            pageBackGestureStyle = .none
            initSections()
            tableView.reloadData()
            setNavigationBarRightButtonItems()
        } else {
            if checkEmpty() || checkInvalid() {
                return
            }
            tableView.isUserInteractionEnabled = false
            Keyboard.hide({ [weak self] in
                self?.tableView.isUserInteractionEnabled = true
                self?.showProgress()
                self?.saveProfileDetail()
            })
        }
    }
    
    //最大长度的限制
    @objc func textFieldEditingChanged(_ notification: Notification?) {
        guard let currentItem = currentItem, currentItem.textMaxLength > 0 else {
            return
        }
        
        let textMaxLength = currentItem.textMaxLength
        let textField = notification?.object as! UITextField
        let lang = textField.textInputMode?.primaryLanguage; // 键盘输入模式
        if "zh-Hans" == lang { //解决拼音字母多于汉字的问题
            //获取高亮部分
            var position: UITextPosition?
            if let selectedRange = textField.markedTextRange {
                position = textField.position(from: selectedRange.start, offset: 0)
            }
            // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
            if let text = textField.text,
                position == nil
                    && textMaxLength > 0
                    && text.length > textMaxLength {
                textField.text = text.substring(from: 0, length: textMaxLength)
            }
        } else { // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if let text = textField.text {
                textField.text = text.substring(from: 0, length: textMaxLength)
            }
        }
    }
    
    //最大长度的限制
    @objc func textViewEditingChanged(_ notification: Notification?) {
        guard let currentItem = currentItem, currentItem.textMaxLength > 0 else {
            return
        }
        
        let textMaxLength = currentItem.textMaxLength
        let textView = notification?.object as! UITextView
        let lang = textView.textInputMode?.primaryLanguage; // 键盘输入模式
        if "zh-Hans" == lang { //解决拼音字母多于汉字的问题
            //获取高亮部分
            var position: UITextPosition?
            if let selectedRange = textView.markedTextRange {
                position = textView.position(from: selectedRange.start, offset: 0)
            }
            // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
            if let text = textView.text,
                position == nil
                    && textMaxLength > 0
                    && text.length > textMaxLength {
                textView.text = text.substring(from: 0, length: textMaxLength)
            }
        } else { // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if let text = textView.text {
                textView.text = text.substring(from: 0, length: textMaxLength)
            }
        }
    }
    
    @IBAction func clickHeadPortraitImageView(_ sender: Any) {
        /*
         let photoBrowser: MWPhotoBrowser = MWPhotoBrowser(delegate: self)
         photoBrowser.displayActionButton = false
         photoBrowser.displayNavArrows = false
         photoBrowser.displaySelectionButtons = false
         photoBrowser.alwaysShowControls = false
         photoBrowser.zoomPhotosToFill = true
         photoBrowser.enableGrid = false
         photoBrowser.startOnGrid = false
         photoBrowser.enableSwipeToDismiss = true
         photoBrowser.modalTransitionStyle = .crossDissolve
         photoBrowser.modalPresentationStyle = .popover
         photos = [MWPhoto(url: headPortraitURL)]
         self.photoBrowser = photoBrowser
         navigationController?.present(photoBrowser, animated: true, completion: { [weak self] in
         var pagingScrollView: UIScrollView?
         for view in (self?.photoBrowser?.view.subviews)! {
         if view is UIScrollView {
         pagingScrollView = view as? UIScrollView
         break
         }
         }
         
         if pagingScrollView != nil {
         //添加消失的手势
         if self?.photoBrowserGR == nil {
         self?.photoBrowserGR =
         UITapGestureRecognizer(target: self,
         action: #selector(self?.clickPhotoBrowser))
         }
         pagingScrollView?.addGestureRecognizer((self?.photoBrowserGR!)!)
         }
         })
         */
    }
    
    @IBAction func cleanHeadPortrait(_ sender: Any) {
        let item = indexPathSet[headPortraitCell] as! ProfileDetailForm
        let url = URL(string: item.value as? String ?? EmptyString)
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Resource.defaultImage(.normal))
        headPortraitURL = url
        headPortraitTrailingConstraint.constant = 0
        cleanHeadPortraitButton.isHidden = true
    }
    
    func clickPhotoBrowser() {
        //guard Common.mutexTouch() else { return }
        //photoBrowser?.dismiss(animated: true) { [weak self] in
        //    self?.photoBrowser = nil
        //}
    }
}

/*
 //MARK: - MWPhotoBrowserDelegate
 
 extension ProfileDetailViewController: MWPhotoBrowserDelegate {
 func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
 return UInt((photos.count))
 }
 
 func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
 if Int(index) < photos.count {
 return photos[Int(index)]
 }
 return nil
 }
 }
 */

//MARK: - UIImagePickerControllerDelegate

extension ProfileDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerEditedImage] as! UIImage //获取裁剪过的图像
        if headPortraitCell == currentItem?.cell {
            let size = Const.headPortraitSize
            let cropImage = image.cropped(size.width / size.height) //继续按定制比例裁剪
            let resizedImage = cropImage.resized(size) //再按尺寸缩放
            let data = UIImagePNGRepresentation(resizedImage)
            let directory = Common.currentProfile()!.directory(.upload)!
            let filePath = directory.appending(pathComponent: Const.editedHeadPortraitFileName)
            let url = URL(fileURLWithPath: filePath) //保存到缓存图片
            do {
                try data?.write(to: url)
            } catch {
                picker.dismiss(animated: true, completion: {
                    Common.showAlert(message: error.localizedDescription, type: .error)
                })
                return
            }
            SDImageCache.shared().removeImage(forKey: url.absoluteString) //删除缓存中的图片再刷新图片
            headPortraitImageView.sd_setImage(with: url,
                                              placeholderImage: Resource.defaultImage(.normal))
            headPortraitURL = url
            headPortraitTrailingConstraint.constant = headPortraitTopConstraint.constant
            cleanHeadPortraitButton.isHidden = false
            picker.dismiss(animated: true, completion: nil)
        } else if faceValueCell == currentItem?.cell {
            DispatchQueue.main.async { [weak self] in
                self?.showProgress()
                self?.uploadFaceImage(image)
            }
            picker.dismiss(animated: true, completion: nil)
            showFaceImage(image, text: EmptyString)
        }
    }
}

//MARK: - UITextFieldDelegate

extension ProfileDetailViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentItem = indexPathSet[textField] as? ProfileDetailForm
        textField.text = currentItem?.inputText
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let currentItem = currentItem else { return }
        
        let cell = currentItem.cell
        currentItem.inputText = textField.text ?? EmptyString //更新inputText
        
        //更新value
        switch currentItem.paramValueType {
        case .string:
            currentItem.value = textField.text ?? EmptyString
            
        case .number:
            if let text = textField.text, !text.isEmpty {
                currentItem.value = NSDecimalNumber(string: text)
            } else {
                currentItem.value = nil
            }
        default:
            break
        }
        
        //添加单位等调整显示文字的操作
        if cell === heightCell
            || cell === dickLengthCell
            || cell === bustCell
            || cell === waistlineCell
            || cell === hiplineCell {
            if let number = currentItem.value as? NSNumber {
                currentItem.inputText = number.stringValue
                textField.text = currentItem.inputText + "cm"
            }
        } else if cell === weightCell {
            if let number = currentItem.value as? NSNumber {
                currentItem.inputText = number.stringValue
                textField.text = currentItem.inputText + "kg"
            }
        } else if cell === fuckDurationCell {
            if let number = currentItem.value as? NSNumber {
                currentItem.inputText = number.stringValue
                textField.text = currentItem.inputText + "m"
            }
        } else if cell === houseAreaCell {
            if let number = currentItem.value as? NSNumber {
                currentItem.inputText = number.stringValue
                textField.text = currentItem.inputText + "㎡"
            }
        } else if cell === annualIncomeCell {
            if let number = currentItem.value as? NSNumber {
                currentItem.inputText = number.stringValue
                textField.text = currentItem.inputText.tenThousands(number.uintValue)
            }
        }
        
        textField.isEnabled = false
        self.currentItem = nil
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if string.length > 0 {
            if let currentItem = currentItem, !Common.isEmptyString(currentItem.inputRegex) {
                return string.regex(currentItem.inputRegex!)
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK: - UITextViewDelegate

extension ProfileDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        currentItem = indexPathSet[textView] as? ProfileDetailForm
        textView.text = currentItem?.inputText
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let currentItem = currentItem else { return }
        
        let cell = currentItem.cell
        currentItem.value = textView.text ?? EmptyString
        currentItem.inputText = textView.text ?? EmptyString //更新inputText
        if cell === signatureCell {
            textView.isHidden = true
            currentItem.showTextView?.isHidden = false
            currentItem.showText = currentItem.inputText
            currentItem.showTextView?.setProperty(.text, value: currentItem.showText)
            resetSignatureHeight()
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [self.indexPathSet[self.signatureCell]!.indexPath],
                                          with: .automatic)
                self.tableView.reloadData()
            }
        }
        
        textView.isEditable = false
        self.currentItem = nil
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text.length > 0 {
            if let currentItem = currentItem, !Common.isEmptyString(currentItem.inputRegex) {
                return text.regex(currentItem.inputRegex!)
            }
        }
        return true
    }
}

//MARK: - SRPickerViewDelegate

extension ProfileDetailViewController: SRPickerViewDelegate {
    func pickerView(didConfirm pickerView: SRPickerView) {
        guard let currentItem = currentItem else { return }
        
        if currentItem.cell === birthDateCell {
            let datePicker = pickerView as! SRDatePicker
            currentItem.value = String(date: datePicker.currentDate, format: DateFormat.full)
            currentItem.showText = String(date: datePicker.currentDate,
                                          format: DateFormat.localDate)
            currentItem.showTextView?.setProperty(.text, value: currentItem.showText)
        } else if currentItem.cell === nativePlaceCell
            || currentItem.cell === locationCell {
            let divisionPicker = pickerView as! SRDivisionPicker
            var text = EmptyString
            var dictionary = [:] as [String : String]
            divisionPicker.currentDivisions.forEach {
                text.append($0.name)
                switch $0.level {
                case .province:
                    dictionary[ParamKey.province] = $0.name
                case .city:
                    dictionary[ParamKey.city] = $0.name
                case .region:
                    dictionary[ParamKey.region] = $0.name
                }
            }
            currentItem.value = dictionary
            currentItem.showText = text
            currentItem.showTextView?.setProperty(.text, value: currentItem.showText)
        }
        
        self.currentItem = nil
    }
    
    func pickerView(didCancel pickerView: SRPickerView) {
        currentItem = nil
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ProfileDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? SectionHeaderTopHeight : SectionHeaderHeight / 2.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return lastSection + 1
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return section == lastSection ? SectionHeaderHeight : SectionHeaderHeight / 2.0
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = indexPathSet[indexPath] as? ProfileDetailForm {
            return item.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? ProfileDetailForm, let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        
        guard let item = indexPathSet[indexPath] as? ProfileDetailForm else {
            return
        }
        
        if item.cell === headPortraitCell { //点击头像所在的row
            if !isEditingProfile {
                clickHeadPortraitImageView(0) //查看大图
            } else {
                currentItem = indexPathSet[headPortraitCell] as? ProfileDetailForm
                updateHeadPortraitImage()
            }
        } else if item.cell === birthDateCell {
            if !isEditingProfile {
                popText(item.showTextView)
            } else {
                showDatePicker(item)
            }
        } else if item.cell === nativePlaceCell
            || item.cell === locationCell {
            if !isEditingProfile {
                popText(item.showTextView)
            } else {
                showDivisionPicker(item)
            }
        } else if item.cell === faceValueCell {
            currentItem = indexPathSet[faceValueCell] as? ProfileDetailForm
            testFaceValue()
        } else if item.titleChoices != nil { //可选择的项
            showTitleChoicesVC(item)
        } else if let inputTextView = item.inputTextView  { //有可输入控件的项，并且
            if !isEditingProfile {
                if let showTextView = item.showTextView {
                    popText(showTextView)
                } else {
                    popText(inputTextView)
                }
            } else if !inputTextView.isFirstResponder { //输入控件不在编辑状态
                inputTextView.setProperty(.text, value: item.showText) //去掉多余的单位等文字
                if let textField = inputTextView as? UITextField {
                    textField.isEnabled = true
                    textField.becomeFirstResponder()
                } else if let textView = inputTextView as? UITextView {
                    textView.isEditable = true
                    textView.becomeFirstResponder()
                }
                
                if item.cell === signatureCell {
                    inputTextView.isHidden = false
                    item.showTextView?.isHidden = true
                }
            }
        } else {
            popText(item.showTextView)
        }
    }
}

public class CustomEncoding: ParameterEncoding {
    public static var `default`: CustomEncoding { return CustomEncoding() }
    
    public func encode(_ urlRequest: URLRequestConvertible,
                       with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        if let parameters = parameters {
            parameters.forEach {
                if let string = $0.value as? String {
                    request.httpBody = string.data(using: .utf8, allowLossyConversion: false)
                } else if let data = $0.value as? Data {
                    request.httpBody = data
                }
            }
        }
        return request
    }
}
