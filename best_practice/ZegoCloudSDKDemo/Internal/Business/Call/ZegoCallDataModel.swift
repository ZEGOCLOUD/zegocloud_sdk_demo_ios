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
    
    var userInfo: ZegoSDKUser?
    var callUserState: ZIMCallUserState = .unknown
    var extendedData: String = ""
    var streamID: String {
        get {
            return "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_\(userInfo?.id ?? "")_main"
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
    
    init(userInfo: ZegoSDKUser? = nil) {
        self.userInfo = userInfo
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
