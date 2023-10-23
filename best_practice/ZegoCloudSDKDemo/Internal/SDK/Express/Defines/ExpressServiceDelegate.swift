//
//  ExpressServiceDelegate.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

@objc public protocol ExpressServiceDelegate: ZegoEventHandler {
    @objc optional
    func onMicrophoneOpen(_ userID: String, isMicOpen: Bool)
    
    @objc optional
    func onCameraOpen(_ userID: String, isCameraOpen: Bool)
        
    @objc optional
    func onReceiveStreamAdd(userList: [ZegoSDKUser])

    @objc optional
    func onReceiveStreamRemove(userList: [ZegoSDKUser])
    
    @objc optional
    func onRoomExtraInfoUpdate2(_ roomExtraInfoList: [ZegoRoomExtraInfo], roomID: String)
}
