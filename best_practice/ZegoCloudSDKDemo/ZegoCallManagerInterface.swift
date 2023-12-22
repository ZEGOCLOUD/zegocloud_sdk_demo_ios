//
//  ZegoCallManagerInterface.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/22.
//

import Foundation
import ZIM

protocol CallManagerProtocol {
    func addCallEventHandler(_ handler: ZegoCallManagerDelegate)
    func inviteUserToJoinCall(_ targetUserID: [String], callback: CallRequestCallback?) 
    func sendVideoCallInvitation(_ targetUserID: String, callback: CallRequestCallback?)
    func sendVoiceCallInvitation(_ targetUserID: String, callback: CallRequestCallback?)
    func sendGroupVideoCallInvitation(_ targetUserIDs: [String], callback: CallRequestCallback?)
    func sendGroupVoiceCallInvitation(_ targetUserIDs: [String], callback: CallRequestCallback?)
    func quitCall(_ requestID: String, callback: ZIMCallQuitSentCallback?)
    func endCall(_ requestID: String, callback: ZIMCallEndSentCallback?)
    func rejectCallInvitation(requestID: String, callback: ZIMCallRejectionSentCallback?)
    func rejectCallInvitationCauseBusy(requestID: String,  extendedData: String, type: CallType, callback: ZIMCallRejectionSentCallback?)
    func acceptCallInvitation(requestID: String, callback: ZIMCallAcceptanceSentCallback?)
    
    func updateUserAvatarUrl(_ url: String, callback: @escaping ZIMUserAvatarUrlUpdatedCallback)
    func queryUsersInfo(_ userIDList: [String], callback: ZIMUsersInfoQueriedCallback?)
    func getUserAvatar(userID: String) -> String?
    
    func getMainStreamID() -> String
}
