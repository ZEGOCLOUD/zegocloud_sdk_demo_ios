//
//  PKService+ExpressEventHandler.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/10/30.
//

import Foundation
import ZegoExpressEngine

extension PKService: ExpressServiceDelegate {
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .delete {
            if liveManager.hostUser?.id == nil && roomPKState == .isStartPK && liveManager.isLocalUserHost() {
                roomPKState = .isNoPK
                for delegate in eventDelegates.allObjects {
                    delegate.onPKEnded?()
                    delegate.onStopPlayMixerStream?()
                }
                destoryTimer()
            }
        }
    }
    
    func onPlayerRecvAudioFirstFrame(_ streamID: String) {
        if streamID.contains("_mix") {
            muteMainStream()
            for delegate in eventDelegates.allObjects {
                delegate.onPKViewAvaliable?()
            }
        }
    }
    
    func onPlayerRecvVideoFirstFrame(_ streamID: String) {
        if streamID.contains("_mix") {
            muteMainStream()
            for delegate in eventDelegates.allObjects {
                delegate.onPKViewAvaliable?()
            }
        }
    }
    
    func muteMainStream() {
        ZegoSDKManager.shared.expressService.streamDict.forEach { (key, value) in
            if key.hasPrefix("_host") {
                ZegoSDKManager.shared.expressService.mutePlayStreamAudio(streamID: key, mute: true)
                ZegoSDKManager.shared.expressService.mutePlayStreamVideo(streamID: key, mute: true)
            }
        }
    }
    
    func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        if let dataString = String(data: data, encoding: .utf8) {
            var seiData = dataString.toDict
            seiTimeDict.updateValue(Int(Date().timeIntervalSince1970 * 1000), forKey: "time")
            let key = seiData?["sender_id"] as? String ?? ""
            let isMicOpen: Bool = seiData?["mic"] as? Bool ?? false
            let isCameraOpen: Bool = seiData?["cam"] as? Bool ?? false
            
            if let pkInfo = pkInfo,
               let pkUser = getPKUser(pkBattleInfo: pkInfo, userID: key)
            {
                let micChanged: Bool = pkUser.microphone != isMicOpen
                let camChanged: Bool = pkUser.camera != isCameraOpen
                if micChanged {
                    pkUser.microphone = isMicOpen
                    for delegate in eventDelegates.allObjects {
                        delegate.onPKUserMicrophoneOpen?(userID: pkUser.userID, isMicOpen: isMicOpen)
                    }
                }
                if camChanged {
                    pkUser.camera = isCameraOpen
                    for delegate in eventDelegates.allObjects {
                        delegate.onPKUserCameraOpen?(userID: pkUser.userID, isCameraOpen: isCameraOpen)
                    }
                }
            }
        }
    }
    
    func isPKBusiness(type: Int) -> Bool {
        if type == PKProtocolType.startPK.rawValue || type == PKProtocolType.resume.rawValue || type == PKProtocolType.endPK.rawValue {
            return true
        }
        return false
    }
    
}
