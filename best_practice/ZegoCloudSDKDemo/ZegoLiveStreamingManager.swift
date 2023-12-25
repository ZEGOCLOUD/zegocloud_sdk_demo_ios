//
//  ZegoLiveStreamingManager.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/5/30.
//

import UIKit
import ZIM
import ZegoExpressEngine

@objc protocol ZegoLiveStreamingManagerDelegate: AnyObject {
    
    @objc optional func onRoomStreamAdd(streamList: [ZegoStream])
    @objc optional func onRoomStreamDelete(streamList: [ZegoStream])
    @objc optional func onRoomUserAdd(userList: [ZegoUser])
    @objc optional func onRoomUserDelete(userList: [ZegoUser])
    @objc optional func onCameraOpen(_ userID: String, isCameraOpen: Bool)
    @objc optional func onMicrophoneOpen(_ userID: String, isMicOpen: Bool)
    
    @objc optional func onReceiveRoomMessage(messageList: [ZIMMessage])
    @objc optional func getMixLayoutConfig(streamList: [String], videoConfig: ZegoMixerVideoConfig) -> [ZegoMixerInput]
    
}

class ZegoLiveStreamingManager: NSObject {
    
    static let shared = ZegoLiveStreamingManager()
    let eventDelegates: NSHashTable<ZegoLiveStreamingManagerDelegate> = NSHashTable(options: .weakMemory)
    
    var isLiveStart: Bool = false
    
    var pkService: PKService?
    var coHostService: CoHostService?
    var pkInfo: PKInfo? {
        get {
            return pkService?.pkInfo
        }
    }
    
    var isPKStarted: Bool {
        get {
            return pkService?.isPKStarted ?? false
        }
    }
    
    var hostUser: ZegoSDKUser? {
        get {
            return coHostService?.hostUser
        }
        set {
            coHostService?.hostUser = newValue
        }
    }
    
    override init() {
        super.init()
        ZegoSDKManager.shared.expressService.addEventHandler(self)
    }
    
    func addUserLoginListeners() {
        pkService = PKService()
        coHostService = CoHostService()
    }
    
    func addPKDelegate(_ delegate: PKServiceDelegate) {
        pkService?.addPKDelegate(delegate)
    }
    
    func addDelegate(_ delegate: ZegoLiveStreamingManagerDelegate) {
        eventDelegates.add(delegate)
    }
    
    func leaveRoom() {
        if isLocalUserHost() {
            quitPKBattle()
        }
        ZegoSDKManager.shared.logoutRoom()
        clearData()
    }
    
    func clearData()  {
        coHostService?.clearData()
        pkService?.clearData()
    }
    
    func getMixLayoutConfig(streamList: [String], videoConfig: ZegoMixerVideoConfig) -> [ZegoMixerInput]? {
        var inputList: [ZegoMixerInput]?
        for delegate in eventDelegates.allObjects {
            inputList = delegate.getMixLayoutConfig?(streamList: streamList, videoConfig: videoConfig)
        }
        return inputList
    }
    
}
    


extension ZegoLiveStreamingManager {
    
    func startPKBattle(anotherHostID: String, callback: UserRequestCallback?) {
        pkService?.invitePKbattle(targetUserIDList: [anotherHostID], autoAccept: true, callback: callback)
    }

    func startPKBattle(anotherHostIDList: [String], callback: UserRequestCallback?) {
        pkService?.invitePKbattle(targetUserIDList: anotherHostIDList, autoAccept: true, callback: callback)
    }
    
    func invitePKBattle(targetUserID: String, callback: UserRequestCallback?) {
        pkService?.invitePKbattle(targetUserIDList: [targetUserID], autoAccept: false, callback: callback)
    }
    
    func invitePKbattle(targetUserIDList: [String], callback: UserRequestCallback?) {
        pkService?.invitePKbattle(targetUserIDList: targetUserIDList, autoAccept: false, callback: callback)
    }
    
//    func joinPKBattle(requestID: String, callback: UserRequestCallback?) {
//        pkService?.joinPKbattle(requestID: requestID, callback: callback)
//    }
    
    func acceptPKStartRequest(requestID: String) {
        pkService?.acceptPKBattle(requestID: requestID)
    }
    
    func rejectPKStartRequest(requestID: String) {
        pkService?.rejectPKBattle(requestID: requestID)
    }
    
    func removeUserFromPKBattle(userID: String) {
        pkService?.removeUserFromPKBattle(userID: userID)
    }
    
    func endPKBattle() {
        if let pkInfo = pkService?.pkInfo {
            pkService?.endPKBattle(requestID: pkInfo.requestID, callback: nil)
            pkService?.stopPKBattle()
        }
    }
    
    func quitPKBattle() {
        if let pkInfo = pkService?.pkInfo {
            pkService?.stopPlayAnotherHostStream()
            pkService?.quitPKBattle(requestID: pkInfo.requestID, callback: nil)
            pkService?.stopPKBattle()
        }
    }
    
    func isLocalUserHost() -> Bool {
        return coHostService?.isLocalUserHost() ?? false
    }
    
    func isHost(userID: String) -> Bool {
        return coHostService?.isHost(userID) ?? false
    }

    func isCoHost(userID: String) -> Bool {
        return coHostService?.isCoHost(userID) ?? false
    }

    func isAudience(userID: String) -> Bool {
        return coHostService?.isAudience(userID) ?? false
    }
    
    func getHostMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main_host"
    }
    
    func getCoHostMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main_cohost"
    }
    
    func isPKUser(userID: String) -> Bool {
        return pkService?.isPKUser(userID: userID) ?? false
    }
    
    func isPKUserMuted(userID: String) -> Bool {
        return pkService?.isPKUserMuted(userID: userID) ?? false
    }
    
    func mutePKUser(muteUserList: [String], mute: Bool, callback: ZegoMixerStartCallback?) {
        if let pkInfo = pkInfo,
           let pkService = pkService
        {
            var muteIndexs: [Int] = []
            for muteUserID in muteUserList {
                let pkUser = pkService.getPKUser(pkBattleInfo: pkInfo, userID: muteUserID)
                var i = 0
                for input in pkService.currentInputList {
                    if input.streamID == pkUser?.pkUserStream {
                        muteIndexs.append(i)
                    }
                    i = i + 1
                }
            }
            pkService.mutePKUser(muteIndexList: muteIndexs, mute: mute, callback: callback)
        }
    }
}
