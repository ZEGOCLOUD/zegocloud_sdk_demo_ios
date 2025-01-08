//
//  ZegoCallPipView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2025/01/06.
//

import UIKit
import ZegoExpressEngine

class ZegoCallPipView: UIView {
    
    func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        
    }
    
    func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        
    }
    
    func updateCurrentPIPStreamID(streamID: String) {
        
    }

}
