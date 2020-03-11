//
//  ProfileViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import SDWebImage
import IDMPhotoBrowser

class ProfileForm: SRIndexPath.Form {
    var titleChoices: [TitleChoiceModel]? //可以选择项
    
    //获取已选择项的标题拼接
    var selectedChoicesTitle: String? {
        return titleChoices?.compactMap { model in
            selectedTitleChoiceIds.first { String(int: $0) == model.id } != nil ? model.title : nil
        }.joined(separator: ", ")
    }
    
    //获取titleChoices，每项标记了是否已被选中的
    var titleChoicesUpdatedIsSelected: [TitleChoiceModel] {
        guard let titleChoices = titleChoices else {
                return []
        }
        
        titleChoices.forEach { model in
            model.isSelected = selectedTitleChoiceIds.first { model.id == String(int: $0) } != nil
        }
        
        return titleChoices
    }
    
    var selectedTitleChoiceIds: [EnumInt] {
        //adapter for value
        var enumInts = [] as [EnumInt]
        if let array = value as? [EnumInt] {
            enumInts = array
        } else if let enumInt = value as? EnumInt {
            enumInts.append(enumInt)
        } else if let number = value as? NSNumber {
            enumInts.append(number.intValue)
        } else if let string = value as? String, let number = Int(string) {
            enumInts.append(number)
        }
        return enumInts
    }
}

extension SRIndexPath.AttributedString.Key {
    public static let titleChoices: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("titleChoices")
}

class ProfileViewController: BaseViewController {
    lazy var indexPathSet: SRIndexPath.Set = SRIndexPath.Set()
    var lastSection = -1
    var lastSectionWillAdd = -1
    var lastRow = -1
    weak var currentItem: ProfileForm?
    
    lazy var profile: ParamDictionary = ProfileManager.currentProfile?.toJSON() ?? [:]
    lazy var editingProfile: ParamDictionary = [:]
    
    lazy var genderChoices: [TitleChoiceModel] = TitleChoiceModel.choices(Param.Key.gender)!
    lazy var boolChoices: [TitleChoiceModel] = TitleChoiceModel.choices(Param.Key.bool)!
    
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
    lazy var locationCell: UITableViewCell = tableCell("locationCell")
    
