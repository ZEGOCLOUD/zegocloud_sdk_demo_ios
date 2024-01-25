//
//  PKService+EventHandler.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/10/30.
//

import Foundation
import ZIM

extension PKService: ZIMServiceDelegate {
    
    func onRoomAttributesUpdated2(setProperties: [[String : String]], deleteProperties: [[String : String]]) {
        for deleteProperty in deleteProperties {
            deleteProperty.forEach { (key, _) in
                pkRoomAttribute.removeValue(forKey: key)
            }
        }
        for setProperty in setProperties {
            setProperty.forEach { (key,value) in
                pkRoomAttribute.updateValue(value, forKey: key)
            }
        }
        
        for setProperty in setProperties {
            if setProperty.keys.contains("pk_users") {
                onReceivePKRoomAttribute(roomProperties: setProperty)
            }
        }
        for deleteProperty in deleteProperties {
            if deleteProperty.keys.contains("pk_users") {
                if let _ = pkInfo {
                    stopPKBattle()
                } else {
                    return
                }
            }
        }
    }
    
    // pk invitation
    func onInComingUserRequestReceived(requestID: String, info: ZIMCallInvitationReceivedInfo) {
        let inviterExtendedData = PKExtendedData.parse(extendedData: info.extendedData)
        guard let inviterExtendedData = inviterExtendedData else { return }
        if inviterExtendedData.type == PKExtendedData.STARK_PK {
            let currentRoomID: String = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
            let userNotHost: Bool = currentRoomID.isEmpty || !liveManager.isLocalUserHost()
            if (pkInfo != nil || userNotHost)
            {
                rejectPKBattle(requestID: requestID)
                return
            }
            let newPKInfo = PKInfo()
            newPKInfo.requestID = requestID
            newPKInfo.pkUserList = []
            for callUserInfo in info.callUserList {
                let pkUser = PKUser(userID: callUserInfo.userID)
                pkUser.callUserState = callUserInfo.state
                pkUser.extendedData = callUserInfo.extendedData
                if !callUserInfo.extendedData.isEmpty {
                    let userData = PKExtendedData.parse(extendedData: callUserInfo.extendedData)
                    if let userData = userData {
                        pkUser.userName = userData.userName ?? ""
                        pkUser.roomID = userData.roomID ?? ""
                    }
                }
                
                if localUser?.id == callUserInfo.userID {
                    pkUser.userName = localUser?.name ?? ""
                    pkUser.roomID = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
                    pkUser.camera = localUser?.isCameraOpen ?? false
                    pkUser.microphone = localUser?.isMicrophoneOpen ?? false
                    newPKInfo.pkUserList.insert(pkUser, at: 0)
                } else {
                    if callUserInfo.userID == inviterExtendedData.userID {
                        pkUser.roomID = inviterExtendedData.roomID ?? ""
                        pkUser.userName = inviterExtendedData.userName ?? ""
                    }
                    newPKInfo.pkUserList.append(pkUser)
                }
            }
            pkInfo = newPKInfo
            for delegate in eventDelegates.allObjects {
                delegate.onPKBattleReceived?(requestID: requestID, info: info)
            }
        }
    }
    
