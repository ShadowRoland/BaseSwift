//
//  ServerConfigViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/11.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

//仅用于调试
class ServerConfigViewController: BaseViewController {
    lazy var indexPathSet: SRIndexPath.Set = SRIndexPath.Set()
    var lastSection = -1
    var lastSectionWillAdd = -1
    var lastRow = -1
    weak var currentItem: SRIndexPath.Form?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var runEnvSC: UISegmentedControl!
    
    lazy var apiBaseUrlCell: UITableViewCell = tableCell("apiBaseUrlCell")
    lazy var httpsCerCell: UITableViewCell = tableCell("httpsCerCell")
    
    func tableCell(_ identifier: String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    var env: ParamDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        pageBackGestureStyle = .none
        setDefaultNavigationBar("Server Configuration".localized)
        initView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let inputTextViewTag = 100
    }
    
    func initView() {
        let gr = UISwipeGestureRecognizer.init(target: self, action: #selector(handleViewSwipe))
        gr.direction = .right
        view.addGestureRecognizer(gr)
        
        tableView.tableFooterView = UIView()
        
        let local = Env.local!
        let envs = local["envs"] as! [Any]
        var current = min(local["current"] as! Int, envs.count)
        current = min(current, runEnvSC.numberOfSegments - 2)
        env = current >= 0 ? envs[current] as! ParamDictionary : Env.shared.toJSON()
        runEnvSC.selectedSegmentIndex = current >= 0 ? current : runEnvSC.numberOfSegments - 1
        initCells()
        tableView.reloadData()
    }
    
    func initCells() {
        indexPathSet.removeAll()
        lastSection = -1
        lastSectionWillAdd = lastSection
        
        //Section 0
        lastRow = -1
        item(apiBaseUrlCell, config: [.title : "Api Base Url",
                                      .paramKey : "apiBaseUrl",
                                      .isRequired : true])
        item(httpsCerCell, config: [.title : "Https Client Certificate", .paramKey : "httpsCer"])
        
        lastSection = lastSectionWillAdd
    }
    
    @discardableResult
    func item(_ cell: UITableViewCell,
              config: [SRIndexPath.AttributedString.Key : Any] = [:]) -> SRIndexPath.Form? {
        var paramValueType: JsonValueType = .string
        if let intValue = config[.paramValueType] as? Int,
            let enumInt = JsonValueType(rawValue: intValue) {
            paramValueType = enumInt
        }
        
        var isIgnored = true
        if let isIgnoreParamValue = config[.isIgnoreParamValue] as? Bool {
            isIgnored = isIgnoreParamValue
        }
        
        var isJsonValueValid = false
        var value: Any?
        let paramKey = config[.paramKey] as? String
        if paramKey != nil
            && env.jsonValue(paramKey!, type: paramValueType, outValue: &value) {
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
                    isJsonValueValid = !(value as! [Any]).isEmpty
                    
                default:
                    break
                }
            }
        }
        
        if !isIgnored && !isJsonValueValid { //没读到参数或者读取的参数不可用，不需要显示
            return nil
        }
        
        var item = SRIndexPath.Form(cell: cell)
        item.config = config
        item.value = NonNull.check(value) ? value : nil
        item.isIgnoreParamValue = isIgnored
        item.paramValueType = paramValueType
        item.paramKey = paramKey
        item.paramValue = item.value
        
        //set subviews
        item.inputTextView = cell.contentView.viewWithTag(Const.inputTextViewTag)
        
        value = nil
        if config.jsonValue(configKey: .height, type: .number, outValue: &value),
            NonNull.check(value) {
            item.height = CGFloat(truncating: value as! NSNumber)
        }
        
        if config.jsonValue(configKey: .width, type: .number, outValue: &value),
            NonNull.check(value) {
            item.width = CGFloat(truncating: value as! NSNumber)
        }
        
        if config.jsonValue(configKey: .title, type: .string, outValue: &value),
            NonNull.check(value) {
            item.title = value as! String
        }
        
