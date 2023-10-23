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
    
    @objc optional func onLocalHostCameraStatus(isOn: Bool)
    @objc optional func onAnotherHostCameraStatus(isOn: Bool)
    
    @objc optional func onMixerStreamTaskFail(errorCode: Int)
    
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
    var pkState: RoomPKState {
        get {
            return pkService?.roomPKState ?? .isNoPK
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
    
    func leaveRoom() {
        if isLocalUserHost() {
            pkService?.sendPKBattlesStopRequest()
        }
        ZegoSDKManager.shared.logoutRoom()
        clearData()
    }
    
    func clearData()  {
        coHostService?.clearData()
        pkService?.clearData()
    }
}
    


extension ZegoLiveStreamingManager {
    
    func sendPKBattlesStartRequest(userID: String, callback: CommonCallback?) {
        pkService?.sendPKBattlesStartRequest(userID: userID, callback: callback)
    }
    
    func sendPKBattleResumeRequest(userID: String) {
        pkService?.sendPKBattleResumeRequest(userID: userID)
    }
    
    func sendPKBattlesStopRequest() {
        pkService?.sendPKBattlesStopRequest()
    }
    
    func cancelPKBattleRequest() {
        pkService?.cancelPKBattleRequest()
    }
    
    func acceptPKStartRequest(requestID: String) {
        pkService?.acceptPKStartRequest(requestID: requestID)
    }
    
    func rejectPKStartRequest(requestID: String) {
        pkService?.rejectPKStartRequest(requestID: requestID)
    }
    
    func muteAnotherHostAudio(mute: Bool) {
        pkService?.muteAnotherHostAudio(mute: mute)
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
    
    func removeRoomData() {
//        coHostService?.removeRoomData();
//        pkService?.removeRoomData();
    }
    
    func removeUserData() {
//        coHostService?.removeUserData();
//        pkService?.removeUserData();
    }
    
}

extension ZegoLiveStreamingManager: ExpressServiceDelegate {
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        if updateType == .add {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomStreamAdd?(streamList: streamList)
            }
            for stream in streamList {
                let extraInfoDict = stream.extraInfo.toDict
                let isCameraOpen: Bool = extraInfoDict?["cam"] as! Bool
                let isMicOpen: Bool = extraInfoDict?["mic"] as! Bool
                for delegate in eventDelegates.allObjects {
                    delegate.onCameraOpen?(stream.user.userID, isCameraOpen: isCameraOpen)
                    delegate.onMicrophoneOpen?(stream.user.userID, isMicOpen: isMicOpen)
                }
            }
        } else {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomStreamDelete?(streamList: streamList)
            }
        }
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .add {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomUserAdd?(userList: userList)
            }
        } else {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomUserDelete?(userList: userList)
            }
        }
    }
    
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        for delegate in eventDelegates.allObjects {
            delegate.onCameraOpen?(userID, isCameraOpen: isCameraOpen)
        }
    }
    
    func onMicrophoneOpen(_ userID: String, isMicOpen: Bool) {
        print("onMicrophoneOpen, userID: \(userID), isMicOpen: \(isMicOpen)")
        for delegate in eventDelegates.allObjects {
            delegate.onMicrophoneOpen?(userID, isMicOpen: isMicOpen)
        }
    }
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        
    }
    
}
