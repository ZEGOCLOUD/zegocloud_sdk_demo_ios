//
//  Array+Extension.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/10/31.
//

import Foundation

extension Array {
    func toJsonString() -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
}
