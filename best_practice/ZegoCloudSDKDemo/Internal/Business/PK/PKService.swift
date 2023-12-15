//
//  PKService.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/7/6.
//

import UIKit
import ZIM
import ZegoExpressEngine

typealias UserRequestCallback = (_ code: UInt, _ requestID: String) -> ()

let MixVideoSize: CGSize = CGSize(width: 486 * 2, height: 864)

@objc protocol PKServiceDelegate: AnyObject {
    
    @objc optional func onPKBattleReceived(requestID: String, info: ZIMCallInvitationReceivedInfo)
    @objc optional func onIncomingPKRequestCancelled()
    @objc optional func onOutgoingPKRequestAccepted()
    @objc optional func onOutgoingPKRequestRejected()
    @objc optional func onIncomingPKRequestTimeout()
    @objc optional func onOutgoingPKRequestTimeout()
    
    @objc optional func onPKStarted()
    @objc optional func onPKEnded()
    @objc optional func onPKViewAvaliable()
    @objc optional func onPKMixTaskFail(code: Int32)
    
    @objc optional func onPKUserQuit(userID: String, extendedData: String)
    @objc optional func onPKBattleAccepted(userID: String, extendedData: String)
    @objc optional func onPKBattleRejected(userID: String, extendedData: String)
    @objc optional func onPKBattleTimeout(userID: String, extendedData: String)
    @objc optional func onPKUserJoin(userID: String, extendedData: String)
    @objc optional func onPKUserUpdate(userList: [String])
    
    @objc optional func onPKUserConnecting(userID: String, duration: Int)
    @objc optional func onPKUserMicrophoneOpen(userID: String, isMicOpen: Bool)
    @objc optional func onPKUserCameraOpen(userID: String, isCameraOpen: Bool)
    
}



class PKService: NSObject {
    
    var pkInfo: PKInfo?
    var isPKStarted: Bool = false
    var pkRoomAttribute: [String: String] = [:]
    
    var seiTimer: Timer?
    var checkSEITimer: Timer?
    var seiTimeDict: [String: Any] = [:]
    var isLiveStart: Bool {
        get {
            return ZegoLiveStreamingManager.shared.isLiveStart
        }
    }
    
    let eventDelegates: NSHashTable<PKServiceDelegate> = NSHashTable(options: .weakMemory)
    let liveManager = ZegoLiveStreamingManager.shared
    
    var localUser: ZegoSDKUser? {
        get {
            return ZegoSDKManager.shared.currentUser
        }
    }
    private var currentMixerTask: ZegoMixerTask? {
        didSet {
            if currentMixerTask == nil {
                currentInputList.removeAll()
            }
        }
    }
    var currentInputList: [ZegoMixerInput] = []
    
    override init() {
        super.init()
        ZegoSDKManager.shared.zimService.addEventHandler(self)
    }
    
    func addPKDelegate(_ delegate: PKServiceDelegate) {
        eventDelegates.add(delegate)
    }
    
    private func getPKExtendedData(type: Int) -> String? {
        let currentRoomID: String = ZegoSDKManager.shared.expressService.currentRoomID ?? ""
        let data: PKExtendedData  = PKExtendedData()
        data.roomID = currentRoomID
        data.userName = ZegoSDKManager.shared.currentUser?.name
        data.type = type
        return data.toString()
    }
    
    private func sendUserRequest(userIDList: [String], extendedData: String, advanced: Bool, callback: ZIMCallInvitationSentCallback?) {
        let config = ZIMCallInviteConfig()
        config.timeout = 200
        if advanced {
            config.mode = .advanced
        }
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.sendUserRequest(userList: userIDList, config: config, callback: callback)
    }
    
    private func addUserToRequest(invitees: [String], requestID: String, callback: ZIMCallingInvitationSentCallback?) {
        let config: ZIMCallingInviteConfig = ZIMCallingInviteConfig()
        ZegoSDKManager.shared.zimService.addUserToRequest(invitees: invitees, requestID: requestID, config: config, callback: callback)
    }
    
