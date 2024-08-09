import Foundation
import ZIM

public typealias RoomRequestCallback =  (_ code: UInt, _ message: String, _ requestID: String?) -> ()
public typealias RoomCommandCallback =  (_ code: UInt, _ message: String) -> ()

extension ZIMService {
            
    public func sendRoomRequest(_ receiverID: String, extendedData: String, callback: RoomRequestCallback?) {
        guard let currentUser = userInfo else { return }
        let roomRequest = RoomRequest(requestID: "", actionType: .request, senderID: currentUser.userID, receiverID: receiverID, extendedData: extendedData)
        sendCommand(command: roomRequest.jsonString() ?? "") { message, error in
            if error.code == .ZIMErrorCodeSuccess {
                roomRequest.requestID = "\(message.messageID)"
                var extendedDict: [String: Any] = extendedData.toDict ?? [:]
                extendedDict.updateValue(roomRequest.requestID as AnyObject, forKey: "request_id")
                roomRequest.extendedData = extendedDict.jsonString
                self.roomRequestDict.updateValue(roomRequest, forKey: roomRequest.requestID)
            }
            for delegate in self.eventHandlers.allObjects {
                delegate.onSendRoomRequest?(errorCode: error.code.rawValue, requestID: "\(message.messageID)", extendedData: extendedData)
            }
            callback?(error.code.rawValue, error.message, "\(message.messageID)")
        }
    }
    
    public func acceptRoomRequest(_ requestID: String, extendedData: String?, callback: RoomRequestCallback?) {
        guard let currentUser = userInfo,
              let roomRequest = self.roomRequestDict[requestID]
        else { return }
        roomRequest.actionType = .accept
        roomRequest.receiverID = roomRequest.senderID
        roomRequest.senderID = currentUser.userID
        if let extendedData = extendedData {
            roomRequest.extendedData = extendedData
        }
        sendCommand(command: roomRequest.jsonString() ?? "") { message, error in
            self.roomRequestDict.removeValue(forKey: roomRequest.requestID)
            for delegate in self.eventHandlers.allObjects {
                delegate.onAcceptIncomingRoomRequest?(errorCode: error.code.rawValue, requestID: requestID, extendedData: roomRequest.extendedData)
            }
            callback?(error.code.rawValue, error.message, "\(roomRequest.requestID)")
        }
        
    }
    
    public func rejectRoomRequest(_ requestID: String, extendedData: String?, callback: RoomRequestCallback?) {
        guard let currentUser = userInfo,
              let roomRequest = self.roomRequestDict[requestID]
        else { return }
        roomRequest.actionType = .reject
        roomRequest.receiverID = roomRequest.senderID
        roomRequest.senderID = currentUser.userID
        if let extendedData = extendedData {
            roomRequest.extendedData = extendedData
        }
        
        sendCommand(command: roomRequest.jsonString() ?? "") { message, error in
            self.roomRequestDict.removeValue(forKey: roomRequest.requestID)
            for delegate in self.eventHandlers.allObjects {
                delegate.onRejectIncomingRoomRequest?(errorCode: error.code.rawValue, requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
            }
            callback?(error.code.rawValue, error.message, "\(roomRequest.requestID)")
        }
    }
    
    public func cancelRoomRequest(_ requestID: String, extendedData: String?, callback: RoomRequestCallback?) {
        guard let _ = userInfo,
              let roomRequest = self.roomRequestDict[requestID]
        else { return }
        roomRequest.actionType = .cancel
        if let extendedData = extendedData {
            roomRequest.extendedData = extendedData
        }
        
        sendCommand(command: roomRequest.jsonString() ?? "") { message, error in
            self.roomRequestDict.removeValue(forKey: roomRequest.requestID)
            for delegate in self.eventHandlers.allObjects {
                delegate.onCancelRoomRequest?(errorCode: error.code.rawValue, requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
            }
            callback?(error.code.rawValue, error.message, "\(roomRequest.requestID)")
        }
    }
    
    private func sendCommand(command: String, callback: @escaping ZIMMessageSentCallback) {
        let bytes = command.data(using: .utf8)!
        let commandMessage = ZIMCommandMessage(message: bytes)
        zim?.sendMessage(commandMessage, toConversationID: currentRoom?.baseInfo.roomID ?? "", conversationType: .room, config: ZIMMessageSendConfig(), notification: nil, callback: callback)
    }
    
    public func sendRoomCommand(command: String, callback: RoomCommandCallback?) {
        let bytes = command.data(using: .utf8)!
        let commandMessage = ZIMCommandMessage(message: bytes)
        zim?.sendMessage(commandMessage, toConversationID: currentRoom?.baseInfo.roomID ?? "", conversationType: .room, config: ZIMMessageSendConfig(), notification: nil, callback: { message, error in
            guard let callback = callback else { return }
            callback(error.code.rawValue, error.message)
        })
    }
    
    public func getRoomRequestByRequestID(_ requestID: String) -> RoomRequest? {
        return roomRequestDict[requestID]
    }
    
    public func getRoomRequestBySenderID(userID: String) -> RoomRequest? {
        for roomRequest in roomRequestDict.values {
            if roomRequest.senderID == userID {
                return roomRequest
            }
        }
        return nil;
    }
    
    public func getRequestUserList() -> [String] {
        var userList: [String] = []
        if let userInfo = userInfo {
            for roomRequest in roomRequestDict.values {
                if (roomRequest.receiverID == userInfo.userID) {
                    userList.append(roomRequest.senderID)
                }
            }
        }
        return userList
    }
    
    public func removeAllRequest() {
        roomRequestDict.removeAll()
    }

}
