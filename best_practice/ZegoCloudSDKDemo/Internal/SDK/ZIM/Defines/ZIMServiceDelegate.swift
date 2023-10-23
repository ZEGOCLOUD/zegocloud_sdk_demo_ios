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
    
    
    @objc optional func onInComingUserRequestReceived(requestID: String, inviter: String, extendedData: String)
    @objc optional func onInComingUserRequestTimeout(requestID: String)
    @objc optional func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String)
    @objc optional func onOutgoingUserRequestTimeout(requestID: String)
    @objc optional func onOutgoingUserRequestAccepted(requestID: String, invitee: String, extendedData: String)
    @objc optional func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String)
    
    @objc optional func onRoomCommandReceived(senderID: String, command: String)
}
