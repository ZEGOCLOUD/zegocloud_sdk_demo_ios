//
//  CoHostService.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/7/6.
//

import UIKit
import ZegoExpressEngine
import ZIM

@objc protocol CoHostServiceDelegate: AnyObject {
    @objc optional func onCoHostApplyListUpdate()
}

class CoHostService: NSObject {
    
    var hostUser: ZegoSDKUser?
    var coHostUserList: [ZegoSDKUser] = []
    
    let eventDelegates: NSHashTable<CoHostServiceDelegate> = NSHashTable(options: .weakMemory)
    
    var coHostArray: [CoHostInfo] {
        get {
            var array: [CoHostInfo] = []
            cohostRequestDict.forEach { (messageID, signalingProtocol) in
                let info = CoHostInfo(userID: signalingProtocol.senderID, userName: ZegoSDKManager.shared.getUser(signalingProtocol.senderID)?.name ?? "", messageID: messageID)
                array.append(info)
            }
            return array
        }
    }
    var cohostRequestDict: [String : RoomRequest] = [:]
    
    override init() {
        super.init()
    }
    
    func addCoHostDelegate(_ delegate: CoHostServiceDelegate) {
        eventDelegates.add(delegate)
    }
    
    func isHost(_ userID: String) -> Bool {
        guard let hostUser = hostUser else { return false }
        return hostUser.id == userID
    }

    func isCoHost(_ userID: String) -> Bool {
        for user in coHostUserList {
            if user.id == userID {
                return true
            }
        }
        return false
    }

    func isAudience(_ userID: String) -> Bool {
        if (isHost(userID) || isCoHost(userID)) {
            return false
        }
        return true
    }
    
    func isLocalUserHost() -> Bool {
        guard let localUser = ZegoSDKManager.shared.expressService.currentUser else { return false }
        return isHost(localUser.id);
    }
    
    func clearData() {
        coHostUserList.removeAll();
        cohostRequestDict.removeAll()
        hostUser = nil;
    }
    
    func rejectAllCohostRequest() {
        cohostRequestDict.forEach { (key, value) in
            //rejectCohost(receiverID: value.senderID, applyID: nil, callback: nil)
        }
        removeAllCohostData()
    }
    
    func removeCohostData(_ coHostID: String) {
        cohostRequestDict.removeValue(forKey: coHostID)
        for delegate in eventDelegates.allObjects {
            delegate.onCoHostApplyListUpdate?()
        }
    }
    
    func removeAllCohostData() {
        cohostRequestDict.removeAll()
        for delegate in eventDelegates.allObjects {
            delegate.onCoHostApplyListUpdate?()
        }
    }
    
    func setCohostData(_ messageID: String, signalingProtocol: RoomRequest) {
        cohostRequestDict.updateValue(signalingProtocol, forKey: messageID)
        for delegate in eventDelegates.allObjects {
            delegate.onCoHostApplyListUpdate?()
        }
    }

}

extension CoHostService {
    
    func onReceiveStreamAdd(userList: [ZegoSDKUser]) {
        for user in userList {
            if let streamID = user.streamID {
                if streamID.contains("_host") {
                    hostUser = user
                } else if streamID.contains("_cohost") {
                    coHostUserList.append(user)
                }
            }
        }
    }
    
    func onReceiveStreamRemove(userList: [ZegoSDKUser]) {
        for user in userList {
            if let streamID = user.streamID {
                if streamID.hasPrefix("_host") {
                    hostUser = nil
                } else if streamID.hasPrefix("_cohost") {
                    coHostUserList.removeAll { coHostUser in
                        return coHostUser.id == user.id
                    }
                }
            }
        }
    }
}
