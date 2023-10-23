//
//  ExpressService+Device.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func useFrontCamera(_ isFrontFacing: Bool) {
        isUsingFrontCamera = isFrontFacing
        ZegoExpressEngine.shared().useFrontCamera(isFrontFacing)
    }
    
    public func setAudioRouteToSpeaker(defaultToSpeaker: Bool) {
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(defaultToSpeaker)
    }
    
    public func turnMicrophoneOn(_ isOn: Bool) {
        currentUser?.isMicrophoneOpen = isOn
        ZegoExpressEngine.shared().muteMicrophone(!isOn)
        
        if let localUser = currentUser {
            setCameraAndMicState(isCameraOpen: localUser.isCameraOpen,
                                 isMicOpen: isOn)
        }
        
        for delegate in eventHandlers.allObjects {
            delegate.onMicrophoneOpen?(currentUser?.id ?? "", isMicOpen: isOn)
        }
    }
    
    public func turnCameraOn(_ isOn: Bool) {
        currentUser?.isCameraOpen = isOn
        ZegoExpressEngine.shared().enableCamera(isOn)
        
        if let localUser = currentUser {
            setCameraAndMicState(isCameraOpen: isOn,
                                 isMicOpen: localUser.isMicrophoneOpen)
        }
        
        for delegate in eventHandlers.allObjects {
            delegate.onCameraOpen?(currentUser?.id ?? "", isCameraOpen: isOn)
        }
    }
        
    func setCameraAndMicState(isCameraOpen: Bool, isMicOpen: Bool) {
        let info = ["cam" : isCameraOpen, "mic": isMicOpen]
        let infoStr = info.jsonString
        ZegoExpressEngine.shared().setStreamExtraInfo(infoStr)
    }
}
