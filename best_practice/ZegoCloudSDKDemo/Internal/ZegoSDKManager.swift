//
//  ZegoSDKManager.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import UIKit
import ZegoExpressEngine
import ZIM

public class ZegoSDKManager: NSObject {
    
    public static let shared = ZegoSDKManager()
    
    public var expressService = ExpressService.shared
    public var zimService = ZIMService.shared
//    public var beautyService = ZegoEffectsService.shared
        
    public var currentUser: ZegoSDKUser? {
        expressService.currentUser
    }
    
    private var token: String? = nil
    
    private var appID: UInt32 = 0
    private var appSign: String = ""
    
    public func initWith(appID: UInt32, appSign: String, enableBeauty: Bool = false) {
        
        self.appID = appID
        self.appSign = appSign
        
        expressService.initWithAppID(appID: appID, appSign: appSign)
        zimService.initWithAppID(appID, appSign: appSign)
        
        if enableBeauty {
//            beautyService.initWithAppID(appID: appID, appSign: appSign)
//            enableCustomVideoProcessing()
        }
    }
    
    public func unInit() {
        zimService.unInit()
//        beautyService.unInit()
    }
    
    public func connectUser(userID: String,
                            userName: String,
                            token: String? = nil,
                            callback: CommonCallback? = nil) {
        self.token = token
        expressService.connectUser(userID: userID,userName: userName,token: token)
        zimService.connectUser(userID: userID, userName: userName, token: token, callback:callback)
    }
    
    public func disconnectUser() {
        expressService.logoutRoom(callback: nil)
        expressService.disconnectUser()
        zimService.leaveRoom(callback: nil)
        zimService.disconnectUser()
    }
    
    public func loginRoom(_ roomID: String,
                         roomName: String? = nil,
                         scenario: ZegoScenario,
                         callback: CommonCallback? = nil) {
        self.zimService.loginRoom(roomID, roomName: roomName, callback: { code, message in
            if (code == 0) {
                self.expressService.setRoomScenario(scenario: scenario)
                self.expressService.loginRoom(roomID, token: self.token) { code, data in
                    if code != 0 {
                        callback?(Int(code), "express loginRoom faild")
                    } else {
                        callback?(Int(code), "express loginRoom success")
                    }
                }
            } else {
                callback?(code, "zim loginRoom faild:\(message)")
            }
        })
    }
    
    
    public func logoutRoom(callback: CommonCallback? = nil) {
        var expressCode: Int32?
        var zimCode: Int?
        expressService.logoutRoom { code, data in
            expressCode = code
            if code == 0 {
                if let zimCode = zimCode {
                    if zimCode != 0 {
                        callback?(zimCode, "zim logoutRoom fail")
                    } else {
                        callback?(Int(code), "logoutRoom success")
                    }
                }
            } else {
                if let _ = zimCode {
                    callback?(Int(code), "express logoutRoom fail")
                }
            }
        }
        zimService.leaveRoom { roomID, error in
            zimCode = Int(error.code.rawValue)
            if zimCode == 0 {
                if let expressCode = expressCode {
                    if expressCode != 0 {
                        callback?(Int(expressCode), "express logoutRoom fail")
                    } else {
                        callback?(Int(error.code.rawValue), "logoutRoom success")
                    }
                }
            } else {
                if let _ = expressCode {
                    callback?(Int(error.code.rawValue), "zim logoutRoom fail")
                }
            }
        }
    }
    
    public func enableCustomVideoProcessing() {
        let config = ZegoCustomVideoProcessConfig()
        config.bufferType = .cvPixelBuffer
        expressService.enableCustomVideoProcessing(true, config: config)
        expressService.setCustomVideoProcessHandler(self)
    }
    
    public func uploadLog(callback: CommonCallback?) {
        self.expressService.uploadLog { expressCode in
            if expressCode == 0 {
                self.zimService.uploadLog { zimCode, message in
                    if zimCode == 0 {
                        guard let callback = callback else { return }
                        callback(0, "upload log success")
                    } else {
                        guard let callback = callback else { return }
                        callback(zimCode,"zim upload log fail")
                    }
                }
            } else {
                guard let callback = callback else { return }
                callback(Int(expressCode),"express upload log fail")
            }
        }
    }
    
    func getUser(_ userID: String) -> ZegoSDKUser? {
        let dict = expressService.inRoomUserDict;
        return dict[userID]
    }
}

extension ZegoSDKManager: ZegoCustomVideoProcessHandler {
    public func onStart(_ channel: ZegoPublishChannel) {
//        let config = expressService.getVideoConfig()
//        beautyService.initEnv(config.captureResolution)
    }
    
    public func onStop(_ channel: ZegoPublishChannel) {
//        beautyService.uninitEnv()
    }
    
    public func onCapturedUnprocessedCVPixelBuffer(_ buffer: CVPixelBuffer, timestamp: CMTime, channel: ZegoPublishChannel) {
//        beautyService.processImageBuffer(buffer)
//        expressService.sendCustomVideoProcessedCVPixelBuffer(buffer,
//                                                             timestamp: timestamp,
//                                                             channel: channel)
    }
}
