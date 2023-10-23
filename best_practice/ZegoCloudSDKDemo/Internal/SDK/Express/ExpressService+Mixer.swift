//
//  ExpressService+Mixer.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/6/2.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    public func startMixerTask(_ task: ZegoMixerTask,
                               callback: ZegoMixerStartCallback?) {
        ZegoExpressEngine.shared().start(task, callback: callback)
    }
    
    func stopMixerTask(_ task: ZegoMixerTask, callback: ZegoMixerStopCallback?) {
        ZegoExpressEngine.shared().stop(task,callback: callback)
    }
    
    public func generateMixerStreamID() -> String {
        let roomID = currentRoomID ?? ""
        let mixerStreamID = roomID + "_mix"
        return mixerStreamID
    }
    
}
