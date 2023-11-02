import Foundation
import ZIM

extension ZIMService {
    public func sendUserRequest(userList: [String],
                                config: ZIMCallInviteConfig,
                                callback: ZIMCallInvitationSentCallback?) {
        zim?.callInvite(with: userList, config: config, callback: { requestID, sentInfo, errorInfo in
            guard let callback = callback else { return }
            callback(requestID, sentInfo, errorInfo)
        })
    }
    
    public func addUserToRequest(invitees: [String],
                                 requestID: String,
                                 config: ZIMCallingInviteConfig,
                                 callback: ZIMCallingInvitationSentCallback?) {
        zim?.callingInvite(with: invitees, callID: requestID, config: config, callback: { requestID, sentInfo, errorInfo in
            guard let callback = callback else { return }
            callback(requestID,sentInfo,errorInfo)
        })
    }
        
    public func cancelUserRequest(requestID: String, config: ZIMCallCancelConfig, userList: [String], callback: ZIMCallCancelSentCallback?) {
        zim?.callCancel(with: userList, callID: requestID, config: config, callback: { requestID, errorInvitees, errorInfo in
            guard let callback = callback else { return }
            callback(requestID,errorInvitees,errorInfo)
        })
    }
        
    public func acceptUserRequest(requestID: String, config: ZIMCallAcceptConfig, callback: ZIMCallAcceptanceSentCallback?) {
        zim?.callAccept(with: requestID, config: config, callback: { requestID, errorInfo in
            guard let callback = callback else { return }
            callback(requestID,errorInfo)
        })
    }
        
    public func refuseUserRequest(requestID: String, config: ZIMCallRejectConfig, callback: ZIMCallRejectionSentCallback?) {
        zim?.callReject(with: requestID, config: config, callback: { requestID, errorInfo in
            guard let callback = callback else { return }
            callback(requestID,errorInfo)
        })
    }
    
    public func endUserRequest(requestID: String, config: ZIMCallEndConfig, callback: ZIMCallEndSentCallback?) {
        zim?.callEnd(by: requestID, config: config, callback: { requestID, info, error in
            guard let callback = callback else { return }
            callback(requestID,info,error)
        })
    }
    
    public func quitUserRequest(requestID: String, config: ZIMCallQuitConfig, callback: ZIMCallQuitSentCallback?) {
        zim?.callQuit(by: requestID, config: config, callback: { requestID, info, error in
            guard let callback = callback else { return }
            callback(requestID, info, error)
        })
    }
}
