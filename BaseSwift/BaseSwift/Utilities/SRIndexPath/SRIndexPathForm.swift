//
//  SRIndexPathForm.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/3.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

//Like html form row
open class SRIndexPathForm: SRIndexPathTable {
    public weak var titleView: UIView? //左边标题控件
    public var title = EmptyString //左边标题控件的文字内容
    public weak var inputTextView: UIView? //右边内容的可输入控件，一般为UITextField或者UITextView
    public var inputText = EmptyString //右边输入控件的文字内容
    public var placeholder = EmptyString //右边输入控件的placeholder，仅限textField
    public weak var showTextView: UIView? //右边内容的只读控件，可以与inputTextView同为一个控件，也可以另为UILabel
    public var showText = EmptyString //右边只读控件的文字内容
    
    public var isRequired = false //字段值是否必填
    
    public var inputRegex: String? //右边输入控件通过键盘或粘贴时输入内容的正则表达式
    public var textRegex: String? //右边输入控件所有文字内容的正则表达式
    public var textRegexDescription: String? //右边输入控件最终文字内容的正则表达式的描述，用于出错时的提示
    public var textMaxLength = 0 //右边输入控件所有文字内容的最大长度，不大于0时表示无限制
}

public extension SRIndexPathConfigKey {
    public static let title: SRIndexPathConfigKey = SRIndexPathConfigKey("title")
    public static let inputText: SRIndexPathConfigKey = SRIndexPathConfigKey("inputText")
    public static let placeholder: SRIndexPathConfigKey = SRIndexPathConfigKey("placeholder")
    public static let showText: SRIndexPathConfigKey = SRIndexPathConfigKey("showText")
    public static let isRequired: SRIndexPathConfigKey = SRIndexPathConfigKey("isRequired")
    public static let value: SRIndexPathConfigKey = SRIndexPathConfigKey("value")
    public static let inputRegex: SRIndexPathConfigKey = SRIndexPathConfigKey("inputRegex")
    public static let textRegex: SRIndexPathConfigKey = SRIndexPathConfigKey("textRegex")
    public static let textRegexDescription: SRIndexPathConfigKey = SRIndexPathConfigKey("textRegexDescription")
    public static let textMaxLength: SRIndexPathConfigKey = SRIndexPathConfigKey("textMaxLength")
}

public extension SRIndexPathSet {
    
    //MARK: - 通过下标获取和设置
    
    func item(inputTextView: UIView) -> SRIndexPathForm? {
        return enumerated.first
            { inputTextView == ($0.element as? SRIndexPathForm)?.inputTextView }?.element
            as? SRIndexPathForm
    }
    
    func update(inputTextView: UIView, item: Any?) {
        guard let item = item as? SRIndexPathForm else {
            return
        }
        
        remove(self.item(inputTextView: inputTextView))
        item.inputTextView = inputTextView
        append(item)
    }
}
