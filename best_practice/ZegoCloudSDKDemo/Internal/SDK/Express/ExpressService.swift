//
//  ExpressService.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import Foundation
import ZegoExpressEngine

public class ExpressService: NSObject {
    
    public static let shared = ExpressService()
    
    public var currentUser: ZegoSDKUser?
    
    let eventHandlers: NSHashTable<ExpressServiceDelegate> = NSHashTable(options: .weakMemory)
    
    public var isUsingFrontCamera: Bool = true
    
    public var currentRoomID: String?
    
    // StreamID: UserID 
    public var streamDict: [String: String] = [:]
    
    // UserID: UserInfo
    public var inRoomUserDict: [String: ZegoSDKUser] = [:]
    
    public var roomExtraInfoDict: [String: ZegoRoomExtraInfo] = [:]
    
    public var currentMixerTask: ZegoMixerTask?
    
    public var currentScenario: ZegoScenario?
        
    public func initWithAppID(appID: UInt32, appSign: String, scenario: ZegoScenario = .default) {
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = scenario
        currentScenario = scenario
        let config: ZegoEngineConfig = ZegoEngineConfig()
        config.advancedConfig = ["notify_remote_device_unknown_status": "true", "notify_remote_device_init_status":"true"]
        ZegoExpressEngine.setEngineConfig(config)
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
    }
    
    public func setRoomScenario(scenario: ZegoScenario) {
        currentScenario = scenario
        ZegoExpressEngine.shared().setRoomScenario(scenario)
    }
    
    public func connectUser(userID: String,
                            userName: String? = nil, token: String?) {
        let userName = userName ?? userID
        currentUser = ZegoSDKUser(id: userID, name: userName)
    }
    
    public func disconnectUser() {
        currentUser = nil
    }
    
    public func uploadLog(callback: ZegoUploadLogResultCallback?) {
        ZegoExpressEngine.shared().uploadLog(callback)
    }
    
    public func addEventHandler(_ handler: ExpressServiceDelegate) {
        eventHandlers.add(handler)
    }
    
    public func removeEventHandler(_ handler: ExpressServiceDelegate) {
        for delegate in eventHandlers.allObjects {
            if delegate === handler {
                eventHandlers.remove(delegate)
            }
        }
    }
}
