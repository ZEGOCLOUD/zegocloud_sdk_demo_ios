//
//  ZegoCallDataModel.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import UIKit

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

class ZegoCallDataModel: NSObject {
    var callID: String?
    var inviter: ZegoSDKUser?
    var invitee: ZegoSDKUser?
    var type: CallType = .voice
    var callStatus: CallState = .error
    
    init(callID: String? = nil, inviter: ZegoSDKUser? = nil, invitee: ZegoSDKUser? = nil, type: CallType = .voice, callStatus: CallState = .error) {
        self.callID = callID
        self.inviter = inviter
        self.invitee = invitee
        self.type = type
        self.callStatus = callStatus
    }
}
