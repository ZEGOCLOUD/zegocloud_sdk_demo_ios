//
//  ExpressService+Stream.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    public func startPreview(_ renderView: UIView,
                             viewMode: ZegoViewMode = .aspectFill) {
        let canvas = ZegoCanvas(view: renderView)
        canvas.viewMode = viewMode
        ZegoExpressEngine.shared().startPreview(canvas)
    }
    
    public func stopPreview() {
        ZegoExpressEngine.shared().stopPreview()
    }
    
    public func startPublishingStream(_ streamID: String, channel: ZegoPublishChannel = .main) {
        currentUser?.streamID = streamID
        streamDict[streamID] = currentUser?.id
        
        ZegoExpressEngine.shared().startPublishingStream(streamID)
        if let localUser = currentUser {
            setCameraAndMicState(isCameraOpen: localUser.isCameraOpen,
                                 isMicOpen: localUser.isMicrophoneOpen)
        }
    }
    
    public func stopPublishingStream(channel: ZegoPublishChannel? = nil) {
        if let channel = channel {
            ZegoExpressEngine.shared().stopPublishingStream(channel)
        } else {
            ZegoExpressEngine.shared().stopPublishingStream()
        }
        ZegoExpressEngine.shared().stopPreview()
    }
    
    public func startPlayingStream(_ renderView: UIView?,
                                   streamID: String,
                                   config: ZegoPlayerConfig = ZegoPlayerConfig(),
                                   viewMode: ZegoViewMode = .aspectFill) {
        if currentScenario == .highQualityChatroom || currentScenario == .highQualityVideoCall || currentScenario == .standardVideoCall || currentScenario == .standardVoiceCall || currentScenario == .standardChatroom {
            config.resourceMode = .onlyRTC
        }
        if let renderView = renderView {
            let canvas = ZegoCanvas(view: renderView)
            canvas.viewMode = viewMode
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas, config: config)
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, config: config)
        }
    }
    
    public func stopPlayingStream(_ streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
    
    public func mutePlayStreamAudio(streamID: String, mute: Bool) {
        ZegoExpressEngine.shared().mutePlayStreamAudio(mute, streamID: streamID)
    }
    
    public func mutePlayStreamVideo(streamID: String, mute: Bool) {
        ZegoExpressEngine.shared().mutePlayStreamVideo(mute, streamID: streamID)
    }
    
    public func startSoundLevelMonitor(millisecond: UInt32 = 1000) {
        ZegoExpressEngine.shared().startSoundLevelMonitor(millisecond)
    }
    
    public func stopSoundLevelMonitor() {
        ZegoExpressEngine.shared().stopSoundLevelMonitor()
    }
}
