//
//  ZEGOLiveAudioRoomManager.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2023/5/5.
//

import UIKit
import ZIM
import ZegoExpressEngine



enum RoomCommandType: Int {
    case muteSpeaker = 20000
    case unMuteSpeaker = 20001
    case kickOutRoom = 20002
}

protocol ZegoLiveAudioRoomManagerDelegate: AnyObject {
    func onHostChanged(_ user: ZegoSDKUser)
    func onSeatLockChanged(_ lock: Bool)
    func onSeatChanged(_ seatList: [ZegoLiveAudioRoomSeat])
    func onQueryUserInfoSucess()
    func onReceiveMuteUserSpeaker(_ userID: String, isMute: Bool)
    func onReceiveKickOutRoom()
}

extension ZegoLiveAudioRoomManagerDelegate {
    func onHostChanged(_ user: ZegoSDKUser) { }
    func onSeatLockChanged(_ lock: Bool) { }
    func onSeatChanged(_ seatList: [ZegoLiveAudioRoomSeat]) { }
    func onQueryUserInfoSucess() { }
    func onReceiveMuteUserSpeaker(_ userID: String, isMute: Bool) { }
    func onReceiveKickOutRoom() { }
}

class ZegoLiveAudioRoomManager: NSObject {
    
    static let shared = ZegoLiveAudioRoomManager()
    private let seatService: RoomSeatService = RoomSeatService()
    
    private let KEY: String = "audioRoom"
    private var roomExtraInfoDict: [String : AnyObject] = [:]
    private var lockSeat: Bool = false
    private var hostUserID: String?
    
    var seatList: [ZegoLiveAudioRoomSeat] {
        get {
            return seatService.seatList
        }
    }
    
    var hostSeatIndex: Int {
        get {
            return seatService.hostSeatIndex
        }
        set {
            seatService.hostSeatIndex = newValue
        }
    }
    weak var delegate: ZegoLiveAudioRoomManagerDelegate?
    
    func initWithConfig(_ layoutConfig: ZegoLiveAudioRoomLayoutConfig) {
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        seatService.initWithConfig(layoutConfig)
    }
    
    func unInit() {
        ZegoSDKManager.shared.expressService.removeEventHandler(self)
        ZegoSDKManager.shared.zimService.removeEventHandler(self)
    }
    
    func addSeatServiceEventHandler(_ eventHandler: RoomSeatServiceDelegate) {
        seatService.addSeatServiceEventHandler(eventHandler)
    }
    
    func lockSeat(_ lock: Bool) {
        roomExtraInfoDict.updateValue(lock as AnyObject, forKey: "lockseat")
        ZegoSDKManager.shared.expressService.setRoomExtraInfo(key: KEY, value: roomExtraInfoDict.jsonString)
    }
    
    func isSeatLocked() -> Bool {
        return lockSeat
    }

    func tryTakeSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        seatService.tryTakeSeat(seatIndex: seatIndex, callback: callback)
    }
    
    func takeSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        seatService.takeSeat(seatIndex: seatIndex, callback: callback)
    }

    
    func switchSeat(fromSeatIndex: Int, toSeatIndex: Int, callback: ZIMRoomAttributesBatchOperatedCallback?) {
        seatService.switchSeat(fromSeatIndex: fromSeatIndex, toSeatIndex: toSeatIndex, callback: callback)
    }
    
    func leaveSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        seatService.leaveSeat(seatIndex: seatIndex, callback: callback)
    }
    
    func emptySeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        seatService.emptySeat(seatIndex: seatIndex, callback: callback)
    }
    
    func muteSpeaker(_ userID: String, isMute: Bool, callback: RoomCommandCallback?) {
        let messageType: RoomCommandType = isMute ? .muteSpeaker : .unMuteSpeaker
        let commandDict: [String: AnyObject] = ["room_command_type": messageType.rawValue as AnyObject, "receiver_id": userID as AnyObject]
        ZegoSDKManager.shared.zimService.sendRoomCommand(command: commandDict.jsonString, callback: callback)
    }
    
    func kickOutRoom(_ userID: String, callback: RoomCommandCallback?) {
        let messageType: RoomCommandType = .kickOutRoom
        let commandDict: [String: AnyObject] = ["room_command_type": messageType.rawValue as AnyObject, "receiver_id": userID as AnyObject]
        ZegoSDKManager.shared.zimService.sendRoomCommand(command: commandDict.jsonString, callback: callback)
    }
    
    func leaveRoom() {
        lockSeat = false
        hostUserID = nil
        roomExtraInfoDict.removeAll()
        seatService.removeRoomData()
        ZegoSDKManager.shared.logoutRoom()
    }
    
    func setSelfHost() {
        guard let localUser = ZegoSDKManager.shared.expressService.currentUser else { return }
        hostUserID = localUser.id
        roomExtraInfoDict.updateValue(localUser.id as AnyObject, forKey: "host")
        ZegoSDKManager.shared.expressService.setRoomExtraInfo(key: KEY, value: roomExtraInfoDict.jsonString)
    }
    
    func getHostUser() -> ZegoSDKUser? {
        guard let hostUserID = hostUserID else { return nil }
        return ZegoSDKManager.shared.getUser(hostUserID)
    }
    
    func updateUserAvatarUrl(_ url: String, callback: @escaping ZIMUserAvatarUrlUpdatedCallback) {
        ZegoSDKManager.shared.zimService.updateUserAvatarUrl(url, callback: callback)
    }
    
    func queryUsersInfo(_ userIDList: [String], callback: @escaping ZIMUsersInfoQueriedCallback) {
        ZegoSDKManager.shared.zimService.queryUsersInfo(userIDList, callback: callback)
    }
    
    func getUserAvatar(userID: String) -> String? {
        return ZegoSDKManager.shared.zimService.getUserAvatar(userID: userID);
    }
    
    func getHostMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main_host"
    }
    
    func getCoHostMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main_cohost"
    }
    
    func clearData() {
        lockSeat = false
        hostUserID = nil
        hostSeatIndex = 0
        roomExtraInfoDict.removeAll()
        seatService.removeRoomData()
    }

}

