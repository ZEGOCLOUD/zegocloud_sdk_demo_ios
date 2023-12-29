//
//  ZegoCallManager+EventHandler.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/13.
//

import Foundation
import ZIM

extension ZegoCallManager: ZIMServiceDelegate {
    
    func onInComingUserRequestReceived(requestID: String, info: ZIMCallInvitationReceivedInfo) {
        let callExtendedData = ZegoCallExtendedData.parse(extendedData: info.extendedData)
        guard let callType = callExtendedData?.type,
              let _ = ZegoSDKManager.shared.currentUser
        else { return }
        if !isCallBusiness(type: callType.rawValue) { return }
        let inRoom: Bool = (ZegoSDKManager.shared.expressService.currentRoomID != nil)
        let inviteeList: [String] = info.callUserList.map { user in
            user.userID
        }
        if inRoom || (currentCallData != nil && currentCallData?.callID != requestID) {
            for delegate in callEventHandlers.allObjects {
                delegate.onInComingCallInvitationReceived?(requestID: requestID, inviter: info.inviter, inviteeList: inviteeList, extendedData: info.extendedData)
            }
            return
        }
        
        let userIDList: [String] = info.callUserList.map { userInfo in
            userInfo.userID
        }
        ZegoCallManager.shared.queryUsersInfo(userIDList) { userFullInfoList, errorUserInfoList, error in
            let callData = ZegoCallDataModel()
            callData.callID = requestID
            callData.callUserList = []
            callData.type = callType
            callData.inviter = CallUserInfo(userID: info.inviter)
            for userInfo in info.callUserList {
                let callUser: CallUserInfo = CallUserInfo(userID: userInfo.userID)
                callUser.callUserState = userInfo.state
                callUser.extendedData = userInfo.extendedData
                callData.callUserList.append(callUser)
            }
            self.currentCallData = callData
            
            for delegate in self.callEventHandlers.allObjects {
                delegate.onInComingCallInvitationReceived?(requestID: requestID, inviter: info.inviter, inviteeList: inviteeList, extendedData: info.extendedData)
            }
        }
    }
    
    
    func onUserRequestStateChanged(info: ZIMCallUserStateChangeInfo, requestID: String) {
        if let currentCallData = currentCallData,
           requestID == currentCallData.callID
        {
            for userInfo in info.callUserList {
                var findIfAlreadyAdded: Bool = false
                var hasUserStateUpdate: Bool = false
                for callUser in currentCallData.callUserList {
                    if callUser.userID == userInfo.userID {
                        if callUser.callUserState != userInfo.state {
                            callUser.callUserState = userInfo.state
                            hasUserStateUpdate = true
                        }
                        findIfAlreadyAdded = true
                        break
                    }
                }
                if !findIfAlreadyAdded {
                    hasUserStateUpdate = true
                    let callUser = CallUserInfo(userID: userInfo.userID)
                    callUser.callUserState = userInfo.state
                    let userData: ZegoCallExtendedData? = ZegoCallExtendedData.parse(extendedData: userInfo.extendedData)
                    callUser.extendedData = userInfo.extendedData
                    currentCallData.callUserList.append(callUser)
                }
                
                if hasUserStateUpdate {
                    for delegate in callEventHandlers.allObjects {
                        delegate.onCallUserUpdate?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                }
            }
            
            var receivedUsers: [ZIMCallUserInfo] = []
            for userInfo in info.callUserList {
                if userInfo.state == .received {
                    receivedUsers.append(userInfo)
                    onReceiveCallUserReceived(userInfoList: receivedUsers)
                } else if userInfo.state == .accepted {
                    onReceiveCallUserAccepted(userInfo: userInfo)
                } else if userInfo.state == .rejected {
                    for delegate in callEventHandlers.allObjects {
                        delegate.onOutgoingCallInvitationRejected?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                    if let localUser = localUser {
                        checkIfPKEnd(requestID: requestID, currentUser: localUser)
                    }
                } else if userInfo.state == .timeout {
                    for delegate in callEventHandlers.allObjects {
                        delegate.onOutgoingCallInvitationTimeout?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                    if let localUser = localUser {
                        checkIfPKEnd(requestID: requestID, currentUser: localUser)
                    }
                } else if userInfo.state == .quit {
                    onReceiveCallUserQuit(requestID: requestID, userInfo: userInfo)
                }
            }
        }
    }
    
    func onUserRequestEnded(info: ZIMCallInvitationEndedInfo, requestID: String) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            stopCall()
        }
    }
    
    
    func onInComingUserRequestTimeout(requestID: String, info: ZIMCallInvitationTimeoutInfo?) {
        if let currentCallData = currentCallData,
           currentCallData.callID == requestID
        {
            for delegate in callEventHandlers.allObjects {
                delegate.onInComingCallInvitationTimeout?(requestID: requestID)
            }
            clearCallData()
        }
    }
    
    func onReceiveCallUserQuit(requestID: String, userInfo: ZIMCallUserInfo) {
        if let currentCallData = currentCallData {
            let selfCallUser = getCallUser(callData: currentCallData, userID: localUser?.id ?? "")
            if let selfCallUser = selfCallUser,
               selfCallUser.hasAccepted
            {
                var moreThanOneAcceptedExceptMe: Bool = false
                var hasWaitingUser: Bool = false
                for callUser in currentCallData.callUserList {
                    if callUser.userID != localUser?.id {
                        if callUser.hasAccepted || callUser.isWaiting {
                            hasWaitingUser = true
                        }
                        if callUser.hasAccepted {
                            moreThanOneAcceptedExceptMe = true
                        }
                    }
                }
                if moreThanOneAcceptedExceptMe {
                    for delegate in callEventHandlers.allObjects {
                        delegate.onCallUserQuit?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                }
                if (!hasWaitingUser) {
                    quitCall(requestID, callback: nil)
                    stopCall()
                }
            }
        }
    }
    
    private func onReceiveCallUserReceived(userInfoList: [ZIMCallUserInfo]) {
        if userInfoList.count > 0 {
            let userIDList: [String] = userInfoList.map { userInfo in
                userInfo.userID
            }
            ZegoSDKManager.shared.zimService.queryUsersInfo(userIDList) { fullInfoList, errorUserInfoList, error in
                if error.code == .success {
                    for delegate in self.callEventHandlers.allObjects {
                        delegate.onCallUserInfoUpdate?(userList: userIDList)
                    }
                }
            }
        }
    }
    
    private func onReceiveCallUserAccepted(userInfo: ZIMCallUserInfo) {
        guard let currentCallData = currentCallData else { return }
        var moreThanOneAcceptedExceptMe = false
        var meHasAccepted = false
        for callUser in currentCallData.callUserList {
            if callUser.userID == localUser?.id {
                meHasAccepted = callUser.hasAccepted
            } else {
                if callUser.hasAccepted {
                    moreThanOneAcceptedExceptMe = true
                }
            }

        }
        
        if currentCallData.isGroupCall {
            if (meHasAccepted && !isCallStart) {
                isCallStart = true
                for delegate in callEventHandlers.allObjects {
                    delegate.onCallStart?()
                }
            }
        } else {
            if (meHasAccepted && moreThanOneAcceptedExceptMe && !isCallStart) {
                isCallStart = true
                for delegate in callEventHandlers.allObjects {
                    delegate.onCallStart?()
                }
            }
        }
        
        for delegate in callEventHandlers.allObjects {
            delegate.onOutgoingCallInvitationAccepted?(userID: userInfo.userID, extendedData: userInfo.extendedData)
        }
    }
    
}
