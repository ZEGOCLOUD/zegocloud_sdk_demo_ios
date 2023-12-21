//
//  ZIMService.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by zego on 2023/4/28.
//

import Foundation
import UIKit
import ZIM

public class ZIMService: NSObject {
    
    public static let shared = ZIMService()
    
    var zim: ZIM? = nil
    var userInfo: ZIMUserInfo? = nil
    
    var currentRoom: ZIMRoomFullInfo? {
        didSet {
            guard let currentRoom = currentRoom else {
                print("currentRoom is nil")
                return
            }
            print("currentRoom : \(currentRoom.baseInfo.roomID)")
        }
    }
    var inRoomAttributsDict: [String : String] = [:]
    var roomRequestDict: [String : RoomRequest] = [:]
    var usersAvatarUrlDict: [String: String] = [:]
    var usersNameDict: [String: String] = [:]
    
    let eventHandlers: NSHashTable<ZIMServiceDelegate> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
    }
    
    public func initWithAppID(_ appID: UInt32, appSign: String?) {
        let zimConfig: ZIMAppConfig = ZIMAppConfig()
        zimConfig.appID = appID
        zimConfig.appSign = appSign ?? ""
        self.zim = ZIM.shared()
        if self.zim == nil {
            self.zim = ZIM.create(with: zimConfig)
        }
        self.zim?.setEventHandler(self)
    }
    
    public func unInit() {
        
    }
    
    public func connectUser(userID: String,
                            userName: String,
                            token: String?,
                            callback: CommonCallback?) {
        let user = ZIMUserInfo()
        user.userID = userID
        user.userName = userName
        userInfo = user
        usersNameDict[userID] = userName
        zim?.login(with: user, token: token ?? "") { error in
            callback?(Int(error.code.rawValue), error.message)
        }
    }
    
    public func disconnectUser() {
        zim?.logout()
    }
    

    public func addEventHandler(_ handler: ZIMServiceDelegate) {
        eventHandlers.add(handler)
    }
    
    public func removeEventHandler(_ handler: ZIMServiceDelegate) {
        for delegate in eventHandlers.allObjects {
            if delegate === handler {
                eventHandlers.remove(delegate)
            }
        }
    }
    
    public func renewToken(_ token: String, callback: CommonCallback?) {
        zim?.renewToken(token) { token, error in
            callback?(Int(error.code.rawValue), error.message)
        }
    }
    
    func removeRoomData() {
        currentRoom = nil
        inRoomAttributsDict.removeAll()
        roomRequestDict.removeAll()
    }
    
    public func uploadLog(callback: CommonCallback?) {
        zim?.uploadLog(with: { error in
            callback?(Int(error.code.rawValue), error.message)
        })
    }
}
