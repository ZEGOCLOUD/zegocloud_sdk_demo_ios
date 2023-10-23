//
//  ZegoLiveAudioRoomLayoutConfig.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2023/5/5.
//

import UIKit

public class ZegoLiveAudioRoomSeatConfig: NSObject {
    public var showSoundWaveInAudioMode: Bool = true
    public var backgroudColor: UIColor?
    public var backgroundImage: UIImage?
}

public class ZegoLiveAudioRoomLayoutConfig: NSObject {
    public var rowConfigs: [ZegoLiveAudioRoomLayoutRowConfig] = []
    public var rowSpecing: Int = 0
    
    public override init() {
        super.init()
        let firstConfigs = ZegoLiveAudioRoomLayoutRowConfig()
        firstConfigs.count = 4
        let secondConfig = ZegoLiveAudioRoomLayoutRowConfig()
        secondConfig.count = 4
        rowConfigs = [firstConfigs, secondConfig]
    }
}

public class ZegoLiveAudioRoomLayoutRowConfig: NSObject {
    
    public var count: Int = 0 {
        didSet {
            if count > 4 {
                count = 4
            }
        }
    }
    public var seatSpacing: Int = 0
}
