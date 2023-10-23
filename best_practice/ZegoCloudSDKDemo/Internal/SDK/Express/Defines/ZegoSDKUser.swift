//
//  UserInfo.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import Foundation

public class ZegoSDKUser: NSObject {
    public var id: String
    
    public var name: String
        
    public var isMicrophoneOpen = true
    
    public var isCameraOpen = true
    
    public var streamID: String?
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
