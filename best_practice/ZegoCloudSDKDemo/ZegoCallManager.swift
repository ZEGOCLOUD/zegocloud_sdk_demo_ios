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
    @objc optional func onInComingCallInvitationReceived(requestID: String, inviter: String, inviteeList: [String], extendedData: String)
    @objc optional func onInComingCallInvitationTimeout(requestID: String)
    @objc optional func onCallUserUpdate(userID: String, extendedData: String)
    @objc optional func onCallUserJoin(userID: String, extendedData: String)
    @objc optional func onOutgoingCallInvitationAccepted(userID: String, extendedData: String)
    @objc optional func onOutgoingCallInvitationRejected(userID: String, extendedData: String)
    @objc optional func onOutgoingCallInvitationTimeout(userID: String, extendedData: String)
    @objc optional func onCallUserQuit(userID: String, extendedData: String)
    @objc optional func onCallUserInfoUpdate(userList: [String])
    
}

typealias CallRequestCallback = (_ code: UInt, _ requestID: String?) -> ()

class ZegoCallManager: NSObject, CallManagerProtocol {
    
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
    func inviteUserToJoinCall(_ targetUserID: [String], callback: CallRequestCallback?) {
        guard let currentCallData = currentCallData,
              let callID = currentCallData.callID
        else { return }
        addUserToRequest(userList: targetUserID, requestID: callID, callback: callback)
    }
    
    func sendVideoCallInvitation(_ targetUserID: String, callback: CallRequestCallback?) {
        let callType: CallType = .video
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: [targetUserID], requestID: callID, callback: callback)
        } else {
            let extendedData = getCallExtendata(type: callType)
            sendUserRequest(userList: [targetUserID], extendedData: extendedData.toString() ?? "", type: callType, callback: callback)
        }
    }
    
    func sendVoiceCallInvitation(_ targetUserID: String, callback: CallRequestCallback?) {
        let callType: CallType = .voice
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: [targetUserID], requestID: callID, callback: callback)
        } else {
            let extendedData = getCallExtendata(type: callType)
            sendUserRequest(userList: [targetUserID], extendedData: extendedData.toString() ?? "", type: callType, callback: callback)
        }
    }
    
    func sendGroupVideoCallInvitation(_ targetUserIDs: [String], callback: CallRequestCallback?) {
        let callType: CallType = .video
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: targetUserIDs, requestID: callID, callback: callback)
        } else {
            let extendedData = getCallExtendata(type: callType)
            sendUserRequest(userList: targetUserIDs, extendedData: extendedData.toString() ?? "", type: callType, callback: callback)
        }
    }
    
    func sendGroupVoiceCallInvitation(_ targetUserIDs: [String], callback: CallRequestCallback?) {
        let callType: CallType = .voice
        if let currentCallData = currentCallData,
           let callID = currentCallData.callID
        {
            addUserToRequest(userList: targetUserIDs, requestID: callID, callback: callback)
        } else {
            let extendedData = getCallExtendata(type: callType)
            sendUserRequest(userList: targetUserIDs, extendedData: extendedData.toString() ?? "", type: callType, callback: callback)
        }
    }
    
    func quitCall(_ requestID: String, callback: ZIMCallQuitSentCallback?) {
        guard let currentCallData = currentCallData else { return }
        let extendedData = getCallExtendata(type: currentCallData.type)
        quitUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
        leaveRoom()
        clearCallData()
    }
    
    func endCall(_ requestID: String, callback: ZIMCallEndSentCallback?) {
        guard let currentCallData = currentCallData,
              let localUser = ZegoSDKManager.shared.currentUser
        else { return }
        let extendedData = getCallExtendata(type: currentCallData.type)
        endUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
        leaveRoom()
        clearCallData()
    }
    
    func rejectCallInvitation(requestID: String, callback: ZIMCallRejectionSentCallback?) {
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
    
    func rejectCallInvitationCauseBusy(requestID: String,  extendedData: String, type: CallType, callback: ZIMCallRejectionSentCallback?) {
        refuseUserRequest(requestID: requestID, extendedData: extendedData, callback: callback)
    }
    
    func acceptCallInvitation(requestID: String, callback: ZIMCallAcceptanceSentCallback?) {
        guard let currentCallData = currentCallData else { return }
        let extendedData = getCallExtendata(type: currentCallData.type)
        acceptUserRequest(requestID: requestID, extendedData: extendedData.toString() ?? "", callback: callback)
    }
    
    func updateUserAvatarUrl(_ url: String, callback: @escaping ZIMUserAvatarUrlUpdatedCallback) {
        ZegoSDKManager.shared.zimService.updateUserAvatarUrl(url, callback: callback)
    }
    
    func queryUsersInfo(_ userIDList: [String], callback: ZIMUsersInfoQueriedCallback?) {
        ZegoSDKManager.shared.zimService.queryUsersInfo(userIDList) { userFullInfoList, errorUserInfoList, error in
            guard let callback = callback else { return }
            callback(userFullInfoList,errorUserInfoList,error)
        }
    }
    
    func getUserAvatar(userID: String) -> String? {
        return ZegoSDKManager.shared.zimService.getUserAvatar(userID: userID);
    }
    
    func getMainStreamID() -> String {
        return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(ZegoSDKManager.shared.currentUser?.id ?? "")_main"
    }
}

