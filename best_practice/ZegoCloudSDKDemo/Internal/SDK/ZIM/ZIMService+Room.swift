//
//  ZIMService+Room.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/7/5.
//

import Foundation
import ZIM

extension ZIMService {
    public func loginRoom(_ roomID: String,
                         roomName: String?,
                         callback: CommonCallback? = nil) {
        if let currentRoom = currentRoom {
            debugPrint("zim room is logined")
            return
        }
        
        let roomInfo = ZIMRoomInfo()
        roomInfo.roomID = roomID
        roomInfo.roomName = roomName ?? roomID
        
        zim?.enterRoom(with: roomInfo, config: ZIMRoomAdvancedConfig(), callback: { roomFullInfo, errorInfo in
            
            if (errorInfo.code.rawValue == 0) {
                self.currentRoom = roomFullInfo
            } else {
                self.currentRoom = nil
            }
            
            callback?(Int(errorInfo.code.rawValue), errorInfo.message)
        });
    }
    
    public func leaveRoom(callback: ZIMRoomLeftCallback?){
        guard let currentRoom = currentRoom else {
            return
        }
        
        zim?.leaveRoom(by: currentRoom.baseInfo.roomID, callback: { roomID, errorInfo in
            if(errorInfo.code.rawValue == 0){
                self.removeRoomData()
            }
            guard let callback = callback else { return }
            callback(roomID,errorInfo)
        })
    }
    
    public func setRoomAttributes(_ key: String, value: String, isForce: Bool = false, isDeleteAfterOwnerLeft: Bool = true, isUpdateOwner: Bool = true, callback: @escaping ZIMRoomAttributesOperatedCallback) {
        guard let roomID = self.currentRoom?.baseInfo.roomID else {
            assertionFailure("Please join the room first!")
            return
        }
        let config = ZIMRoomAttributesSetConfig()
        config.isForce = isForce
        config.isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft
        config.isUpdateOwner = isUpdateOwner
        zim?.setRoomAttributes([key: value], roomID: roomID, config: config, callback: { roomID, errorKeys, errorInfo in
            if errorInfo.code == .ZIMErrorCodeSuccess && !errorKeys.contains(key) {
                self.inRoomAttributsDict[key] = value
            }
            callback(roomID,errorKeys,errorInfo)
        })
    }
    
    public func setRoomAttributes(_ attributes: [String : String], isForce: Bool = false, isDeleteAfterOwnerLeft: Bool = true, isUpdateOwner: Bool = true, callback: ZIMRoomAttributesOperatedCallback?) {
        guard let roomID = self.currentRoom?.baseInfo.roomID else {
            assertionFailure("Please join the room first!")
            return
        }
        let config = ZIMRoomAttributesSetConfig()
        config.isForce = isForce
        config.isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft
        config.isUpdateOwner = isUpdateOwner
        zim?.setRoomAttributes(attributes, roomID: roomID, config: config, callback: { roomID, errorKeys, errorInfo in
            if errorInfo.code == .ZIMErrorCodeSuccess {
                attributes.forEach { (key, value) in
                    if !errorKeys.contains(key) {
                        self.inRoomAttributsDict[key] = value
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        })
    }
    
    public func deletedRoomAttributes(_ keys: [String], isForce: Bool = false, callback: ZIMRoomAttributesOperatedCallback?) {
        guard let roomID = self.currentRoom?.baseInfo.roomID else {
            assertionFailure("Please join the room first!")
            return
        }
        
        let config = ZIMRoomAttributesDeleteConfig()
        config.isForce = isForce
        zim?.deleteRoomAttributes(by: keys, roomID: roomID, config: config, callback: { roomID, errorKeys, errorInfo in
            if errorInfo.code == .ZIMErrorCodeSuccess {
                for key in keys {
                    if !errorKeys.contains(key) {
                        self.inRoomAttributsDict.removeValue(forKey: key)
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        })
    }
    
    public func beginRoomPropertiesBatchOperation(isForce: Bool = false, isDeleteAfterOwnerLeft: Bool = true, isUpdateOwner: Bool = true) {
        guard let roomID = self.currentRoom?.baseInfo.roomID else {
            assertionFailure("Please join the room first!")
            return
        }
        let config = ZIMRoomAttributesBatchOperationConfig()
        config.isForce = isForce
        config.isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft
        config.isUpdateOwner = isUpdateOwner
        zim?.beginRoomAttributesBatchOperation(with: roomID, config: config)
    }
    
    public func endRoomPropertiesBatchOperation(callback: @escaping ZIMRoomAttributesBatchOperatedCallback) {
        guard let roomID = self.currentRoom?.baseInfo.roomID else {
            assertionFailure("Please join the room first!")
            return
        }
        zim?.endRoomAttributesBatchOperation(with: roomID, callback: callback)
    }
}
