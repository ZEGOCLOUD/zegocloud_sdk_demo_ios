//
//  ZegoCallDataManager.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import UIKit
import ZIM

@objc public protocol ZegoCallManagerDelegate: AnyObject {
    
    @objc optional func onInComingUserRequestTimeout(requestID: String)
    @objc optional func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String)
    @objc optional func onOutgoingUserRequestTimeout(requestID: String)
    @objc optional func onOutgoingUserRequestAccepted(requestID: String, invitee: String, extendedData: String)
    @objc optional func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String)
    @objc optional func onInComingUserRequestReceived(requestID: String, inviter: String, extendedData: String)
}

class ZegoCallManager: NSObject {
    
    static let shared = ZegoCallManager()
    
    var currentCallData: ZegoCallDataModel?
    
    let callEventHandlers: NSHashTable<ZegoCallManagerDelegate> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
        ZegoSDKManager.shared.zimService.addEventHandler(self)
    }
    
    func addCallEventHandler(_ handler: ZegoCallManagerDelegate) {
        callEventHandlers.add(handler)
    }
    
    func createCallData(_ callID: String, inviter: ZegoSDKUser, invitee: ZegoSDKUser, type: CallType, callStatus: CallState) {
        currentCallData = ZegoCallDataModel(callID: callID, inviter: inviter, invitee: invitee, type: type, callStatus: callStatus)
    }
    
    func updateCallData(callStatus: CallState) {
        currentCallData?.callStatus = callStatus
    }
    
    func clearCallData() {
        currentCallData = nil
    }

    //MARK - invitation
    func sendVideoCall(_ targetUserID: String, callback: ZIMCallInvitationSentCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .video
        let extendedData: [String : Any] = ["type": callType.rawValue, "user_name": localUser.name]
        
        let config = ZIMCallInviteConfig()
        config.extendedData = extendedData.jsonString
        config.timeout = 60
        ZegoSDKManager.shared.zimService.sendUserRequest(userList: [targetUserID], config: config) { requestID, sentInfo, error in
            if error.code == .success {
                let invitee: ZegoSDKUser = ZegoSDKUser(id: targetUserID, name: targetUserID)
                self.createCallData(requestID, inviter: localUser, invitee: invitee, type: callType, callStatus: .wating)
            } else {
                self.clearCallData()
            }
            guard let callback = callback else { return }
            callback(requestID, sentInfo, error)
        }
    }
    
    func sendVoiceCall(_ targetUserID: String, callback: ZIMCallInvitationSentCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .voice
        let extendedData: [String : Any] = ["type": callType.rawValue, "user_name": localUser.name]
        
        let config = ZIMCallInviteConfig()
        config.extendedData = extendedData.jsonString
        config.timeout = 60
        ZegoSDKManager.shared.zimService.sendUserRequest(userList: [targetUserID], config: config) { requestID, sentInfo, error in
            if error.code == .success {
                let invitee: ZegoSDKUser = ZegoSDKUser(id: targetUserID, name: targetUserID)
                self.createCallData(requestID, inviter: localUser, invitee: invitee, type: callType, callStatus: .wating)
            } else {
                self.clearCallData()
            }
            guard let callback = callback else { return }
            callback(requestID, sentInfo, error)
        }
    }
    
    func cancelCallRequest(requestID: String, userID: String, callback: ZIMCallCancelSentCallback?) {
        guard let currentCallData = currentCallData else { return }
        let extendedData: [String : Any] = ["type": currentCallData.type.rawValue]
        clearCallData()
        let config = ZIMCallCancelConfig()
        config.extendedData = extendedData.jsonString
        ZegoSDKManager.shared.zimService.cancelUserRequest(requestID: requestID, config: config, userList: [userID]) { requestID, errorInvitees, error in
            guard let callback = callback else { return }
            callback(requestID, errorInvitees, error)
        }

    }
    
    func rejectCallRequest(requestID: String, callback: ZIMCallRejectionSentCallback?) {
        if let currentCallData = currentCallData,
           requestID == currentCallData.callID
        {
            let extendedData: [String : Any] = ["type": currentCallData.type.rawValue]
            clearCallData()
            let config = ZIMCallRejectConfig()
            config.extendedData = extendedData.jsonString
            ZegoSDKManager.shared.zimService.refuseUserRequest(requestID: requestID, config: config) { requestID, error in
                guard let callback = callback else { return }
                callback(requestID,error)
            }
        }
    }
    
    func acceptCallRequest(requestID: String, callback: ZIMCallAcceptanceSentCallback?) {
        guard let currentCallData = currentCallData else { return }
        updateCallData(callStatus: .accept)
        let extendedData: [String : Any] = ["type": currentCallData.type.rawValue]
        let config = ZIMCallAcceptConfig()
        config.extendedData = extendedData.jsonString
        ZegoSDKManager.shared.zimService.acceptUserRequest(requestID: requestID, config: config) { requestID, error in
            guard let callback = callback else { return }
            callback(requestID,error)
        }
    }
    
    func busyRejectCallRequest(requestID: String,  extendedData: String, type: CallType, callback: ZIMCallRejectionSentCallback?) {
        let config = ZIMCallRejectConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.refuseUserRequest(requestID: requestID, config: config) { requestID, error in
            guard let callback = callback else { return }
            callback(requestID,error)
        }
    }
    
    func leaveRoom() {
        ZegoSDKManager.shared.logoutRoom()
    }
     
    func isCallBusiness(type: Int) -> Bool {
        if type == CallType.video.rawValue || type == CallType.voice.rawValue {
            return true
        }
        return false
    }
    
    func getMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main"
    }
}