    private func acceptUserRequest(requestID: String, extendedData: String, callback: ZIMCallAcceptanceSentCallback?) {
        let config = ZIMCallAcceptConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.acceptUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
    private func rejectUserRequest(requestID: String, extendedData: String, callback: ZIMCallRejectionSentCallback?) {
        let config = ZIMCallRejectConfig()
        config.extendedData = extendedData
        ZegoSDKManager.shared.zimService.refuseUserRequest(requestID: requestID, config: config, callback: callback)
    }
    
    private func cancelUserRequest(userID: String, requestID: String, extendedData: String,
                                   callback: ZIMCallCancelSentCallback?) {
        let config = ZIMCallCancelConfig()
        config.extendedData = extendedData;
        ZegoSDKManager.shared.zimService.cancelUserRequest(requestID: requestID, config: config, userList: [userID], callback: callback)
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
    
    func updatePKMixTask(callback: ZegoMixerStartCallback?) {
        guard let pkInfo = pkInfo else { return }
        var pkStreamList: [String] = []
        for pkUser in pkInfo.pkUserList {
            if pkUser.hasAccepted {
                pkStreamList.append(pkUser.pkUserStream)
            }
        }
        let videoConfig = ZegoMixerVideoConfig()
        videoConfig.resolution = MixVideoSize
        videoConfig.bitrate = 1500
        videoConfig.fps = 15
        var mixInputList: [ZegoMixerInput] = []
        if let layOutConfig = liveManager.getMixLayoutConfig(streamList: pkStreamList, videoConfig: videoConfig) {
            mixInputList = layOutConfig
        } else {
            mixInputList = getMixVideoInputs(streamList: pkStreamList, videoConfig: videoConfig)
        }
        currentInputList = mixInputList
        
        if let currentMixerTask = currentMixerTask {
            currentMixerTask.setInputList(mixInputList)
        } else {
            let mixStreamID = "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_mix"
            currentMixerTask = ZegoMixerTask(taskID: mixStreamID)
            currentMixerTask!.setVideoConfig(videoConfig)
            currentMixerTask!.setInputList(mixInputList)

            let mixerOutput: ZegoMixerOutput = ZegoMixerOutput(target: mixStreamID)
            var mixerOutputList: [ZegoMixerOutput] = []
            mixerOutputList.append(mixerOutput)
            currentMixerTask!.setOutputList(mixerOutputList)
            currentMixerTask!.enableSoundLevel(true)
            currentMixerTask!.setAudioConfig(ZegoMixerAudioConfig.default())
        }
        ZegoSDKManager.shared.expressService.startMixerTask(currentMixerTask!) { errorCode, info in
            if errorCode == 0 {
                self.updatePKRoomAttributes()
            } else {
                for delegate in self.eventDelegates.allObjects {
                    delegate.onPKMixTaskFail?(code: errorCode)
                }
            }
            guard let callback = callback else { return }
            callback(errorCode, info)
        }
    }
    
    private func getMixVideoInputs(streamList: [String], videoConfig: ZegoMixerVideoConfig) ->
    [ZegoMixerInput] {
        var inputList: [ZegoMixerInput] = []
        if (streamList.count == 2) {
            for i in 0...1 {
                let left = (Int(videoConfig.resolution.width) / streamList.count) * i
                let top = 0
                let width: Int = Int(MixVideoSize.width / 2)
                let height: Int = Int(MixVideoSize.height)
                let rect = CGRect(x: left, y: top, width: width, height: height)
                let input = ZegoMixerInput(streamID: streamList[i], contentType: .video, layout: rect)
                input.renderMode = .fill
                input.soundLevelID = 0
                input.volume = 100
                inputList.append(input)
            }
        } else if (streamList.count == 3) {
            for i in 0...(streamList.count - 1) {
                let left = i == 0 ? 0 : Int(MixVideoSize.width / 2);
                let top = i == 2 ? Int(MixVideoSize.height / 2) : 0;
                let width: Int = Int(MixVideoSize.width / 2)
                let height: Int = i == 0 ? Int(MixVideoSize.height) : Int(MixVideoSize.height / 2)
                let rect = CGRect(x: left, y: top, width: width, height: height)
                let input = ZegoMixerInput(streamID: streamList[i], contentType: .video, layout: rect)
                input.renderMode = .fill
                input.soundLevelID = 0
                input.volume = 100
                inputList.append(input)
            }
          } else if (streamList.count == 4) {
              let row: Int = 2
              let column: Int = 2
              let cellWidth = Int(Int(MixVideoSize.width) / column)
              let cellHeight = Int(Int(MixVideoSize.width) / row)
              var left: Int
              var top: Int
              for i in 0...(streamList.count - 1) {
                left = cellWidth * (i % column)
                top = cellHeight * (i < column ? 0 : 1)
                let rect = CGRect(x: left, y: top, width: cellWidth, height: cellHeight)
                let input = ZegoMixerInput(streamID: streamList[i], contentType: .video, layout: rect)
                input.renderMode = .fill
                input.soundLevelID = 0
                input.volume = 100
                inputList.append(input)
            }
          } else if (streamList.count == 5) {
              var lastLeft: Int = 0
              var height: Int = 432
              for i in 0...(streamList.count - 1) {
                  if (i == 2) {
                      lastLeft = 0
                  }
                  let width: Int = i < 2 ? Int(MixVideoSize.width / 2) : Int(MixVideoSize.width / 3)
                  let left = lastLeft + (width * (i < 2 ? i : (i - 2)))
                  let top: Int = i > 1 ? height : 0
                  let rect = CGRect(x: left, y: top, width: width, height: height)
                  let input = ZegoMixerInput(streamID: streamList[i], contentType: .video, layout: rect)
                  input.renderMode = .fill
                  input.soundLevelID = 0
                  input.volume = 100
                  inputList.append(input)
              }
          } else if (streamList.count > 5) {
              let row: Int = streamList.count % 3 == 0 ? (streamList.count / 3) : (streamList.count / 3) + 1;
              let column: Int = 3
              let cellWidth: Int = Int(MixVideoSize.width) / column
              let cellHeight: Int = Int(MixVideoSize.height) / row
              var left: Int
              var top: Int
              for i in 0...(streamList.count - 1) {
                  left = cellWidth * (i % column)
                  top = cellHeight * (i < column ? 0 : 1)
                  let rect = CGRect(x: left, y: top, width: cellWidth, height: cellHeight)
                  let input = ZegoMixerInput(streamID: streamList[i], contentType: .video, layout: rect)
                  input.renderMode = .fill
                  input.soundLevelID = 0
                  input.volume = 100
                  inputList.append(input)
              }
          }
        return inputList;
    }
    
    func onReceivePKUserQuit(requestID: String, userInfo: ZIMCallUserInfo) {
        if let pkInfo = pkInfo {
            let selfPKUser = getPKUser(pkBattleInfo: pkInfo, userID: localUser?.id ?? "")
            if let selfPKUser = selfPKUser,
               selfPKUser.hasAccepted
            {
                var moreThanOneAcceptedExceptMe: Bool = false
                var hasWaitingUser: Bool = false
                for pkUser in pkInfo.pkUserList {
                    if pkUser.userID != localUser?.id {
                        if pkUser.hasAccepted || pkUser.isWaiting {
                            hasWaitingUser = true
                        }
                        if pkUser.hasAccepted {
                            moreThanOneAcceptedExceptMe = true
                        }
                    }
                }
                if moreThanOneAcceptedExceptMe {
                    if isPKStarted {
                        updatePKMixTask { errorCode, info in
                            for delegate in self.eventDelegates.allObjects {
                                delegate.onPKUserQuit?(userID: userInfo.userID, extendedData: userInfo.extendedData)
                            }
                        }
                    }
                }
                if (!hasWaitingUser) {
                    quitPKBattle(requestID: requestID, callback: nil)
                    stopPKBattle()
                }
            }
        }
    }
    
    func getPKUser(pkBattleInfo: PKInfo, userID: String) -> PKUser? {
        for pkUser in pkBattleInfo.pkUserList {
            if pkUser.userID == userID {
                return pkUser
            }
        }
        return nil
    }
    
    func checkIfPKEnd(requestID: String, currentUser: ZegoSDKUser) {
        guard let pkInfo = pkInfo else { return }
        let selfPKUser = getPKUser(pkBattleInfo: pkInfo, userID: localUser?.id ?? "")
        if let selfPKUser = selfPKUser {
            if selfPKUser.hasAccepted {
                var hasWaitingUser: Bool = false;
                for pkUser in pkInfo.pkUserList {
                    if pkUser.userID != localUser?.id {
                        // except self
                        if pkUser.hasAccepted || pkUser.isWaiting {
                            hasWaitingUser = true
                        }
                    }
                }
                if (!hasWaitingUser) {
                    quitPKBattle(requestID: requestID, callback: nil)
                    stopPKBattle()
                }
            }
        }
        
    }
    
    public func removeUserFromPKBattle(userID: String) {
        if let pkInfo = pkInfo {
            var timeoutQuitUsers: [PKUser] = []
            for pkUser in pkInfo.pkUserList {
                if userID == pkUser.userID {
                    pkUser.callUserState = .quit
                    timeoutQuitUsers.append(pkUser)
                }
            }
            if (!timeoutQuitUsers.isEmpty) {
                for timeoutQuitUser in timeoutQuitUsers {
                    let callUserInfo: ZIMCallUserInfo = ZIMCallUserInfo()
                    callUserInfo.userID = timeoutQuitUser.userID
                    callUserInfo.extendedData = timeoutQuitUser.extendedData
                    callUserInfo.state = timeoutQuitUser.callUserState
                    onReceivePKUserQuit(requestID: pkInfo.requestID, userInfo: callUserInfo)
                }
            }
        }
        seiTimeDict.removeValue(forKey: userID)
    }
    
    public func invitePKbattle(targetUserIDList: [String], autoAccept: Bool,callback: UserRequestCallback?) {
        if let pkInfo = pkInfo {
            addUserToRequest(invitees: targetUserIDList, requestID: pkInfo.requestID) { requestID, info, error in
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        } else {
            pkInfo = PKInfo()
            let pkExtendedData: String? = getPKExtendedData(type: PKExtendedData.STARK_PK)
            var dataDict: [String: Any] = pkExtendedData?.toDict ?? [:]
            dataDict["user_id"] = localUser?.id
            dataDict["auto_accept"] = autoAccept
            sendUserRequest(userIDList: targetUserIDList, extendedData: dataDict.jsonString, advanced: true) { requestID, info, error in
                if error.code == .success {
                    self.pkInfo?.requestID = requestID
                    self.pkInfo?.pkUserList = []
                } else {
                    self.pkInfo = nil
                }
                guard let callback = callback else { return }
                callback(error.code.rawValue, requestID)
            }
        }
    }
    
    public func acceptPKBattle(requestID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            let extendedData = getPKExtendedData(type: PKExtendedData.STARK_PK) ?? ""
            acceptUserRequest(requestID: requestID, extendedData: extendedData) { requestID, error in
                if error.code != .success {
                    self.pkInfo = nil
                }
            }
        }
    }
    
    public func quitPKBattle(requestID: String, callback: ZIMCallQuitSentCallback?) {
        if isPKUser(userID: localUser?.id ?? "") {
            quitUserRequest(requestID: requestID, extendedData: "", callback: callback)
        }
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
        }
    }
    
    public func endPKBattle(requestID: String, callback: ZIMCallEndSentCallback?) {
        let extendedData = getPKExtendedData(type: PKExtendedData.STARK_PK) ?? ""
        if isPKUser(userID: localUser?.id ?? "") {
            endUserRequest(requestID: requestID, extendedData: extendedData, callback: callback)
        }
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
        }
    }
    