    func tableCell(_ identifier: String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    var headPortraitURL: URL?
    
    var pickerView: SRPickerView!
    lazy var divisionPicker: SRDivisionPicker = {
        let picker = SRDivisionPicker()
//        let filePath = C.resourceDirectory.appending(pathComponent: "china_locations.json.zip")
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: filePath)).gunzipped()
//            picker.chinaLocations = try JSON(data: data).rawValue as? [String : String] ?? [:]
//        } catch {
//            LogError("Unzip and transfer china locations file failed: \(filePath), error.localizedDescription")
//        }
        picker.delegate = self
        return picker
    }()
    
    struct Const {
        static let titleViewTag = 100
        static let inputTextViewTag = 102
        static let showTextViewTag = 101
        static let imageViewTag = 103
        static let clearButtonTag = 104
        
        static let titleViewFont = C.Font.text
        static let inputTextViewFont = UIFont.system(13)
        static let showTextViewFont = inputTextViewFont
        
        static let nicknameMaxLength = 11
        static let signatureMaxLength = 100
        static let signatureMargin = 2.0 as CGFloat
        
        static let headPortraitCellHeight = 100.0 as CGFloat
        static let headPortraitSize = CGSize(1024.0, 1024.0)
        static let editedHeadPortraitFileName = "editedHeadPortrait.png"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDefaultNavigationBar("Profile".localized)
        navBarRightButtonOptions = [.text([.title("More".localized)])]
        
        tableView.tableFooterView = UIView()
        initSections()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 视图初始化
    
    func initSections() {
        indexPathSet.removeAll()
        lastSection = -1
        initBaseSection()
        initProfileSection()
    }
    
    func initBaseSection() {
        lastSectionWillAdd = lastSection
        lastRow = -1
        
        //在获取了基本的item后可以做一些adapter的工作
        if let item = item(headPortraitCell,
                           config: [.height : Const.headPortraitCellHeight,
                                    .paramKey : Param.Key.headPortrait,
                                    .isIgnoreParamValue : true]) {
            let url = URL(string: item.value as? String ?? "")
            headPortraitImageView.sd_setImage(with: url,
                                              placeholderImage: Config.Resource.defaultImage(.normal))
            headPortraitURL = url
            headPortraitTrailingConstraint.constant = 0
            cleanHeadPortraitButton.isHidden = true
        }
        
        if let item = item(nicknameCell,
                           config: [.paramKey : Param.Key.nickname,
                                    .textMaxLength : Const.nicknameMaxLength,
                                    .isIgnoreParamValue : true]) {
            item.inputText = item.value as? String ?? ""
            item.inputTextView?.setProperty(.text, value: item.inputText)
        }
        
        if let item = item(signatureCell,
                           config: [.paramKey : Param.Key.signature,
                                    .textMaxLength : Const.signatureMaxLength,
                                    .isIgnoreParamValue : true]) {
            item.inputText = item.value as? String ?? ""
            item.inputTextView?.setProperty(.text, value: item.inputText)
            item.showText = item.inputText
            let label = item.showTextView as! UILabel
            label.text = item.showText
            label.adjustsFontSizeToFitWidth = false
            resetSignatureHeight()
        }
        
        if let item = item(userNameCell,
                           config: [.paramKey : Param.Key.userName,
                                    .isIgnoreParamValue : true]) {
            item.showText = item.value as? String ?? ""
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(phoneCell,
                           config: [.paramKey : Param.Key.phone,
                                    .isIgnoreParamValue : true]) {
            var value: Any?
            if profile.jsonValue(Param.Key.countryCode, type: .number, outValue: &value),
                NonNull.check(value) {
                let phone = "+" + String(object: value as! NSNumber) + (item.value as! String)
                item.showText = phone
                item.showTextView?.setProperty(.text, value: item.showText)
            } else {
                item.showText = item.value as? String ?? ""
                item.showTextView?.setProperty(.text, value: item.showText)
            }
        }
        
        lastSection = lastSectionWillAdd
    }
    
    func initProfileSection() {
        lastSectionWillAdd = lastSection
        lastRow = -1
        
        if let item = item(genderCell,
                           config: [.paramKey : Param.Key.gender,
                                    .paramValueType : JsonValueType.enumInt.rawValue,
                                    .isIgnoreParamValue : true,
                                    .titleChoices : genderChoices]) {
            if !NonNull.check(item.value) {
                item.showText = "Hideyoshi".localized
                item.showTextView?.setProperty(.text, value: item.showText)
            }
        }
        
        if let item = item(birthDateCell,
                           config: [.paramKey : Param.Key.birthDate,
                                    .isRequired : true,
                                    .isIgnoreParamValue : true]) {
            var showText = ""
            if let string = item.value as? String, let date = string.date(C.DateFormat.full) {
                showText = String(date: date, format: C.DateFormat.localDate)
            }
            item.showText = showText
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        if let item = item(locationCell,
                           config: [.paramKey : Param.Key.location,
                                    .paramValueType : JsonValueType.dictionary.rawValue,
                                    .isRequired : true,
                                    .isIgnoreParamValue : true]) {
            let dictionary = NonNull.dictionary(item.value)
            var names = [] as [String]
            if let province = dictionary[Param.Key.province] as? String {
                names.append(province)
            }
            if let city = dictionary[Param.Key.city] as? String {
                names.append(city)
            }
            if let region = dictionary[Param.Key.region] as? String {
                names.append(region)
            }
            let divisions = SRDivision.divisions(names: names,
                                                 from: divisionPicker.provinces)
            var text = ""
            divisions.forEach { text.append($0.name) }
            item.showText = text
            item.showTextView?.setProperty(.text, value: item.showText)
        }
        
        lastSection = lastSectionWillAdd
    }
    
    func item(_ cell: UITableViewCell, config: [SRIndexPath.AttributedString.Key : Any] = [:]) -> ProfileForm? {
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
                    isJsonValueValid = !isEmptyString(value)
                    
                case .number:
                    isJsonValueValid = (value as! NSNumber).doubleValue != 0
                    
                case .array:
                    isJsonValueValid = !(value as! AnyArray).isEmpty
                    
                default:
                    break
                }
            }
        }
        
        if !isIgnored && !isJsonValueValid { //没读到参数或者读取的参数不可用，不需要显示
            return nil
        }
        
        var item = ProfileForm(cell: cell)
        item.config = config
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
            item.height = CGFloat(truncating: value as! NSNumber)
        }
        
        if config.jsonValue(configKey: .width, type: .number, outValue: &value),
            NonNull.check(value) {
            item.width = CGFloat(truncating: value as! NSNumber)
        }
        
        //修改标签文字
        if let label = item.titleView as? UILabel {
            if config.jsonValue(configKey: .title, type: .string, outValue: &value),
                NonNull.check(value) {
                label.text = value as? String
                label.font = Const.titleViewFont
            }
            item.title = label.text ?? ""
        }
        
        updateInput(&item)
        updateTitleChoices(&item)
        
        lastSectionWillAdd = lastSection + 1 //确保section会自增
        lastRow += 1
        indexPathSet[IndexPath(row: lastRow, section: lastSectionWillAdd)] = item
        
        return item
    }
    
    //更新由键盘输入控件的item
    func updateInput(_ item: inout ProfileForm) {
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
                              name: UITextField.textDidChangeNotification,
                              object: textField)
            if config.jsonValue(configKey: .placeholder, type: .string, outValue: &value),
                NonNull.check(value) {
                textField.placeholder = value as? String
            }
        } else if let textView = inputTextView as? UITextView {
            textView.delegate = self
            NotifyDefault.add(self,
                              selector: #selector(textViewEditingChanged(_:)),
                              name: UITextView.textDidChangeNotification,
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
        
        if config.jsonValue(configKey: .textRegexDescription,
                            type: .string,
                            outValue: &value),
            NonNull.check(value) {
            item.textRegexDescription = value as? String
        }
        
        if config.jsonValue(configKey: .textMaxLength, type: .number, outValue: &value),
            NonNull.check(value) {
            item.textMaxLength = (value as! NSNumber).intValue
        }
    }
    
    //更新点击后跳转选择页面的item
    func updateTitleChoices(_ item: inout ProfileForm) {
        let config = item.config
        var value: Any?
        if config.jsonValue(configKey: .titleChoices, type: .array, outValue: &value),
            NonNull.check(value) {
            item.titleChoices = value as? [TitleChoiceModel]
        } else {
            return
        }
        
        item.showText = item.selectedChoicesTitle!
        item.showTextView?.setProperty(.text, value: item.showText)
    }
    
    func resetSignatureHeight() {
        guard let item = indexPathSet[signatureCell] as? ProfileForm,
            let label = item.showTextView as? UILabel else {
                return
        }
        
        let height = item.showText.textSize(label.font, maxWidth: label.width).height
        item.height = max(C.tableCellHeight, ceil(height) + 2.0 * Const.signatureMargin)
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        if pickerView != nil && pickerView.superview != nil {
            pickerView.frame = pickerView.superview!.bounds
        }
        resetSignatureHeight()
        tableView.reloadData()
    }
    
    //MARK: - 业务处理
    
    func saveProfile() {
        //准备提交参数
        var profile = editingProfile
        indexPathSet.enumerated.forEach {
            if let item = $0.element as? ProfileForm, let paramKey = item.paramKey {
                profile[paramKey] = NonNull.check(item.value) ? item.value : NSNull()
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
            //let directory = ProfileManager.currentProfile()!.directory(.upload)!
            //let filePath = directory.appending(pathComponent: Const.editedHeadPortraitFileName)
            //let image = UIImage(contentsOfFile: filePath)
            //let data = UIImagePNGRepresentation(image!)
            //profile[Param.Key.headPortraitImage] = data!.base64EncodedData()
        }
        
        //        httpReq(.post(.profileDetail), profile, nil)
        httpRequest(.post("user/profileDetail"), success: { response in
            SRAlert.showToast("Submit successfully".localized)
            self.dismissProgress()
            self.profile = ProfileManager.currentProfile?.toJSON() ?? [:]
            self.initSections()
            self.tableView.reloadData()
        })
    }
    
    func updateHeadPortraitImage() {
        let alert = SRAlertController(title: "Update head portrait".localized,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take photo".localized, style: .default, handler: { [weak self] (action) in
                if let strongSelf = self {
                    let vc = UIImagePickerController()
                    vc.allowsEditing = true
                    vc.sourceType = .camera
                    vc.delegate = strongSelf
                    strongSelf.present(vc, animated: true, completion: nil)
                }
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo album".localized, style: .default, handler: { [weak self] (action) in
                if let strongSelf = self {
                    let vc = UIImagePickerController()
                    vc.allowsEditing = true
                    vc.sourceType = .photoLibrary
                    vc.delegate = strongSelf
                    strongSelf.present(vc, animated: true, completion: nil)
                }
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler:nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showTitleChoicesVC(_ item: ProfileForm) {
        currentItem = item
        let vc = UIViewController.viewController("TitleChoicesViewController",
                                       storyboard: "Utility") as! TitleChoicesViewController
        vc.title = String(format: "Select %@".localized, item.title)
        vc.titleChoices = item.titleChoicesUpdatedIsSelected
        vc.didSelectBlock = { selectedTitleChoices in
            let models = selectedTitleChoices ?? []
            var array = [] as [Int]
            models.forEach { array.append(Int($0.id!)!) }
            
            let item = self.currentItem!
            var isChanged = false
            //adapter
            if item.cell === self.genderCell {
                if array.isEmpty {
                    isChanged = NonNull.check(self.profile[item.paramKey!])
                    item.value = NSNull()
                } else {
                    if let intValue = self.profile[item.paramKey!] as? Int {
                        isChanged = array.first != intValue
                    } else {
                        isChanged = true
                    }
                    item.value = array.first
                }
            } else {
                if let intArray = self.profile[item.paramKey!] as? [Int] {
                    isChanged = array != intArray
                } else {
                    isChanged = true
                }
                item.value = array
            }
            item.showText = item.selectedChoicesTitle!
            item.showTextView?.setProperty(.text, value: item.showText)
            
            if isChanged {
                DispatchQueue.main.async {
                    self.showProgress()
                    self.saveProfile()
                }
            }
        }
        show(vc)
    }
    
    func showDatePicker(_ item: ProfileForm) {
        guard pickerView == nil || pickerView.superview == nil else {
            return
        }
        
        Keyboard.hide { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.currentItem = item
            let datePicker = SRDatePicker()
            datePicker.delegate = strongSelf
            if let string = strongSelf.currentItem?.value as? String,
                let date = string.date(C.DateFormat.full) {
                datePicker.currentDate = date
            }
            strongSelf.pickerView = datePicker
            datePicker.show()
        }
    }
    
    func showDivisionPicker(_ item: ProfileForm) {
        guard pickerView == nil || pickerView.superview == nil else {
            return
        }
        
        Keyboard.hide { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.currentItem = item
            let dictionary = NonNull.dictionary(item.value)
            var names = [] as [String]
            if let province = dictionary[Param.Key.province] as? String {
                names.append(province)
            }
            if let city = dictionary[Param.Key.city] as? String {
                names.append(city)
            }
            if let region = dictionary[Param.Key.region] as? String {
                names.append(region)
            }
            let divisions = SRDivision.divisions(names: names,
                                                 from: strongSelf.divisionPicker.provinces)
            strongSelf.divisionPicker.currentDivisions =
                !divisions.isEmpty ? divisions : strongSelf.divisionPicker.firstLocations
            strongSelf.pickerView = strongSelf.divisionPicker
            strongSelf.divisionPicker.show()
        }
    }
    
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        show("ProfileDetailViewController", storyboard: "Profile")
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
                    && text.count > textMaxLength {
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
                    && text.count > textMaxLength {
                textView.text = text.substring(from: 0, length: textMaxLength)
            }
        } else { // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if let text = textView.text {
                textView.text = text.substring(from: 0, length: textMaxLength)
            }
        }
    }
    
    @IBAction func clickHeadPortraitImageView(_ sender: Any) {
        guard MutexTouch,
            let url = headPortraitURL,
            let browser = IDMPhotoBrowser(photoURLs: [url]) else {
                return
        }
        
        browser.displayActionButton = false
        browser.displayArrowButton = false
        browser.displayCounterLabel = false
        browser.displayDoneButton = false
        browser.disableVerticalSwipe = true
        browser.dismissOnTouch = true
        navigationController?.present(browser, animated: true, completion: nil)
    }
    
    @objc func cleanHeadPortrait() {
        let item = indexPathSet[headPortraitCell] as! ProfileForm
        let url = URL(string: item.value as? String ?? "")
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Config.Resource.defaultImage(.normal))
        headPortraitURL = url
        headPortraitTrailingConstraint.constant = 0
        cleanHeadPortraitButton.isHidden = true
    }
}

