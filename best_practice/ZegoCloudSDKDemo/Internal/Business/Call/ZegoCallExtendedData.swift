//
//  ZegoCallExtendedData.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/13.
//

import UIKit

class ZegoCallExtendedData: NSObject {
    
    var type: CallType?
    
    init(type: CallType?) {
        self.type = type
    }
    
    static func parse(extendedData: String) -> ZegoCallExtendedData? {
        let dict: [String: Any]? = extendedData.toDict
        if let dict = dict {
            if dict.keys.contains("type") {
                let type: Int = dict["type"] as! Int
                let data: ZegoCallExtendedData = ZegoCallExtendedData(type: CallType(rawValue: type))
                return data
            }
        }
        return nil
    }
    
    func toString() -> String? {
        var dict: [String: Any] = [:]
        dict["type"] = type?.rawValue
        return dict.jsonString
    }
}
