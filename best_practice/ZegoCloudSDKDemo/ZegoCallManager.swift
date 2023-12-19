//
//  ZegoCallDataManager.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import UIKit
import ZIM

@objc public protocol ZegoCallManagerDelegate: AnyObject {
    
    @objc optional func onCallStart()
    @objc optional func onCallEnd()
    
    @objc optional func onInComingUserRequestReceived(requestID: String, inviter: String, inviteeList: [String], extendedData: String)
    @objc optional func onInComingCallTimeout(requestID: String)
    @objc optional func onCallUserUpdate(userID: String, extendedData: String)
    @objc optional func onCallUserJoin(userID: String, extendedData: String)
    @objc optional func onCallAccepted(userID: String, extendedData: String)
    @objc optional func onCallRejected(userID: String, extendedData: String)
    @objc optional func onCallTimeout(userID: String, extendedData: String)
    @objc optional func onCallUserQuit(userID: String, extendedData: String)
    
}

typealias CallRequestCallback = (_ code: UInt, _ requestID: String) -> ()

class ZegoCallManager: NSObject {
    
    static let shared = ZegoCallManager()
    
    var localUser: ZegoSDKUser? {
        get {
            return ZegoSDKManager.shared.currentUser
        }
    }
    
    var isCallStart: Bool = false
    
    var currentCallData: ZegoCallDataModel?
    
    let callEventHandlers: NSHashTable<ZegoCallManagerDelegate> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
        ZegoSDKManager.shared.zimService.addEventHandler(self)
    }
    
    func addCallEventHandler(_ handler: ZegoCallManagerDelegate) {
        callEventHandlers.add(handler)
    }

    //MARK - invitation
    func addMemberCall(_ targetUserID: [String], callback: CallRequestCallback?) {
        guard let currentCallData = currentCallData,
              let callID = currentCallData.callID
        else { return }
        addUserToRequest(userList: targetUserID, requestID: callID) { requestID, sentInfo, error in
            guard let callback = callback else { return }
            callback(error.code.rawValue, requestID)
        }
    }
    
    func sendVideoCall(_ targetUserID: String, callback: CallRequestCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .video
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: [targetUserID], requestID: callID) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        } else {
            let extendedData = getCallExtendata(type: callType, userName: localUser.name)
            sendUserRequest(userList: [targetUserID], extendedData: extendedData.toString() ?? "", type: callType) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        }
    }
    
    func sendVoiceCall(_ targetUserID: String, callback: CallRequestCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .voice
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: [targetUserID], requestID: callID) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        } else {
            let extendedData = getCallExtendata(type: callType, userName: localUser.name)
            sendUserRequest(userList: [targetUserID], extendedData: extendedData.toString() ?? "", type: callType) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        }
    }
    
    func sendGroupVideoCall(_ targetUserIDs: [String], callback: CallRequestCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .video
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: targetUserIDs, requestID: callID) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        } else {
            let extendedData = getCallExtendata(type: callType, userName: localUser.name)
            sendUserRequest(userList: targetUserIDs, extendedData: extendedData.toString() ?? "", type: callType) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        }
    }
    
    func sendGroupVoiceCall(_ targetUserIDs: [String], callback: CallRequestCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        let callType: CallType = .voice
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: targetUserIDs, requestID: callID) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        } else {
            let extendedData = getCallExtendata(type: callType, userName: localUser.name)
            sendUserRequest(userList: targetUserIDs, extendedData: extendedData.toString() ?? "", type: callType) { requestID, sentInfo, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        }
    }
    
