//
//  ExpressService+Room.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func loginRoom(_ roomID: String,
                         token: String? = nil,
                         callback: ZegoRoomLoginCallback?) {
        
        assert(currentUser != nil, "Must login first.")
        
        self.currentRoomID = roomID
        
        let userID = currentUser?.id ?? ""
        let userName = currentUser?.name ?? ""
        let user = ZegoUser(userID: userID, userName: userName)
                
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true
        if let token = token {
            config.token = token
        }
        
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config) { [weak self] error, data in
            if error == 0 {
                self?.inRoomUserDict[userID] = self?.currentUser
                // monitor sound level
                guard let callback = callback else { return }
                callback(error,data)
            } else {
                guard let callback = callback else { return }
                callback(error,data)
            }
        };

    }
    
    public func logoutRoom(callback: ZegoRoomLogoutCallback?) {
        currentRoomID = nil
        stopPublishingStream()
        inRoomUserDict.removeAll()
        streamDict.removeAll()
        roomExtraInfoDict.removeAll()
        currentScenario = .default
        ZegoExpressEngine.shared().stopSoundLevelMonitor()
        if let callback = callback {
            ZegoExpressEngine.shared().logoutRoom(callback: callback)
        } else {
            ZegoExpressEngine.shared().logoutRoom()
        }
    }
    
    public func setRoomExtraInfo(key: String, value: String) {
        guard let roomID = currentRoomID else { return }
        ZegoExpressEngine.shared().setRoomExtraInfo(value, forKey: key, roomID: roomID) { code in
            if code == 0 {
                var extraInfo: ZegoRoomExtraInfo? = self.roomExtraInfoDict[key]
                if extraInfo == nil {
                    extraInfo = ZegoRoomExtraInfo()
                    extraInfo?.key = key
                    extraInfo?.updateUser = ZegoUser(userID: self.currentUser?.id ?? "", userName: self.currentUser?.name ?? "")
                }
                extraInfo?.updateTime = self.getTimeStamp()
                extraInfo?.value = value
                self.roomExtraInfoDict.updateValue(extraInfo!, forKey: key)
                let extraInfoList: [ZegoRoomExtraInfo] = [extraInfo!]
                for delegate in self.eventHandlers.allObjects {
                    delegate.onRoomExtraInfoUpdate2?(extraInfoList, roomID: roomID)
                }
            }
        }
    }
    
    private func getTimeStamp() -> UInt64 {
        let now = Date()
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        let timeStamp = UInt64(timeInterval)
        return timeStamp
    }
}
