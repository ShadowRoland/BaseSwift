//
//  Data+SRExtension.swift
//  SRKitExample
//
//  Created by Gary on 2019/5/6.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit
import SwiftyJSON

public extension Data {
    init?(jsonObject: Any?) {
        guard let jsonObject = jsonObject else { return nil }
        
        var data: Data?
        do {
            try data = JSON(jsonObject).rawData()
        } catch {
            LogError(String(format: "JSON object to data by SwiftyJSON failed! \nError: %@\nJSON object: %@",
                            error.localizedDescription,
                            jsonObject as? CVarArg ?? ""))
            return nil
        }
        
        self.init(referencing: data! as NSData)
    }
}
