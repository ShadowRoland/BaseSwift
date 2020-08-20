//
//  SRNestedElement.swift
//  SRKit
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit

///一个可嵌套的元素，每个元素都可能包含了其他的元素，可包含的元素有可能出现交集
open class SRNestedElement {
    public init(_ element: SRNestedElement? = nil) {
        if let element = element {
            appendSubElement(element)
        }
    }
    
    public init(elements: [SRNestedElement]?) {
        if let elements = elements {
            elements.forEach { appendSubElement($0) }
        }
    }
    
    //subElements包含了所有最终没有子集的元素
    fileprivate var subElements: [SRNestedElement]?
    
    fileprivate func appendSubElement(_ element: SRNestedElement) {
        if let subElements = element.subElements {
            subElements.forEach { appendSubElement($0) }
        } else {
            if isNested {
                objc_sync_enter(subElements!)
                if !subElements!.contains(where: { $0 === element }) {
                    subElements!.append(element)
                }
                objc_sync_exit(subElements!)
            } else {
                subElements = [] as [SRNestedElement]
                subElements!.append(element)
            }
        }
    }
}

extension SRNestedElement {
    ///是否是嵌套的，如果不是嵌套则表示是自己就是最原子的元素，没有包含其他元素，可以被其他元素包含
    public var isNested: Bool {
        return subElements != nil
    }
    
    public func contains(_ element: SRNestedElement) -> Bool {
        if let subElements = element.subElements {
            if let subSubElements = element.subElements {
                return subSubElements.contains { e -> Bool in
                    !subElements.contains { $0 === e }
                }
            } else {
                return subElements.contains { $0 === element }
            }
        } else {
            return self === element
        }
    }
    
    public func contains(elements: [SRNestedElement]) -> Bool {
        return contains(SRNestedElement(elements: elements))
    }
    
    ///交集
    public func intersection(_ element: SRNestedElement) -> SRNestedElement? {
        if !isNested {
            return element.contains(self) ? self : nil
        } else if !element.isNested {
            return contains(element) ? element : nil
        } else {
            let elements = subElements!.filter { e in
                element.subElements!.contains { $0 === e }
            }
            return elements.count > 0 ? SRNestedElement(elements: elements) : nil
        }
    }
    
    ///并集
    public func union(_ element: SRNestedElement) -> SRNestedElement {
        if !isNested && element.contains(self) {
            return element
        } else if !element.isNested && contains(element) {
            return self
        } else {
            return SRNestedElement(elements: [self, element])
        }
    }
    
    public func drop(_ element: SRNestedElement) -> SRNestedElement? {
        if !isNested && !element.contains(self) {
            return self
        } else if !element.isNested && !contains(element) {
            return element
        } else {
            let elements = subElements!.drop { e in
                element.subElements!.contains { $0 === e }
            }
            return elements.count > 0 ? SRNestedElement(elements: Array(elements)) : nil
        }
    }
}

extension SRNestedElement: Equatable {
    ///左右所包含的所有原子元素相同则相等
    public static func == (lhs: SRNestedElement, rhs: SRNestedElement) -> Bool {
        if lhs === rhs {
            return true
        } else if !lhs.isNested {
            return lhs === rhs.subElements?.first
        } else if !rhs.isNested {
            return rhs === lhs.subElements?.first
        } else {
            return lhs.subElements!.contains { e -> Bool in
                !rhs.subElements!.contains { $0 === e }
            }
        }
    }
}