extension ZegoCallManager: ZIMServiceDelegate {
    func onInComingUserRequestReceived(requestID: String, inviter: String, extendedData: String) {
        let extendedDict: [String : Any] = extendedData.toDict ?? [:]
        let callType: CallType? = CallType(rawValue: extendedDict["type"] as? Int ?? -1)
        guard let callType = callType,
              let localUser = ZegoSDKManager.shared.currentUser
        else { return }
        if !isCallBusiness(type: callType.rawValue) { return }
        let inRoom: Bool = (ZegoSDKManager.shared.expressService.currentRoomID != nil)
        if inRoom || (currentCallData != nil && currentCallData?.callID != requestID) {
            for delegate in callEventHandlers.allObjects {
                delegate.onInComingUserRequestReceived?(requestID: requestID, inviter: inviter, extendedData: extendedData)
            }
            return
        }
        let userName: String = extendedDict["user_name"] as? String ?? ""
        let inviterUser = ZegoSDKUser(id: inviter, name: userName)
        createCallData(requestID, inviter: inviterUser, invitee: localUser, type: callType, callStatus: .wating)
        
        for delegate in callEventHandlers.allObjects {
            delegate.onInComingUserRequestReceived?(requestID: requestID, inviter: inviter, extendedData: extendedData)
        }
    }
    
    func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            for delegate in callEventHandlers.allObjects {
                delegate.onInComingUserRequestCancelled?(requestID: requestID, inviter: inviter, extendedData: extendedData)
            }
            clearCallData()
        }
    }
    
    func onInComingUserRequestTimeout(requestID: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            for delegate in callEventHandlers.allObjects {
                delegate.onInComingUserRequestTimeout?(requestID: requestID)
            }
            clearCallData()
        }
    }
    
    func onOutgoingUserRequestTimeout(requestID: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            for delegate in callEventHandlers.allObjects {
                delegate.onOutgoingUserRequestTimeout?(requestID: requestID)
            }
            clearCallData()
        }
    }
    
    func onOutgoingUserRequestAccepted(requestID: String, invitee: String, extendedData: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            updateCallData(callStatus: .accept)
            for delegate in callEventHandlers.allObjects {
                delegate.onOutgoingUserRequestAccepted?(requestID: requestID, invitee: invitee, extendedData: extendedData)
            }
        }
    }
    
    func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            updateCallData(callStatus: .reject)
            clearCallData()
            for delegate in callEventHandlers.allObjects {
                delegate.onOutgoingUserRequestRejected?(requestID: requestID, invitee: invitee, extendedData: extendedData)
            }
        }
    }
}