extension ZegoCallManager {
    
    func leaveRoom() {
        ZegoSDKManager.shared.logoutRoom()
    }
    
    func isCallBusiness(type: Int) -> Bool {
        if type == CallType.video.rawValue || type == CallType.voice.rawValue {
            return true
        }
        return false
    }
    
    func getCallUser(callData: ZegoCallDataModel, userID: String) -> CallUserInfo? {
        for callUser in callData.callUserList {
            if callUser.userID == userID {
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
                    if callUser.userID != localUser?.id {
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
        leaveRoom()
        for delegate in callEventHandlers.allObjects {
            delegate.onCallEnd?()
        }
    }
    
    func clearCallData() {
        isCallStart = false
        currentCallData = nil
    }
    
    private func getCallExtendata(type: CallType) -> ZegoCallExtendedData {
        let extendedData = ZegoCallExtendedData(type: type)
        return extendedData
    }
    
    private func addUserToRequest(userList: [String], requestID: String, callback: CallRequestCallback?) {
        ZegoSDKManager.shared.zimService.queryUsersInfo(userList) { fullInfoList, errorUserInfoList, error in
            if error.code == .success {
                let config: ZIMCallingInviteConfig = ZIMCallingInviteConfig()
                ZegoSDKManager.shared.zimService.addUserToRequest(invitees: userList, requestID: requestID, config: config) { requestID, sentInfo, error in
                    guard let callback = callback else { return }
                    callback(error.code.rawValue, requestID)
                }
            } else {
                guard let callback = callback else { return }
                callback(error.code.rawValue, nil)
            }
        }
    }
    
    private func sendUserRequest(userList: [String], extendedData: String, type: CallType, callback: CallRequestCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        ZegoSDKManager.shared.zimService.queryUsersInfo(userList) { fullInfoList, errorUserInfoList, error in
            if error.code == .success {
                self.currentCallData = ZegoCallDataModel()
                let config = ZIMCallInviteConfig()
                config.mode = .advanced
                config.extendedData = extendedData
                config.timeout = 60
                ZegoSDKManager.shared.zimService.sendUserRequest(userList: userList, config: config) { requestID, sentInfo, error in
                    if error.code == .success {
                        let errorUser: [String] = sentInfo.errorUserList.map { userInfo in
                            userInfo.userID
                        }
                        let sucessUsers = userList.filter { userID in
                            return !errorUser.contains(userID)
                        }
                        if !sucessUsers.isEmpty {
                            self.currentCallData?.callID = requestID
                            self.currentCallData?.inviter = CallUserInfo(userID: localUser.id)
                            self.currentCallData?.type = type
                            self.currentCallData?.callUserList = []
                        } else {
                            self.clearCallData()
                        }
                    } else {
                        self.clearCallData()
                    }
                    guard let callback = callback else { return }
                    callback(error.code.rawValue, requestID)
                }
            } else {
                guard let callback = callback else { return }
                callback(error.code.rawValue, nil)
            }
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