extension ZegoLiveAudioRoomManager: ExpressServiceDelegate, ZIMServiceDelegate {
    func onRoomExtraInfoUpdate2(_ roomExtraInfoList: [ZegoRoomExtraInfo], roomID: String) {
        for extraInfo in roomExtraInfoList {
            if (extraInfo.key == KEY) {
                let extraInfoDict: [String : Any] = extraInfo.value.toDict ?? [:]
                for infoKey in extraInfoDict.keys {
                    if infoKey == "host" {
                        let tempUserID = extraInfoDict["host"] as! String
                        let notifyHostChange: Bool = (hostUserID != tempUserID)
                        hostUserID = tempUserID
                        if let hostUser = getHostUser(),
                           notifyHostChange
                        {
                            delegate?.onHostChanged(hostUser)
                        }
                    } else if infoKey == "lockseat" {
                        let tempLock: Bool = extraInfoDict["lockseat"] as! Bool
                        let changed: Bool = (lockSeat != tempLock)
                        lockSeat = tempLock
                        if changed {
                            delegate?.onSeatLockChanged(tempLock)
                        }
                    }
                }
            }
        }
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for user in userList {
            if updateType == .add {
                if let hostUserID = hostUserID,
                   user.userID == hostUserID
                {
                    let hostUser: ZegoSDKUser? = ZegoSDKManager.shared.expressService.inRoomUserDict[user.userID]
                    if let hostUser = hostUser {
                        for seat in seatList {
                            if seat.currentUser?.id == hostUser.id {
                                seatService.hostSeatIndex = seat.seatIndex
                                break
                            }
                        }
                        delegate?.onHostChanged(hostUser)
                    }
                }
            }
        }
        if updateType == .add {
            self.queryUsersInfo(userList.map({
                return $0.userID
            })) { userFullInfoList, errorUserInfoList, errorInfo in
                if errorInfo.code == .success {
                    self.delegate?.onQueryUserInfoSucess()
                }
            }
        }
        
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        for stream in streamList {
            if updateType == .add {
                ZegoSDKManager.shared.expressService.startPlayingStream(nil, streamID: stream.streamID)
            } else {
                ZegoSDKManager.shared.expressService.stopPlayingStream(stream.streamID)
            }
        }
    }
    
    func onRoomCommandReceived( senderID: String, command: String) {
        let messageDict: [String: Any] = command.toDict ?? [:]
        if messageDict.keys.contains("room_command_type") {
            let type: RoomCommandType? = RoomCommandType(rawValue: messageDict["room_command_type"] as? Int ?? -1)
            let receiverID: String? = messageDict["receiver_id"] as? String
            if let receiverID = receiverID,
               let type = type
            {
                if receiverID == ZegoSDKManager.shared.currentUser?.id {
                    switch type {
                    case .muteSpeaker:
                        delegate?.onReceiveMuteUserSpeaker(receiverID, isMute: true)
                    case .unMuteSpeaker:
                        delegate?.onReceiveMuteUserSpeaker(receiverID, isMute: false)
                    case .kickOutRoom:
                        delegate?.onReceiveKickOutRoom()
                    }
                } else {
                    print("onRoomCommandReceived:\(command)")
                }
            }
        }
    }
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        
    }
    
}
