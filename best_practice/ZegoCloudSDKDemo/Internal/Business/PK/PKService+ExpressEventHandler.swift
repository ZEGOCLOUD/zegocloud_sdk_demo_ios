//
//  PKService+ExpressEventHandler.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/10/30.
//

import Foundation
import ZegoExpressEngine

extension PKService {
    
    func onReceiveStreamAdd(userList: [ZegoSDKUser]) {
        for user in userList {
            let mainStreamID = user.streamID
            if let mainStreamID = mainStreamID,
               mainStreamID.hasSuffix("_host")
            {
                if !pkRoomAttribute.isEmpty {
                    if let pkUsers = pkRoomAttribute["pk_users"],
                       !pkUsers.isEmpty
                    {
                        onReceivePKRoomAttribute(roomProperties: pkRoomAttribute)
                    }
                }
            }

        }
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .delete {
            if liveManager.hostUser?.id == nil && isPKStarted && liveManager.isLocalUserHost() {
                isPKStarted = false
                for delegate in eventDelegates.allObjects {
                    delegate.onPKEnded?()
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
            let seiData = dataString.toDict
            let key = seiData?["sender_id"] as? String ?? ""
            seiTimeDict.updateValue(Int(Date().timeIntervalSince1970 * 1000), forKey: key)
            let isMicOpen: Bool = seiData?["mic"] as? Bool ?? false
            let isCameraOpen: Bool = seiData?["cam"] as? Bool ?? false
            
            if let pkInfo = pkInfo,
               let pkUser = getPKUser(pkBattleInfo: pkInfo, userID: key)
            {
                let micChanged: Bool = pkUser.microphone != isMicOpen
                let camChanged: Bool = pkUser.camera != isCameraOpen
                if micChanged {
                    pkUser.microphone = isMicOpen
                    DispatchQueue.main.async {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onPKUserMicrophoneOpen?(userID: pkUser.userID, isMicOpen: isMicOpen)
                        }
                    }
                }
                if camChanged {
                    pkUser.camera = isCameraOpen
                    DispatchQueue.main.async {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onPKUserCameraOpen?(userID: pkUser.userID, isCameraOpen: isCameraOpen)
                        }
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
