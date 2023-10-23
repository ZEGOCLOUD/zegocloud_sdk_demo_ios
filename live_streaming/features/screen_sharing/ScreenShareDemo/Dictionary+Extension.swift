//
//  Dictionary+ZGUIKit.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/10.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    
    var jsonString: String {
        do {
            let stringData = try JSONSerialization.data(withJSONObject: self as NSDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let string = String(data: stringData, encoding: String.Encoding.utf8){
                return string
            }
        } catch _ {
            
        }
        return ""
    }
    
    var jsonData: Data? {
        if (!JSONSerialization.isValidJSONObject(self)) {
            print("is not a valid json object")
            return nil
        }

        let data = try? JSONSerialization.data(withJSONObject: self, options: [])
        
        return data
    }
}

extension String {
    var toDict: [String: Any]? {
        let dict = try? JSONSerialization.jsonObject(with: data(using: .utf8)!) as? [String: Any]
        return dict
    }
}

extension Data {
    var toDict: [String: Any]? {
        let dict = try? JSONSerialization.jsonObject(with: self) as? [String: Any]
        return dict
    }
}
