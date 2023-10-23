//
//  ExpressService+SEI.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/6/9.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    public func sendSEI(_ data: String) {
        if let seiData = data.data(using: .utf8) {
            ZegoExpressEngine.shared().sendSEI(seiData)
        }
    }
    
}
