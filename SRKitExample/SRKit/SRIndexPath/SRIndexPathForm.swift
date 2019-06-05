//
//  SRIndexPath.Form.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

/// Like html form row
extension SRIndexPath {
    open class Form: SRIndexPath.Table {
        /// 左边标题控件
        open weak var titleView: UIView?
        /// 左边标题控件的文字内容
        open var title = ""
        /// 右边内容的可输入控件，一般为UITextField或者UITextView
        open weak var inputTextView: UIView?
        /// 右边输入控件的文字内容
        open var inputText = ""
        /// 右边输入控件的placeholder，仅限textField
        open var placeholder = ""
        /// 右边内容的只读控件，可以与inputTextView同为一个控件，也可以另为UILabel
        open weak var showTextView: UIView?
        /// 右边只读控件的文字内容
        open var showText = ""
        
        /// 字段值是否必填
        open var isRequired = false
        
        /// 右边输入控件通过键盘或粘贴时输入内容的正则表达式
        open var inputRegex: String?
        /// 右边输入控件所有文字内容的正则表达式
        open var textRegex: String?
        /// 右边输入控件最终文字内容的正则表达式的描述，用于出错时的提示
        open var textRegexDescription: String?
        /// 右边输入控件所有文字内容的最大长度，不大于0时表示无限制
        open var textMaxLength = 0
    }
}

public extension SRIndexPath.Set {
    
    //MARK: - 通过下标获取和设置
    
    func item(inputTextView: UIView) -> SRIndexPath.Form? {
        return enumerated.first
            { inputTextView == ($0.element as? SRIndexPath.Form)?.inputTextView }?.element
            as? SRIndexPath.Form
    }
    
    func update(inputTextView: UIView, item: Any?) {
        guard let item = item as? SRIndexPath.Form else {
            return
        }
        
        remove(self.item(inputTextView: inputTextView))
        item.inputTextView = inputTextView
        append(item)
    }
}

public extension SRIndexPath.AttributedString.Key {
    static let title: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("title")
    static let inputText: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("inputText")
    static let placeholder: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("placeholder")
    static let showText: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("showText")
    static let isRequired: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("isRequired")
    static let value: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("value")
    static let inputRegex: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("inputRegex")
    static let textRegex: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("textRegex")
    static let textRegexDescription: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("textRegexDescription")
    static let textMaxLength: SRIndexPath.AttributedString.Key = SRIndexPath.AttributedString.Key("textMaxLength")
}
