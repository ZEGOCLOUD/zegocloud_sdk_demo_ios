//
//  ZIMServiceDelegate.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/7/10.
//

import Foundation
import ZIM

@objc public protocol ZIMServiceDelegate: ZIMEventHandler {
    
    @objc optional func onSendRoomRequest(errorCode: UInt, requestID: String, extendedData: String)
    @objc optional func onCancelRoomRequest(errorCode: UInt, requestID: String, extendedData: String)
    @objc optional func onOutgoingRoomRequestAccepted(requestID: String, extendedData: String)
    @objc optional func onOutgoingRoomRequestRejected(requestID: String, extendedData: String)
    
    
    @objc optional func onInComingRoomRequestReceived(requestID: String, extendedData: String)
    @objc optional func onInComingRoomRequestCancelled(requestID: String, extendedData: String)
    @objc optional func onAcceptIncomingRoomRequest(errorCode: UInt, requestID: String, extendedData: String)
    @objc optional func onRejectIncomingRoomRequest(errorCode: UInt, requestID: String, extendedData: String)
    
    @objc optional func onUserRequestStateChanged(info: ZIMCallUserStateChangeInfo, requestID: String)
    @objc optional func onUserRequestEnded(info: ZIMCallInvitationEndedInfo, requestID: String)
    @objc optional func onInComingUserRequestReceived(requestID: String, info: ZIMCallInvitationReceivedInfo)
    @objc optional func onInComingUserRequestTimeout(requestID: String, info: ZIMCallInvitationTimeoutInfo?)
    
    @objc optional func onRoomCommandReceived(senderID: String, command: String)
    
    @objc optional func onRoomAttributesUpdated2(setProperties: [[String: String]], deleteProperties: [[String: String]])
}
