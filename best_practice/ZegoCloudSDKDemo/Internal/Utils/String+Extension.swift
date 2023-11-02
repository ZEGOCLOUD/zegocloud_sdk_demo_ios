//
//  String+Extension.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/1.
//

import Foundation

extension String {
    
    func jsonArray() -> [Any]? {
        if let jsonData = self.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any] {
                    return jsonArray
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    var toDict: [String: Any]? {
        let dict = try? JSONSerialization.jsonObject(with: data(using: .utf8)!) as? [String: Any]
        return dict
    }
    
}
