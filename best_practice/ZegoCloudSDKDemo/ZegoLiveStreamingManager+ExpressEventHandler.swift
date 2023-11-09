//
//  ZegoLiveStreamingManager+ExpressEventHandler.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/9.
//

import Foundation
import ZegoExpressEngine

extension ZegoLiveStreamingManager: ExpressServiceDelegate {
    
    func onReceiveStreamAdd(userList: [ZegoSDKUser]) {
        coHostService?.onReceiveStreamAdd(userList: userList)
        pkService?.onReceiveStreamAdd(userList: userList)
    }
    
    func onReceiveStreamRemove(userList: [ZegoSDKUser]) {
        coHostService?.onReceiveStreamRemove(userList: userList)
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        if updateType == .add {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomStreamAdd?(streamList: streamList)
            }
            for stream in streamList {
                let extraInfoDict = stream.extraInfo.toDict
                let isCameraOpen: Bool = extraInfoDict?["cam"] as! Bool
                let isMicOpen: Bool = extraInfoDict?["mic"] as! Bool
                for delegate in eventDelegates.allObjects {
                    delegate.onCameraOpen?(stream.user.userID, isCameraOpen: isCameraOpen)
                    delegate.onMicrophoneOpen?(stream.user.userID, isMicOpen: isMicOpen)
                }
            }
        } else {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomStreamDelete?(streamList: streamList)
            }
        }
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .add {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomUserAdd?(userList: userList)
            }
        } else {
            for delegate in eventDelegates.allObjects {
                delegate.onRoomUserDelete?(userList: userList)
            }
        }
        pkService?.onRoomUserUpdate(updateType, userList: userList, roomID: roomID)
    }
    
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        for delegate in eventDelegates.allObjects {
            delegate.onCameraOpen?(userID, isCameraOpen: isCameraOpen)
        }
    }
    
    func onMicrophoneOpen(_ userID: String, isMicOpen: Bool) {
        print("onMicrophoneOpen, userID: \(userID), isMicOpen: \(isMicOpen)")
        for delegate in eventDelegates.allObjects {
            delegate.onMicrophoneOpen?(userID, isMicOpen: isMicOpen)
        }
    }
    
    
    func onPlayerRecvAudioFirstFrame(_ streamID: String) {
        pkService?.onPlayerRecvAudioFirstFrame(streamID)
    }
    
    func onPlayerRecvVideoFirstFrame(_ streamID: String) {
        pkService?.onPlayerRecvVideoFirstFrame(streamID)
    }
    
    func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        pkService?.onPlayerSyncRecvSEI(data, streamID: streamID)
    }
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        
    }
    
}