//MARK: - UIImagePickerControllerDelegate

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage //获取裁剪过的图像
        let size = Const.headPortraitSize
        let cropImage = image.cropped(size.width / size.height) //继续按定制比例裁剪
        let resizedImage = cropImage.resized(size) //再按尺寸缩放
        let data = resizedImage.pngData()
        let directory = ProfileManager.currentProfile!.directory(.upload)!
        let filePath = directory.appending(pathComponent: Const.editedHeadPortraitFileName)
        let url = URL(fileURLWithPath: filePath) //保存到缓存图片
        do {
            try data?.write(to: url)
        } catch {
            picker.dismiss(animated: true, completion: {
                SRAlert.show(message: error.localizedDescription, type: .error)
            })
            return
        }
        SDImageCache.shared.removeImage(forKey: url.absoluteString) //删除缓存中的图片再刷新图片
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Config.Resource.defaultImage(.normal))
        headPortraitURL = url
        headPortraitTrailingConstraint.constant = headPortraitTopConstraint.constant
        cleanHeadPortraitButton.isHidden = false
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITextFieldDelegate

extension ProfileViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentItem = indexPathSet[textField] as? ProfileForm
        textField.text = currentItem?.inputText
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var isChanged = false
        currentItem?.inputText = textField.text ?? "" //更新inputText
        
        //更新value
        switch currentItem!.paramValueType {
        case .string:
            if let string = profile[(currentItem?.paramKey)!] as? String {
                isChanged = textField.text != string
            } else {
                isChanged = true
            }
            currentItem?.value = textField.text ?? ""
        default:
            break
        }
        
        textField.isEnabled = false
        currentItem = nil
        
        if isChanged {
            Keyboard.hide {
                self.showProgress()
                self.saveProfile()
            }
        }
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if !string.isEmpty,
            let currentItem = currentItem,
            !isEmptyString(currentItem.inputRegex) {
            return string.regex(currentItem.inputRegex!)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK: - UITextViewDelegate

extension ProfileViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        currentItem = indexPathSet[textView] as? ProfileForm
        textView.text = currentItem?.inputText
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let cell = currentItem!.cell
        currentItem?.value = textView.text ?? ""
        currentItem?.inputText = textView.text ?? "" //更新inputText
        if cell === signatureCell {
            textView.isHidden = true
            currentItem!.showTextView?.isHidden = false
            currentItem!.showText = currentItem!.inputText
            currentItem!.showTextView?.setProperty(.text, value: currentItem?.showText)
            resetSignatureHeight()
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [self.indexPathSet[self.signatureCell]!.indexPath],
                                          with: .automatic)
                self.tableView.reloadData()
            }
        }
        
        textView.isEditable = false
        
        var isChanged = false
        if let string = profile[(currentItem?.paramKey)!] as? String {
            isChanged = textView.text != string
        }
        currentItem = nil
        
        if isChanged {
            Keyboard.hide {
                self.showProgress()
                self.saveProfile()
            }
        }
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if !text.isEmpty,
            let currentItem = currentItem,
            !isEmptyString(currentItem.inputRegex) {
            return text.regex(currentItem.inputRegex!)
        }
        return true
    }
}

