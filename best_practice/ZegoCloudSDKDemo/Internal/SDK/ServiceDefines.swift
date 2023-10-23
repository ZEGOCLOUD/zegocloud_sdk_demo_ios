//
//  ExpressDefine.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/6.
//

import Foundation


public typealias CommonCallback =  (_ code: Int, _ message: String) -> ()

public enum RoomRequestType: UInt, Codable {
    // Audience Apply To Become CoHost
    case applyCoHost = 10000
    
    // Audience Cancel CoHost Apply
    case cancelCoHostApply = 10001
    
    // Host Refuse Audience CoHost Apply
    case refuseCoHostApply = 10002
    
    // Host Accept Audience CoHost Apply
    case acceptCoHostApply = 10003
}

public enum RoomRequestAction: UInt, Codable {
    case request
    case accept
    case reject
    case cancel
}

public enum UserRole: UInt {
    case audience = 1
    case coHost = 2
    case host = 3
}