    public func cancelPKBattle(requestID: String, userID: String) {
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            let extendedData = getPKExtendedData(type: PKExtendedData.STARK_PK) ?? ""
            cancelUserRequest(userID: userID, requestID: requestID, extendedData: extendedData, callback: nil)
            self.pkInfo = nil
        }
    }
    
    public func isPKUser(userID: String) -> Bool {
        guard let pkInfo = pkInfo else { return false }
        for pkUser in pkInfo.pkUserList {
            if pkUser.userID == userID {
                return true
            }
        }
        return false
    }
    
    public func isPKUserMuted(userID: String) -> Bool {
        guard let pkInfo = pkInfo else { return false }
        for pkUser in pkInfo.pkUserList {
            if pkUser.userID == userID {
                return pkUser.isMute
            }
        }
        return false
    }
    
    public func rejectPKBattle(requestID: String) {
        let extendedData = getPKExtendedData(type: PKExtendedData.STARK_PK) ?? ""
        rejectUserRequest(requestID: requestID, extendedData: extendedData, callback: nil)
        if let pkInfo = pkInfo,
           pkInfo.requestID == requestID
        {
            self.pkInfo = nil
        }
    }

    
    func stopPKBattle() {
        if liveManager.isLocalUserHost() {
            delectPKAttributes()
            stopMixTask()
        } else {
            muteHostAudioVideo(mute: false)
        }
        pkInfo = nil
        destoryTimer()
        seiTimeDict.removeAll()
        isPKStarted = false
        for delegate in eventDelegates.allObjects {
            delegate.onPKEnded?()
        }
    }
    
    func stopPlayAnotherHostStream() {
        guard let pkInfo = pkInfo else { return }
        for pkUser in pkInfo.pkUserList {
            if pkUser.userID != liveManager.hostUser?.id {
                ZegoSDKManager.shared.expressService.stopPlayingStream(pkUser.pkUserStream)
            }
        }
    }
    
    func stopMixTask() {
        guard let currentMixerTask = currentMixerTask else { return }
        ZegoSDKManager.shared.expressService.stopMixerTask(currentMixerTask) { code in
            if code == 0 {
                self.currentMixerTask = nil
            }
        }
    }
    
    func updatePKRoomAttributes() {
        guard let pkInfo = pkInfo else { return }
        var pkDict: [String: String] = [:]
        if let hostUser = liveManager.hostUser {
            pkDict["host_user_id"] = hostUser.id
        }
        pkDict["request_id"] = pkInfo.requestID
        
        var pkAcceptedUserList: [PKUser] = []
        for pkUser in pkInfo.pkUserList {
            if pkUser.hasAccepted {
                pkAcceptedUserList.append(pkUser)
            }
        }
        for pkUser in pkAcceptedUserList {
            for zegoMixerInput in currentInputList {
                if pkUser.pkUserStream == zegoMixerInput.streamID {
                    pkUser.edgeInsets =  rectToEdgeInset(rect: zegoMixerInput.layout)
                }
            }
        }
        let pkUsers = pkAcceptedUserList.compactMap({ user in
            let userJson = user.toDict()
            return userJson
        })
        pkDict["pk_users"] = pkUsers.toJsonString()
        ZegoSDKManager.shared.zimService.setRoomAttributes(pkDict, isDeleteAfterOwnerLeft: false) { roomID, errorKeys, error in
            
        }
    }
    
    func rectToEdgeInset(rect: CGRect) -> UIEdgeInsets {
        let top = rect.origin.y
        let left = rect.origin.x
        let right = left + rect.width
        let bottom = top + rect.height
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    func delectPKAttributes() {
        if pkRoomAttribute.keys.isEmpty { return }
        if pkRoomAttribute.keys.contains("pk_users") {
            let keys: [String] = ["request_id", "host_user_id", "pk_users"]
            ZegoSDKManager.shared.zimService.deletedRoomAttributes(keys, callback: nil)
        }
    }
    
    func muteHostAudioVideo(mute: Bool) {
        guard let _ = liveManager.hostUser else { return }
        let hostMainStreamID: String = liveManager.getHostMainStreamID()
        ZegoSDKManager.shared.expressService.mutePlayStreamAudio(streamID: hostMainStreamID, mute: mute)
        ZegoSDKManager.shared.expressService.mutePlayStreamVideo(streamID: hostMainStreamID, mute: mute)
    }
    
    public func mutePKUser(muteIndexList: [Int], mute: Bool, callback: ZegoMixerStartCallback?) {
        guard let currentMixerTask = currentMixerTask,
              currentInputList.isEmpty
        else { return }
        
        var muteStreamList: [String] = []
        for index in muteIndexList {
            if index < currentInputList.count {
                let mixerInput = currentInputList[index]
                if mute {
                    mixerInput.contentType = .videoOnly
                    muteStreamList.append(mixerInput.streamID)
                } else {
                    mixerInput.contentType = .video
                }
            }
        }
        
        ZegoSDKManager.shared.expressService.startMixerTask(currentMixerTask) { errorCode, info in
            if errorCode == 0 {
                if let pkInfo = self.pkInfo {
                    for streamID in muteStreamList {
                        for pkUser in pkInfo.pkUserList {
                            if pkUser.pkUserStream == streamID {
                                pkUser.isMute = true
                                ZegoSDKManager.shared.expressService.mutePlayStreamAudio(streamID: streamID, mute: mute)
                            }
                        }
                    }
                }
            }
            guard let callback = callback else { return }
            callback(errorCode,info)
        }
    }
    
    func createSEITimer() {
        seiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
            let dict: [String : Any] = ["type": SEIType.deviceState.rawValue, "sender_id": ZegoSDKManager.shared.currentUser?.id ?? "", "mic": ZegoSDKManager.shared.expressService.currentUser?.isMicrophoneOpen ?? true, "cam": ZegoSDKManager.shared.currentUser?.isCameraOpen ?? true]
            
            ZegoSDKManager.shared.expressService.sendSEI(dict.jsonString)
        })
    }
    
    func createCheckSERTimer() {
        checkSEITimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            let currentTimer = Int(Date().timeIntervalSince1970 * 1000)
            self.seiTimeDict.forEach { (key,value) in
                let timerStamp: Int = value as! Int
                let duration = currentTimer - timerStamp
                for delegate in self.eventDelegates.allObjects {
                    delegate.onPKUserConnecting?(userID: key, duration: duration)
                }
            }
        })
    }
    
    func destoryTimer() {
        seiTimer?.invalidate()
        seiTimer = nil
        checkSEITimer?.invalidate()
        checkSEITimer = nil
    }
    
    func clearData() {
        destoryTimer()
        seiTimeDict.removeAll()
        pkRoomAttribute.removeAll()
        pkInfo = nil
        isPKStarted = false
    }
}
