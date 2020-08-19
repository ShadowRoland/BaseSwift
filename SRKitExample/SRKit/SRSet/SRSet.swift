//
//  SRSet.swift
//  SRKit
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit

open class SRSet {
    public init(_ element: SRElement? = nil) {
        if let element = element {
            SRSet.appendElement(element, set: &set)
        }
    }
    
    public init(elements: [SRElement]?) {
        if let elements = elements {
            elements.forEach { SRSet.appendElement($0, set: &set) }
        }
    }
    
    fileprivate var set = [] as [SRElement]
    
    public func contains(_ element: SRElement) -> Bool {
        if let elements = element.elements {
            var set = [] as [SRElement]
            elements.forEach { SRSet.appendElement($0, set: &set) }
            return SRSet.contains(elements: self.set, subElements: set)
        } else {
            return set.contains { $0 === element }
        }
    }
    
    public func contains(elements: [SRElement]) -> Bool {
        var set = [] as [SRElement]
        elements.forEach { SRSet.appendElement($0, set: &set) }
        return SRSet.contains(elements: self.set, subElements: set)
    }
    
    fileprivate class func appendElement(_ element: SRElement, set: inout [SRElement]) {
        if let elements = element.elements {
            elements.forEach { appendElement($0, set: &set) }
        } else {
            set.append(element)
        }
    }
    
    fileprivate class func contains(elements: [SRElement], subElements: [SRElement]) -> Bool {
        if (!elements.isEmpty && !subElements.isEmpty)
            && subElements.contains(where: { subElement -> Bool in
            !elements.contains { $0 === subElement }
        }) {
            return true
        } else {
            return false
        }
    }
}

open class SRElement {
    public init() {  }
    public init(elements: [SRElement]) {
        var set = [] as [SRElement]
        elements.forEach { SRSet.appendElement($0, set: &set) }
        if !set.isEmpty {
            self.elements = set
        }
    }
    fileprivate var elements: [SRElement]?
}
