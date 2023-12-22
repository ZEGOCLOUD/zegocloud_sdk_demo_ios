//
//  ZegoCallDataModel.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import UIKit
import ZIM

enum CallState: Int {
    case error
    case accept
    case wating
    case reject
    case cancel
    case timeout
}

enum CallType: Int {
    case video = 10000
    case voice = 10001
}

class CallUserInfo: NSObject {
    
    var userName: String? {
        get {
            return ZegoSDKManager.shared.zimService.getUserName(userID: userID ?? "")
        }
    }
    var userID: String?
    var callUserState: ZIMCallUserState = .unknown
    var extendedData: String = ""
    var headUrl: String? {
        get {
            return ZegoSDKManager.shared.zimService.getUserAvatar(userID: userID ?? "")
        }
    }
    var streamID: String {
        get {
            return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(userID ?? "")_main"
        }
    }
    
    var hasAccepted: Bool {
        get {
            return callUserState == .accepted
        }
    }
    
    var isWaiting: Bool {
        get {
            return callUserState == .received
        }
    }
    
    init(userID: String) {
        self.userID = userID
    }
    
}

class ZegoCallDataModel: NSObject {
    var callID: String?
    var inviter: CallUserInfo?
    var callUserList: [CallUserInfo] = []
    var type: CallType = .voice
    
    var isGroupCall: Bool {
        get {
            return callUserList.count > 2
        }
    }
}