        updateInput(&item)
        
        lastSectionWillAdd = lastSection + 1 //确保section会自增
        lastRow += 1
        indexPathSet[IndexPath(row: lastRow, section: lastSectionWillAdd)] = item

        return item
    }
    
    //更新由键盘输入控件的item
    func updateInput(_ item: inout SRIndexPath.Form) {
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
        
        //Set delegate & notification
        if let textField = inputTextView as? UITextField {
            textField.delegate = self
            NotifyDefault.add(self,
                              selector: #selector(textFieldEditingChanged(_:)),
                              name: UITextField.textDidChangeNotification,
                              object: textField)
            if config.jsonValue(configKey: .placeholder,
                                type: .string,
                                outValue: &value),
                NonNull.check(value) {
                textField.placeholder = value as? String
            }
            textField.isEnabled = !isProduction
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
    
    var isProduction: Bool {
        return runEnvSC.selectedSegmentIndex == runEnvSC.numberOfSegments - 1
    }
    
    //MARK: - 业务处理
    
    func pageBack() {
        if !isProduction {
            if !checkEmpty() {
                return
            } else {
                saveEnv()
            }
        }
        popBack()
    }
    
    func checkEmpty() -> Bool {
        for item in indexPathSet.sorted {
            let item = item as! SRIndexPath.Form
            if !item.isRequired {
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
                SRAlert.showToast(String(format: "%@ can not be empty!".localized, item.title))
                return true
            }
        }
        return false
    }
    
    func saveEnv() {
        indexPathSet.enumerated.forEach {
            let item = $0.element as! SRIndexPath.Form
            //key存在，value为空，在json中对应的是{key: null}
            env[item.paramKey!] = NonNull.check(item.value) ? item.value : NSNull()
        }
        
        let index = runEnvSC.selectedSegmentIndex
        var local = Env.local!
        var envs = local["envs"] as! [Any]
        local["current"] = index
        envs[index] = env as Any
        UserStandard[USKey.env] = local
        Env.reload()
    }
    
    //MARK: - 事件响应
    
    @objc func handleViewSwipe() {
        pageBack()
    }
    
    @IBAction func runEnvChanged(_ sender: Any) {
        env = !isProduction
            ? (Env.local!["envs"] as! [Any])[runEnvSC.selectedSegmentIndex] as! ParamDictionary
            : Env.shared.toJSON()
        initCells()
        tableView.reloadData()
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
    
}

//MARK: - UITextFieldDelegate

extension ServerConfigViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentItem = indexPathSet[textField] as? SRIndexPath.Form
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let currentItem = currentItem else { return }
        
        if "apiBaseUrl" == currentItem.paramKey, let text = textField.text {
            let trim = text.trim
            if !trim.isEmpty && !trim.hasSuffix("http://") && !trim.hasSuffix("https://") {
                textField.text = "http://" + trim
            } else {
                textField.text = ""
            }
        }
        
        //更新value
        switch currentItem.paramValueType {
        case .string:
            currentItem.value = textField.text ?? ""
            
        case .number:
            if let text = textField.text, !text.isEmpty {
                currentItem.value = NSDecimalNumber(string: text)
            } else {
                currentItem.value = nil
            }
        default:
            break
        }
        
        self.currentItem = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var current: SRIndexPath.Form?
        var next: SRIndexPath.Form?
        for member in indexPathSet.sorted {
            let item = member as! SRIndexPath.Form
            if textField == item.inputTextView {
                if current == nil {
                    current = item
                } else if next == nil {
                    next = item
                    break
                }
            }
        }
        
        if next != nil {
            next?.inputTextView?.becomeFirstResponder()
        } else {
            pageBack()
        }
        
        return true
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ServerConfigViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return indexPathSet.numberOfSections
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = indexPathSet[indexPath] as? SRIndexPath.Form {
            return item.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? SRIndexPath.Form,
            let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
}
