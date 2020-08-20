//
//  SRDownloadItemTaskModel.swift
//  SRFramework
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import ObjectMapper

open class SRDownloadItemTaskModel: SRDownloadTaskModel {
    open var planStatus: Status = .default
    weak open var groupTask: SRDownloadGroupTaskModel?
    
    override public init() { super.init() }
    
    //MARK: - Mappable
    
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
    }
    
    //MARK: - SRDBModel
    
    open override func modelMapping(map: Map) -> SRDBModel {
        if let model = SRDownloadItemTaskModel(map: map) {
            return model
        } else {
            return SRDownloadItemTaskModel()
        }
    }
    
    private var _tableName = ""
    open override var tableName: String {
        get {
            return _tableName
        }
        set {
            _tableName = newValue
        }
    }
}
