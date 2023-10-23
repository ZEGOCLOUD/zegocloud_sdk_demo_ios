import Foundation
import ZIM

extension ZIMService: ZIMEventHandler {
    
    public func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, connectionStateChanged: state, event: event, extendedData: extendedData)
        }
    }
    
    // MARK: - Main
    public func zim(_ zim: ZIM, errorInfo: ZIMError) {
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, errorInfo: errorInfo)
        }
    }
    
    public func zim(_ zim: ZIM, tokenWillExpire second: UInt32) {
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, tokenWillExpire: second)
        }
    }
    
    public func zim(_ zim: ZIM, roomMemberJoined memberList: [ZIMUserInfo], roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, roomMemberJoined: memberList, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, roomMemberLeft memberList: [ZIMUserInfo], roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, roomMemberLeft: memberList, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, receiveRoomMessage messageList: [ZIMMessage], fromRoomID: String) {
        for message in messageList {
            if message is ZIMCommandMessage {
                let commandMessage = message as! ZIMCommandMessage
                let message: String = String(data: commandMessage.message, encoding: .utf8) ?? ""
                let messageDict: [String: Any] = message.toDict ?? [:]
                if messageDict.keys.contains("action_type") && userInfo != nil {
                    let sender = messageDict["sender_id"] as! String
                    let receiver = messageDict["receiver_id"] as! String
                    let extendedData: String = messageDict["extended_data"] as? String ?? ""
                    let actionType: RoomRequestAction = RoomRequestAction(rawValue: messageDict["action_type"] as! UInt) ?? .request
                    if userInfo?.userID == receiver {
                        switch actionType {
                        case .request:
                            let roomRequest: RoomRequest = RoomRequest(actionType: actionType, senderID: sender, receiverID: receiver)
                            roomRequest.extendedData = extendedData
                            roomRequest.requestID = "\(commandMessage.messageID)"
                            roomRequestDict.updateValue(roomRequest, forKey: roomRequest.requestID)
                            for delegate in eventHandlers.allObjects {
                                delegate.onInComingRoomRequestReceived?(requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
                            }
                        case .accept:
                            let requestID: String = messageDict["request_id"] as! String
                            let roomRequest: RoomRequest? = roomRequestDict[requestID]
                            if let roomRequest = roomRequest {
                                roomRequestDict.removeValue(forKey: requestID)
                                for delegate in eventHandlers.allObjects {
                                    delegate.onOutgoingRoomRequestAccepted?(requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
                                }
                            }
                        case .reject:
                            let requestID: String = messageDict["request_id"] as! String
                            let roomRequest: RoomRequest? = roomRequestDict[requestID]
                            if let roomRequest = roomRequest {
                                roomRequestDict.removeValue(forKey: requestID)
                                for delegate in eventHandlers.allObjects {
                                    delegate.onOutgoingRoomRequestRejected?(requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
                                }
                            }
                        case .cancel:
                            let requestID: String = messageDict["request_id"] as! String
                            let roomRequest: RoomRequest? = roomRequestDict[requestID]
                            roomRequestDict.removeValue(forKey: requestID)
                            if let roomRequest = roomRequest {
                                for delegate in eventHandlers.allObjects {
                                    delegate.onInComingRoomRequestCancelled?(requestID: roomRequest.requestID, extendedData: roomRequest.extendedData)
                                }
                            }
                        }
                    }
                } else {
                    for handler in eventHandlers.allObjects {
                        handler.onRoomCommandReceived?(senderID: commandMessage.senderUserID, command: message)
                    }
                }
            }
        }
        
        for handler in eventHandlers.allObjects {
            handler.zim?(zim, receiveRoomMessage: messageList, fromRoomID: fromRoomID)
        }
    }
    
    // MARK: - Invitation
    public func zim(_ zim: ZIM, callInvitationReceived info: ZIMCallInvitationReceivedInfo, callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onInComingUserRequestReceived?(requestID: callID, inviter: info.inviter, extendedData: info.extendedData)
            handler.zim?(zim, callInvitationReceived: info, callID: callID)
        }
    }
    
    public func zim(_ zim: ZIM, callInvitationAccepted info: ZIMCallInvitationAcceptedInfo, callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onOutgoingUserRequestAccepted?(requestID: callID, invitee: info.invitee, extendedData: info.extendedData)
            handler.zim?(zim, callInvitationAccepted: info, callID: callID)
        }
    }
    
    public func zim(_ zim: ZIM, callInvitationRejected info: ZIMCallInvitationRejectedInfo, callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onOutgoingUserRequestRejected?(requestID: callID, invitee: info.invitee, extendedData: info.extendedData)
            handler.zim?(zim, callInvitationRejected: info, callID: callID)
        }
    }
    
    public func zim(_ zim: ZIM, callInvitationCancelled info: ZIMCallInvitationCancelledInfo, callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onInComingUserRequestCancelled?(requestID: callID, inviter: info.inviter, extendedData: info.extendedData)
            handler.zim?(zim, callInvitationCancelled: info, callID: callID)
        }
    }
    
    public func zim(_ zim: ZIM, callInvitationTimeout callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onInComingUserRequestTimeout?(requestID: callID)
            handler.zim?(zim, callInvitationTimeout: callID)
        }
    }
    
    public func zim(_ zim: ZIM, callInviteesAnsweredTimeout invitees: [String], callID: String) {
        for handler in eventHandlers.allObjects {
            handler.onOutgoingUserRequestTimeout?(requestID: callID)
            handler.zim?(zim, callInviteesAnsweredTimeout: invitees, callID: callID)
        }
    }
    
    // MARK: - RoomAttributes
    public func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
        for (key, value) in updateInfo.roomAttributes {
            if updateInfo.action == .set {
                inRoomAttributsDict.updateValue(value, forKey: key)
            } else {
                inRoomAttributsDict.removeValue(forKey: key)
            }
        }
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, roomAttributesUpdated: updateInfo, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, roomAttributesBatchUpdated updateInfo: [ZIMRoomAttributesUpdateInfo], roomID: String) {
        for info in updateInfo {
            for (key,value) in info.roomAttributes {
                if info.action == .set {
                    inRoomAttributsDict.updateValue(value, forKey: key)
                } else {
                    inRoomAttributsDict.removeValue(forKey: key)
                }
            }
        }
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, roomAttributesBatchUpdated: updateInfo, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, conversationChanged conversationChangeInfoList: [ZIMConversationChangeInfo]) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, conversationChanged: conversationChangeInfoList)
        }
    }
    
    public func zim(_ zim: ZIM, conversationTotalUnreadMessageCountUpdated totalUnreadMessageCount: UInt32) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, conversationTotalUnreadMessageCountUpdated: totalUnreadMessageCount)
        }
    }
    
    public func zim(_ zim: ZIM, conversationMessageReceiptChanged infos: [ZIMMessageReceiptInfo]) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, conversationMessageReceiptChanged: infos)
        }
    }
    
    public func zim(_ zim: ZIM, receiveGroupMessage messageList: [ZIMMessage], fromGroupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, receiveGroupMessage: messageList, fromGroupID: fromGroupID)
        }
    }
    
    public func zim(_ zim: ZIM, messageRevokeReceived messageList: [ZIMRevokeMessage]) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, messageRevokeReceived: messageList)
        }
    }
    
    public func zim(_ zim: ZIM, messageReceiptChanged infos: [ZIMMessageReceiptInfo]) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, messageReceiptChanged: infos)
        }
    }
    
    public func zim(_ zim: ZIM, messageSentStatusChanged messageSentStatusChangeInfoList: [ZIMMessageSentStatusChangeInfo]) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, messageSentStatusChanged: messageSentStatusChangeInfoList)
        }
    }
    
    public func zim(_ zim: ZIM, roomStateChanged state: ZIMRoomState, event: ZIMRoomEvent, extendedData: [AnyHashable : Any], roomID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, roomStateChanged: state, event: event, extendedData: extendedData, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, roomMemberAttributesUpdated infos: [ZIMRoomMemberAttributesUpdateInfo], operatedInfo: ZIMRoomOperatedInfo, roomID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, roomMemberAttributesUpdated: infos, operatedInfo: operatedInfo, roomID: roomID)
        }
    }
    
    public func zim(_ zim: ZIM, groupStateChanged state: ZIMGroupState, event: ZIMGroupEvent, operatedInfo: ZIMGroupOperatedInfo, groupInfo: ZIMGroupFullInfo) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupStateChanged: state, event: event, operatedInfo: operatedInfo, groupInfo: groupInfo)
        }
    }
    
    public func zim(_ zim: ZIM, groupNameUpdated groupName: String, operatedInfo: ZIMGroupOperatedInfo, groupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupNameUpdated: groupName, operatedInfo: operatedInfo, groupID: groupID)
        }
    }
    
    public func zim(_ zim: ZIM, groupAvatarUrlUpdated groupAvatarUrl: String, operatedInfo: ZIMGroupOperatedInfo, groupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupAvatarUrlUpdated: groupAvatarUrl, operatedInfo: operatedInfo, groupID: groupID)
        }
    }
    
    public func zim(_ zim: ZIM, groupNoticeUpdated groupNotice: String, operatedInfo: ZIMGroupOperatedInfo, groupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupNoticeUpdated: groupNotice, operatedInfo: operatedInfo, groupID: groupID)
        }
    }
    
    public func zim(_ zim: ZIM, groupAttributesUpdated updateInfo: [ZIMGroupAttributesUpdateInfo], operatedInfo: ZIMGroupOperatedInfo, groupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupAttributesUpdated: updateInfo, operatedInfo: operatedInfo, groupID: groupID)
        }
    }
    
    public func zim(_ zim: ZIM, groupMemberInfoUpdated userInfo: [ZIMGroupMemberInfo], operatedInfo: ZIMGroupOperatedInfo, groupID: String) {
        for delegte in eventHandlers.allObjects {
            delegte.zim?(zim, groupMemberInfoUpdated: userInfo, operatedInfo: operatedInfo, groupID: groupID)
        }
    }
    
}