//    func cancelCallRequest(requestID: String, userID: String, callback: ZIMCallCancelSentCallback?) {
//        guard let currentCallData = currentCallData else { return }
//        let extendedData: ZegoCallExtendedData = getCallExtendata(type: currentCallData.type)
//        clearCallData()
//        
//        let config = ZIMCallCancelConfig()
//        config.extendedData = extendedData.jsonString
//        ZegoSDKManager.shared.zimService.cancelUserRequest(requestID: requestID, config: config, userList: [userID]) { requestID, errorInvitees, error in
//            guard let callback = callback else { return }
//            callback(requestID, errorInvitees, error)
//        }
//
//    }
    
    func quitCall(_ requestID: String, callback: ZIMCallQuitSentCallback?) {
        guard let currentCallData = currentCallData,
              let localUser = ZegoSDKManager.shared.currentUser
        else { return }
        let extendedData = getCallExtendata(type: currentCallData.type, userName: localUser.name)
        quitUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
        leaveRoom()
        clearCallData()
    }
    
    func endCall(_ requestID: String, callback: ZIMCallEndSentCallback?) {
        guard let currentCallData = currentCallData,
              let localUser = ZegoSDKManager.shared.currentUser
        else { return }
        let extendedData = getCallExtendata(type: currentCallData.type, userName: localUser.name)
        endUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
        clearCallData()
    }
    
    func rejectCallRequest(requestID: String, callback: ZIMCallRejectionSentCallback?) {
        if let currentCallData = currentCallData,
           requestID == currentCallData.callID
        {
            let extendedData = getCallExtendata(type: currentCallData.type)
            refuseUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "") { requestID, error in
                guard let callback = callback else { return }
                callback(requestID,error)
            }
            clearCallData()
        }
    }
    
    func busyRejectCallRequest(requestID: String,  extendedData: String, type: CallType, callback: ZIMCallRejectionSentCallback?) {
        refuseUserRequest(requestID: requestID, extendedData: extendedData, callback: callback)
    }
    
    func acceptCallRequest(requestID: String, callback: ZIMCallAcceptanceSentCallback?) {
        guard let currentCallData = currentCallData else { return }
        let extendedData = getCallExtendata(type: currentCallData.type, userName: localUser?.name)
        acceptUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
//
//        updateCallData(callStatus: .accept)
//        let extendedData: [String : Any] = ["type": currentCallData.type.rawValue]
//        let config = ZIMCallAcceptConfig()
//        config.extendedData = extendedData.jsonString
//        ZegoSDKManager.shared.zimService.acceptUserRequest(requestID: requestID, config: config) { requestID, error in
//            guard let callback = callback else { return }
//            callback(requestID,error)
//        }
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

extension ZegoCallManager {
    
//    func createCallData(_ callID: String, inviter: ZegoSDKUser, invitees: [ZegoSDKUser], type: CallType) {
//        let inviterUser = CallUserInfo(userInfo: inviter, callStatus: .wating)
//        var inviteeList: [CallUserInfo] = invitees.map { user in
//            return CallUserInfo(userInfo: user, callStatus: .wating)
//        }
//        currentCallData = ZegoCallDataModel(callID: callID, inviter: inviterUser, invitees: inviteeList, type: type, isGroupCall: inviteeList.count > 1)
//    }
    
//    private func updateCallData(callStatus: CallState, userID: String) {
//        guard let currentCallData = currentCallData else { return }
//        currentCallData.invitees.forEach { user in
//            if user.userInfo?.id == userID {
//                user.callStatus = callStatus
//            }
//        }
//    }
    
    func getCallUser(callData: ZegoCallDataModel, userID: String) -> CallUserInfo? {
        for callUser in callData.callUserList {
            if callUser.userInfo?.id == userID {
                return callUser
            }
        }
        return nil
    }
    
    func checkIfPKEnd(requestID: String, currentUser: ZegoSDKUser) {
        guard let currentCallData = currentCallData else { return }
        let selfCallUser = getCallUser(callData: currentCallData, userID: currentUser.id)
        if let selfCallUser = selfCallUser {
            if selfCallUser.hasAccepted {
                var hasWaitingUser: Bool = false;
                for callUser in currentCallData.callUserList {
                    if callUser.userInfo?.id != localUser?.id {
                        // except self
                        if callUser.hasAccepted || callUser.isWaiting {
                            hasWaitingUser = true
                        }
                    }
                }
                if (!hasWaitingUser) {
                    quitCall(requestID, callback: nil)
                    stopCall()
                }
            }
        }
    }
    
    func stopCall() {
        clearCallData()
        for delegate in callEventHandlers.allObjects {
            delegate.onCallEnd?()
        }
    }
    
    func clearCallData() {
        isCallStart = false
        currentCallData = nil
    }
    
    private func getCallExtendata(type: CallType, userName: String? = nil) -> ZegoCallExtendedData {
        let extendedData = ZegoCallExtendedData(type: type, userName: userName)
        return extendedData
    }
    
    private func addUserToRequest(userList: [String], requestID: String, callback: ZIMCallingInvitationSentCallback?) {
        let config: ZIMCallingInviteConfig = ZIMCallingInviteConfig()
        ZegoSDKManager.shared.zimService.addUserToRequest(invitees: userList, requestID: requestID, config: config, callback: callback)
    }
    
    private func sendUserRequest(userList: [String], extendedData: String, type: CallType, callback: ZIMCallInvitationSentCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        currentCallData = ZegoCallDataModel()
        let config = ZIMCallInviteConfig()
        config.mode = .advanced
        config.extendedData = extendedData
        config.timeout = 10
        ZegoSDKManager.shared.zimService.sendUserRequest(userList: userList, config: config) { requestID, sentInfo, error in
            if error.code == .success {
                let errorUser: [String] = sentInfo.errorUserList.map { userInfo in
                    userInfo.userID
                }
                let sucessUsers = userList.filter { userID in
                    return !errorUser.contains(userID)
                }
                if !sucessUsers.isEmpty {
//                    let inviteeList: [ZegoSDKUser] = sucessUsers.map { userID in
//                        ZegoSDKUser(id: userID, name: "")
//                    }
                    self.currentCallData?.callID = requestID
                    self.currentCallData?.inviter = CallUserInfo(userInfo: localUser)
                    self.currentCallData?.type = type
                    self.currentCallData?.callUserList = []
                } else {
                    self.clearCallData()
                }
            } else {
                self.clearCallData()
            }
            guard let callback = callback else { return }
            callback(requestID, sentInfo, error)
        }
    }
    
    private func endUserRequest(requestID: String, extendedData: String, callback: ZIMCallEndSentCallback?) {
        let config = ZIMCallEndConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.endUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
    private func quitUserRequest(requestID: String, extendedData: String, callback: ZIMCallQuitSentCallback?) {
        let config = ZIMCallQuitConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.quitUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
    private func acceptUserRequest(requestID: String, extendedData: String, callback: ZIMCallAcceptanceSentCallback?) {
        let config = ZIMCallAcceptConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.acceptUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
    private func refuseUserRequest(requestID: String, extendedData: String, callback: ZIMCallRejectionSentCallback?) {
        let config = ZIMCallRejectConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.refuseUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
}
