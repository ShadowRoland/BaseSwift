//
//  SRDBMappable.swift
//  SRFramework
//
//  Created by Gary on 2020/8/18.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import ObjectMapper

public protocol SRDBMappable {
    var createTableSQL: String { get }
    var tableName: String { get }
}
