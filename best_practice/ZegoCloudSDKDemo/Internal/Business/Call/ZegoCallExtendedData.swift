//
//  ZegoCallExtendedData.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/13.
//

import UIKit

class ZegoCallExtendedData: NSObject {
    
    var type: CallType?
    var userName: String?
    
    init(type: CallType?, userName: String? = nil) {
        self.type = type
        self.userName = userName
    }
    
    static func parse(extendedData: String) -> ZegoCallExtendedData? {
        let dict: [String: Any]? = extendedData.toDict
        if let dict = dict {
            if dict.keys.contains("type") {
                let type: Int = dict["type"] as! Int
                let data: ZegoCallExtendedData = ZegoCallExtendedData(type: CallType(rawValue: type), userName: dict["user_name"] as? String)
                return data
            }
        }
        return nil
    }
    
    func toString() -> String? {
        var dict: [String: Any] = [:]
        dict["user_name"] = userName
        dict["type"] = type?.rawValue
        return dict.jsonString
    }
}
