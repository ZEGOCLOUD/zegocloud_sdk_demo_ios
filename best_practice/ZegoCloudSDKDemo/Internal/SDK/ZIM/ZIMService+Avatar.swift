//
//  ZIMService+Command.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/7/5.
//

import Foundation
import ZIM

extension ZIMService {
    public func updateUserAvatarUrl(_ url: String, callback: @escaping ZIMUserAvatarUrlUpdatedCallback) {
        zim?.updateUserAvatarUrl(url, callback: { userAvatarUrl, errorInfo in
            if errorInfo.code == .ZIMErrorCodeSuccess {
                if let userID = self.userInfo?.userID {
                    self.usersAvatarUrlDict[userID] = url
                }
            }
            callback(userAvatarUrl, errorInfo)
        })
    }
    
    public func queryUsersInfo(_ userIDList: [String], callback: @escaping ZIMUsersInfoQueriedCallback) {
        let config = ZIMUsersInfoQueryConfig()
        zim?.queryUsersInfo(by: userIDList, config: config, callback: { userFullInfoList, errorUserInfoList, errorInfo in
            for userFullInfo in userFullInfoList {
                let userID: String = userFullInfo.baseInfo.userID
                let beforeValue: String = self.usersAvatarUrlDict[userID] ?? ""
                self.usersAvatarUrlDict[userID] = userFullInfo.userAvatarUrl
                self.usersNameDict[userID] = userFullInfo.baseInfo.userName
                if userFullInfo.userAvatarUrl != beforeValue {

                }
            }
            callback(userFullInfoList, errorUserInfoList, errorInfo)
        })
    }
    
    public func getUserAvatar(userID: String) -> String? {
        return self.usersAvatarUrlDict[userID]
    }
    
    public func getUserName(userID: String) -> String? {
        return self.usersNameDict[userID]
    }
}