//MARK: - SRPickerViewDelegate

extension ProfileViewController: SRPickerViewDelegate {
    func pickerView(didConfirm pickerView: SRPickerView) {
        guard let currentItem = currentItem, let paramKey = currentItem.paramKey else {
            return
        }
        
        var isChanged = false
        if currentItem.cell === birthDateCell {
            let datePicker = pickerView as! SRDatePicker
            let newValue = String(date: datePicker.currentDate, format: C.DateFormat.full)
            if let string = profile[paramKey] as? String {
                isChanged = newValue != string
            } else {
                isChanged = true
            }
            currentItem.value = newValue
            currentItem.showText = String(date: datePicker.currentDate,
                                          format: C.DateFormat.localDate)
            currentItem.showTextView?.setProperty(.text, value: currentItem.showText)
        } else if currentItem.cell === locationCell {
            let divisionPicker = pickerView as! SRDivisionPicker
            var text = ""
            var dictionary = [:] as [String : String]
            divisionPicker.currentDivisions.forEach {
                let name = $0.name
                text.append(name)
                switch $0.level {
                case .province:
                    dictionary[Param.Key.province] = name
                case .city:
                    dictionary[Param.Key.city] = name
                case .region:
                    dictionary[Param.Key.region] = name
                }
            }
            
            if let params = profile[paramKey] as? ParamDictionary {
                isChanged = dictionary.first { $0.value != params[$0.key] as? String } == nil
            } else {
                isChanged = true
            }
            currentItem.value = dictionary
            currentItem.showText = text
            currentItem.showTextView?.setProperty(.text, value: currentItem.showText)
        }
        self.currentItem = nil
        
        if isChanged {
            showProgress()
            saveProfile()
        }
    }
    
    func pickerView(didCancel pickerView: SRPickerView) {
        currentItem = nil
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return indexPathSet.numberOfSections
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return section == lastSection ? C.sectionHeaderHeight : C.sectionHeaderHeight / 2.0
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = indexPathSet[indexPath] as? ProfileForm {
            return item.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? ProfileForm,
            let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        guard let item = indexPathSet[indexPath] as? ProfileForm else {
            return
        }
        
        if item.cell === headPortraitCell { //点击头像所在的row
            updateHeadPortraitImage()
        } else if item.cell === birthDateCell {
            showDatePicker(item)
        } else if item.cell === locationCell {
            showDivisionPicker(item)
        } else if item.titleChoices != nil { //可选择的项
            showTitleChoicesVC(item)
        } else if let inputTextView = item.inputTextView  { //有可输入控件的项，并且
            if !inputTextView.isFirstResponder { //输入控件不在编辑状态
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
        }
    }
}

