//
//  CustomCommand.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/6.
//

import Foundation

public class RoomRequest: NSObject, Codable {
    public var requestID : String
    public var actionType: RoomRequestAction
    public var senderID: String
    public var receiverID: String
    public var extendedData: String
    
    public init(requestID: String = "", actionType: RoomRequestAction, senderID: String, receiverID: String, extendedData: String = "") {
        self.requestID = requestID
        self.actionType = actionType
        self.senderID = senderID
        self.receiverID = receiverID
        self.extendedData = extendedData
    }
    
    public func jsonString() -> String? {
        let jsonObject: [String: Any] = ["action_type" : actionType.rawValue, "sender_id": senderID, "receiver_id": receiverID, "request_id": requestID, "extended_data": extendedData]
        return jsonObject.jsonString
    }
}
