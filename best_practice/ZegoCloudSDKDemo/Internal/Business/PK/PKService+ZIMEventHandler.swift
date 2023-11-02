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
                if let pkInfo = pkInfo {
                    stopPKBattles()
                } else {
                    continue
                }
            }
        }
    }
    
//    func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
//        if updateInfo.action == .set {
//            
//            let tempAnotherHost: String = pkInfo?.pkUser.id ?? ""
//            let tempAnotherHostRoomID : String = pkInfo?.pkRoom ?? ""
//            
//            pkInfo = PKInfo(user: ZegoSDKUser(id: updateInfo.roomAttributes["pk_user_id"] ?? "", name: updateInfo.roomAttributes["pk_user_name"] ?? ""), pkRoom: updateInfo.roomAttributes["pk_room"] ?? "")
//            pkInfo?.seq = Int(updateInfo.roomAttributes["pk_seq"] ?? "0") ?? 0
//            pkInfo?.hostUserID = updateInfo.roomAttributes["host"] ?? ""
//            
//            if pkInfo!.pkUser.id.count > 0 && pkInfo!.pkRoom.count > 0 {
//                if liveManager.isLocalUserHost() {
//                    //resume pk
//                    if pkRoomAttribute.isEmpty {
//                        sendPKBattleResumeRequest(userID: pkInfo?.pkUser.id ?? "")
//                    }
//                    pkRoomAttribute["host"] = pkInfo?.hostUserID ?? ""
//                    pkRoomAttribute["pk_room"] = pkInfo?.pkRoom ?? ""
//                    pkRoomAttribute["pk_user_id"] = pkInfo?.pkUser.id ?? ""
//                    pkRoomAttribute["pk_user_name"] = pkInfo?.pkUser.name ?? ""
//                    pkRoomAttribute["pk_seq"] =  "\(pkInfo?.seq ?? 0)"
//                    
//                } else {
//                    //play mixer
//                    roomPKState = .isStartPK
//                    for delegate in eventDelegates.allObjects {
//                        delegate.onPKStarted?(roomID: pkInfo?.pkRoom ?? "", userID: pkInfo?.pkUser.id ?? "")
//                        delegate.onStartPlayMixerStream?()
//                    }
//                    createCheckSERTimer()
//                }
//            } else {
//                for delegate in eventDelegates.allObjects {
//                    delegate.onPKEnded?(roomID: tempAnotherHostRoomID, userID: tempAnotherHost)
//                    delegate.onStopPlayMixerStream?()
//                }
//                clearData()
//            }
//            
//        } else {
//            for delegate in eventDelegates.allObjects {
//                delegate.onPKEnded?(roomID: pkInfo?.pkRoom ?? "", userID: pkInfo?.pkUser.id ?? "")
//                delegate.onStopPlayMixerStream?()
//            }
//            clearData()
//        }
//    }
    
    // pk invitation
    func onInComingUserRequestReceived(requestID: String, info: ZIMCallInvitationReceivedInfo) {
        let inviterExtendedData = PKExtendedData.parse(extendedData: info.extendedData)
        guard let inviterExtendedData = inviterExtendedData else { return }
        if inviterExtendedData.type == PKExtendedData.STARK_PK {
            let currentRoomID: String = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
            let userNotHost: Bool = currentRoomID.isEmpty || !liveManager.isLocalUserHost()
            if let _ = pkInfo,
               userNotHost
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
                delegate.onReceivePKBattleRequest?(requestID: requestID, inviter: info.inviter, userName: inviterExtendedData.userName ?? "", roomID: inviterExtendedData.roomID ?? "")
            }
        }
////        guard let invitationData = extendedData.toDict else { return }
//        let pkInvitation = PKInvitation()
//        let type: Int = invitationData["type"] as! Int
//        let pkType: PKProtocolType? = PKProtocolType(rawValue: UInt(type))
//        if let pkType = pkType,
//           !isPKBusiness(type: Int(pkType.rawValue))
//        {
//            return
//        }
//        if pkType == .startPK {
//            if !isLiveStart || roomPKState == .isStartPK || roomPKState == .isRequestPK || currentPkInvitation != nil{
//                rejectPKBattle(requestID: requestID)
////                rejectPKStartRequest(requestID: requestID)
//                return
//            }
//            pkInvitation.requestID = requestID
//            pkInvitation.roomID = invitationData["room_id"] as? String
//            pkInvitation.inviterName = invitationData["user_name"] as? String
//            pkInvitation.inviterID = inviter
//            currentPkInvitation = pkInvitation
//            for delegate in eventDelegates.allObjects {
//                delegate.onIncomingPKRequestReceived?(requestID: requestID)
//            }
//        } else if pkType == .endPK {
//            acceptPKStopRequest(requestID: requestID)
//            stopPKBattles()
//        } else if pkType == .resume {
//            if roomPKState != .isStartPK || !liveManager.isLocalUserHost() || !isLiveStart {
//                rejectPKResumeRequest(requestID: requestID)
//            } else {
//                acceptPKResumeRequest(requestID: requestID)
//            }
//        }
    }
    
    func onOutgoingUserRequestAccepted(requestID: String, invitee: String, extendedData: String) {
        guard let invitationData = extendedData.toDict else { return }
        let roomID = (invitationData["room_id"] ?? "") as! String
        let userName = (invitationData["user_name"] ?? "") as! String
        let type: Int = invitationData["type"] as! Int
        let pkType: PKProtocolType? = PKProtocolType(rawValue: UInt(type))
        if requestID == currentPkInvitation?.requestID {
            if pkType == .startPK || pkType == .resume {
                startPKBatlteWith(roomID: roomID, userID: currentPkInvitation?.invitee.first ?? "", userName: userName)
                for delegate in eventDelegates.allObjects {
                    delegate.onOutgoingPKRequestAccepted?()
                }
            }
        }
    }
    
    
    func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
            roomPKState = .isNoPK
            delectPKAttributes()
            for delegate in eventDelegates.allObjects {
                delegate.onOutgoingPKRequestRejected?()
            }
        }
    }
    
    func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
            for delegate in eventDelegates.allObjects {
                delegate.onIncomingPKRequestCancelled?()
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
    
    func onOutgoingUserRequestTimeout(requestID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
            roomPKState = .isNoPK
            for delegate in eventDelegates.allObjects {
                delegate.onOutgoingPKRequestTimeout?()
            }
        }
    }
    
    func onUserRequestEnded(info: ZIMCallInvitationEndedInfo, requestID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            stopPKBattles()
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
            if (meHasAccepted && moreThanOneAcceptedExceptMe && roomPKState != .isStartPK) {
                roomPKState = .isStartPK
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
                        self.roomPKState = .isNoPK
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
    
    private func onReceivePKRoomAttribute(roomProperties: [String: String]) {
        let request_id = roomProperties["request_id"]
        var pkUserList: [PKUser] = []
        let pkUsers: [Any] = roomProperties["pk_users"]?.jsonArray() ?? []
        for userString in pkUsers {
            let pkUser = PKUser.parse(string: userString as! String)
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
                if let hostUser = liveManager.hostUser {
                    pkInfo = PKInfo()
                    pkInfo?.requestID = request_id ?? ""
                    pkInfo?.pkUserList = pkUserList
                    createCheckSERTimer()
                    roomPKState = .isStartPK
                    
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
                
            }
        }
    }
    
}
