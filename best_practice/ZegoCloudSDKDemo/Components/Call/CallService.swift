//
//  CallService.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/7/21.
//

import UIKit

class CallService: NSObject, ZegoCallManagerDelegate {
    
    static let shared = CallService()
        
    func initService() {
        ZegoCallManager.shared.addCallEventHandler(self)
    }
    
    func onInComingCallInvitationReceived(requestID: String, inviter: String, inviteeList: [String], extendedData: String) {
        let extendedDict: [String : Any] = extendedData.toDict ?? [:]
        let callType: CallType? = CallType(rawValue: extendedDict["type"] as? Int ?? -1)
        guard let callType = callType else { return }
        // receive call
        let inRoom: Bool = (ZegoSDKManager.shared.expressService.currentRoomID != nil)
        if inRoom || (ZegoCallManager.shared.currentCallData?.callID != requestID) {
            let extendedData: [String : Any] = ["type": callType.rawValue, "reason": "busy", "callID": requestID]
            ZegoCallManager.shared.rejectCallInvitationCauseBusy(requestID: requestID, extendedData: extendedData.jsonString, type: callType, callback: nil)
            return
        }
//        guard let inviter = ZegoCallManager.shared.currentCallData?.inviter?.userInfo else { return }
        let _ = ZegoIncomingCallDialog.show()
    }
}
