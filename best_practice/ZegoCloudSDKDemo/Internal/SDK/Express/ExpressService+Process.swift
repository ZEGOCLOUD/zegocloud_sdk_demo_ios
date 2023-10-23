//
//  ExpressService+Process.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/5/6.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func enableCustomVideoProcessing(_ enable: Bool,
                                            config: ZegoCustomVideoProcessConfig,
                                            channel: ZegoPublishChannel = .main) {
        ZegoExpressEngine.shared().enableCustomVideoProcessing(enable,
                                                               config: config,
                                                               channel: channel)
    }
    
    public func setCustomVideoProcessHandler(_ handler: ZegoCustomVideoProcessHandler) {
        ZegoExpressEngine.shared().setCustomVideoProcessHandler(handler)
    }
    
    public func sendCustomVideoProcessedCVPixelBuffer(_ buffer: CVPixelBuffer,
                                                      timestamp: CMTime,
                                                      channel: ZegoPublishChannel = .main) {
        ZegoExpressEngine.shared().sendCustomVideoProcessedCVPixelBuffer(buffer,
                                                                         timestamp: timestamp,
                                                                         channel: channel)
    }
    
    public func getVideoConfig() -> ZegoVideoConfig {
        ZegoExpressEngine.shared().getVideoConfig()
    }
}