    func onInComingUserRequestTimeout(requestID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
            for delegate in eventDelegates.allObjects {
                delegate.onIncomingPKRequestTimeout?()
            }
        }
    }
    
    func onUserRequestEnded(info: ZIMCallInvitationEndedInfo, requestID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            stopPKBattle()
        }
    }
    
    func onUserRequestStateChanged(info: ZIMCallUserStateChangeInfo, requestID: String) {
        if let pkInfo = pkInfo,
           requestID == pkInfo.requestID
        {
            for userInfo in info.callUserList {
                var findIfAlreadyAdded: Bool = false
                for pkUser in pkInfo.pkUserList {
                    if pkUser.userID == userInfo.userID {
                        pkUser.callUserState = userInfo.state
                        pkUser.extendedData = userInfo.extendedData
                        if !userInfo.extendedData.isEmpty {
                            let userData: PKExtendedData? = PKExtendedData.parse(extendedData: userInfo.extendedData)
                            if let userData = userData {
                                pkUser.userName = userData.userName ?? ""
                                pkUser.roomID = userData.roomID ?? ""
                            }
                        }
                        if pkUser.userID == localUser?.id {
                            pkUser.roomID = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
                            pkUser.userName = localUser?.name ?? ""
                            pkUser.camera = localUser?.isCameraOpen ?? false
                            pkUser.microphone = localUser?.isMicrophoneOpen ?? false
                        }
                        findIfAlreadyAdded = true
                        break
                    }
                }
                if !findIfAlreadyAdded {
                    let pkUser = PKUser(userID: userInfo.userID)
                    pkUser.callUserState = userInfo.state
                    pkUser.extendedData = userInfo.extendedData
                    if pkUser.userID == localUser?.id {
                        pkUser.roomID = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
                        pkUser.userName = localUser?.name ?? ""
                        pkUser.camera = localUser?.isCameraOpen ?? false
                        pkUser.microphone = localUser?.isMicrophoneOpen ?? false
                        pkInfo.pkUserList.insert(pkUser, at: 0)
                    } else {
                        if !userInfo.extendedData.isEmpty {
                            let userData: PKExtendedData? = PKExtendedData.parse(extendedData: userInfo.extendedData)
                            if let userData = userData {
                                pkUser.userName = userData.userName ?? ""
                                pkUser.roomID = userData.roomID ?? ""
                            }
                        }
                        pkInfo.pkUserList.append(pkUser)
                    }
                }
            }
            
            for userInfo in info.callUserList {
                if userInfo.state == .accepted {
                    let pkUser = getPKUser(pkBattleInfo: pkInfo, userID: userInfo.userID)
                    if let pkUser = pkUser {
                        for delegate in eventDelegates.allObjects {
                            delegate.onPKBattleAccepted?(userID: pkUser.userID, extendedData: pkUser.extendedData)
                        }
                    }
                    onReceivePKUserAccepted(userInfo: userInfo)
                } else if userInfo.state == .rejected {
                    for delegate in eventDelegates.allObjects {
                        delegate.onPKBattleRejected?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                    if let localUser = localUser {
                        checkIfPKEnd(requestID: requestID, currentUser: localUser)
                    }
                } else if userInfo.state == .timeout {
                    for delegate in eventDelegates.allObjects {
                        delegate.onPKBattleTimeout?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                    }
                    if let localUser = localUser {
                        checkIfPKEnd(requestID: requestID, currentUser: localUser)
                    }
                } else if userInfo.state == .quit {
                    onReceivePKUserQuit(requestID: requestID, userInfo: userInfo)
                    seiTimeDict.removeValue(forKey: userInfo.userID)
                }
            }
        }
    }
    
    
    private func onReceivePKUserAccepted(userInfo: ZIMCallUserInfo) {
        let pkExtendedData = PKExtendedData.parse(extendedData: userInfo.extendedData)
        guard let pkExtendedData = pkExtendedData,
        let pkInfo = pkInfo
        else { return }
        if (pkExtendedData.type == PKExtendedData.STARK_PK) {
                var moreThanOneAcceptedExceptMe = false
                var meHasAccepted = false
                for pkUser in pkInfo.pkUserList {
                    if pkUser.userID == localUser?.id {
                        meHasAccepted = pkUser.hasAccepted
                    } else {
                        if pkUser.hasAccepted {
                            moreThanOneAcceptedExceptMe = true
                        }
                    }

                }
            if (meHasAccepted && moreThanOneAcceptedExceptMe && !isPKStarted) {
                isPKStarted = true
                updatePKMixTask { errorCode, info in
                    if errorCode == 0 {
                        self.createSEITimer()
                        self.createCheckSERTimer()
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onPKStarted?()
                        }
                        for pkUser in pkInfo.pkUserList {
                            if pkUser.hasAccepted {
                                for delegate in self.eventDelegates.allObjects {
                                    delegate.onPKUserJoin?(userID: pkUser.userID, extendedData: pkUser.extendedData)
                                }
                            }
                        }
                    } else {
                        self.isPKStarted = false
                        self.quitPKBattle(requestID: pkInfo.requestID, callback: nil)
                    }
                }
            } else {
                updatePKMixTask { errorCode, info in
                    if errorCode == 0 {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onPKUserJoin?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                        }
                    }
                }
            }
        }
    }
    
    func onReceivePKRoomAttribute(roomProperties: [String: String]) {
        let request_id = roomProperties["request_id"]
        var pkUserList: [PKUser] = []
        let pkUsers: [Any] = roomProperties["pk_users"]?.jsonArray() ?? []
        for userDict in pkUsers {
            let userString: String = (userDict as! [String: Any]).jsonString
            let pkUser = PKUser.parse(string: userString)
            if !liveManager.isLocalUserHost() {
                pkUser.callUserState = .accepted
            }
            pkUserList.append(pkUser)
        }
        
        if liveManager.isLocalUserHost() {
            if pkInfo == nil {
                delectPKAttributes()
            }
        } else {
            for pkUser in pkUserList {
                seiTimeDict.updateValue(Int(Date().timeIntervalSince1970 * 1000), forKey: pkUser.userID)
            }
            if pkInfo == nil {
                if let _ = liveManager.hostUser {
                    pkInfo = PKInfo()
                    pkInfo?.requestID = request_id ?? ""
                    pkInfo?.pkUserList = pkUserList
                    createCheckSERTimer()
                    isPKStarted = true
                    
                    for delegate in eventDelegates.allObjects {
                        delegate.onPKStarted?()
                    }
                    for pkUser in pkInfo!.pkUserList {
                        if pkUser.hasAccepted {
                            for delegate in eventDelegates.allObjects {
                                delegate.onPKUserJoin?(userID: pkUser.userID, extendedData: pkUser.extendedData)
                            }
                        }
                    }
                }
            } else {
                pkInfo?.pkUserList = pkUserList
                for delegate in eventDelegates.allObjects {
                    delegate.onPKUserUpdate?(userList: pkUserList.map({ user in
                        return user.userID
                    }))
                }
            }
        }
    }
    
}
