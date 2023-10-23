//
//  ExpressService+EventHandler.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService: ZegoEventHandler {
    public func onDebugError(_ errorCode: Int32, funcName: String, info: String) {
        for handler in eventHandlers.allObjects {
            handler.onDebugError?(errorCode, funcName: funcName, info: info)
        }
    }
    
    public func onEngineStateUpdate(_ state: ZegoEngineState) {
        for handler in eventHandlers.allObjects {
            handler.onEngineStateUpdate?(state)
        }
    }
    
    public func onRecvExperimentalAPI(_ content: String) {
        for handler in eventHandlers.allObjects {
            handler.onRecvExperimentalAPI?(content)
        }
    }
    
    public func onFatalError(_ errorCode: Int32) {
        for handler in eventHandlers.allObjects {
            handler.onFatalError?(errorCode)
        }
    }
    
    // MARK: - Room
    public func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onRoomStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, roomID: roomID)
        }
    }
    
    public func onRoomStateChanged(_ reason: ZegoRoomStateChangedReason, errorCode: Int32, extendedData: [AnyHashable : Any], roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onRoomStateChanged?(reason, errorCode: errorCode, extendedData: extendedData, roomID: roomID)
        }
    }
    
    public func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .add {
            for user in userList {
                let user = inRoomUserDict[user.userID] ?? ZegoSDKUser(id: user.userID, name: user.userName)
                user.streamID = streamDict.first(where: { $0.value == user.id })?.key
                inRoomUserDict[user.id] = user
            }
        } else {
            for user in userList {
                inRoomUserDict.removeValue(forKey: user.userID)
            }
        }
        for handler in eventHandlers.allObjects {
            handler.onRoomUserUpdate?(updateType, userList: userList, roomID: roomID)
        }
    }
    
    public func onRoomOnlineUserCountUpdate(_ count: Int32, roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onRoomOnlineUserCountUpdate?(count, roomID: roomID)
        }
    }
    
    public func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        
        var userList: [ZegoSDKUser] = []
        for stream in streamList {
            var user = inRoomUserDict[stream.user.userID]
            if user == nil {
                user = ZegoSDKUser(id: stream.user.userID, name: stream.user.userName)
            }
            if updateType == .add {
                streamDict[stream.streamID] = stream.user.userID
                user?.streamID = stream.streamID
                user?.name = stream.user.userName
                inRoomUserDict[stream.user.userID] = user
            } else {
                streamDict.removeValue(forKey: stream.streamID)
                user?.streamID = nil
            }
            userList.append(user!)
        }
        
        for handler in eventHandlers.allObjects {
            if updateType == .add {
                handler.onReceiveStreamAdd?(userList: userList)
            } else {
                handler.onReceiveStreamRemove?(userList: userList)
            }
        }
        
        for handler in eventHandlers.allObjects {
            handler.onRoomStreamUpdate?(updateType, streamList: streamList, extendedData: extendedData, roomID: roomID)
        }
    }
        
    public func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        
        for stream in streamList {
            let userID = stream.user.userID
            let info = stream.extraInfo.toDict
            guard let user = inRoomUserDict[userID] else {
                continue
            }
            if let isCameraOpen = info?["cam"] as? Bool {
                user.isCameraOpen = isCameraOpen
                for handler in eventHandlers.allObjects {
                    handler.onCameraOpen?(userID, isCameraOpen: isCameraOpen)
                }
            }
            
            if let isMicOpen = info?["mic"] as? Bool {
                user.isMicrophoneOpen = isMicOpen
                for handler in eventHandlers.allObjects {
                    handler.onMicrophoneOpen?(userID, isMicOpen: isMicOpen)
                }
            }
        }
        
        for handler in eventHandlers.allObjects {
            handler.onRoomStreamExtraInfoUpdate?(streamList, roomID: roomID)
        }
    }
    
    public func onRoomExtraInfoUpdate(_ roomExtraInfoList: [ZegoRoomExtraInfo], roomID: String) {
        for extraInfo in roomExtraInfoList {
            let oldRoomExtraInfo = roomExtraInfoDict[extraInfo.key]
            if let oldRoomExtraInfo = oldRoomExtraInfo {
                if extraInfo.updateUser.userID == self.currentUser?.id {
                    continue
                }
                if extraInfo.updateTime < oldRoomExtraInfo.updateTime {
                    continue
                }
            }
            roomExtraInfoDict.updateValue(extraInfo, forKey: extraInfo.key)
        }
        
        for handler in eventHandlers.allObjects {
            handler.onRoomExtraInfoUpdate?(roomExtraInfoList, roomID: roomID)
            handler.onRoomExtraInfoUpdate2?(roomExtraInfoList, roomID: roomID)
        }
    }
    
    public func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onRoomTokenWillExpire?(remainTimeInSecond, roomID: roomID)
        }
    }
            
    // MARK: - Publisher
    public func onPublisherStateUpdate(_ state: ZegoPublisherState,
                                       errorCode: Int32,
                                       extendedData: [AnyHashable : Any]?,
                                       streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, streamID: streamID)
        }
    }
    
    public func onPublisherQualityUpdate(_ quality: ZegoPublishStreamQuality, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherQualityUpdate?(quality, streamID: streamID)
        }
    }
    
    public func onPublisherCapturedAudioFirstFrame() {
        for handler in eventHandlers.allObjects {
            handler.onPublisherCapturedAudioFirstFrame?()
        }
    }
    
    public func onPublisherCapturedVideoFirstFrame(_ channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherCapturedVideoFirstFrame?(channel)
        }
    }
    
    public func onPublisherSendAudioFirstFrame(_ channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherSendAudioFirstFrame?(channel)
        }
    }
    
    public func onPublisherSendVideoFirstFrame(_ channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherSendVideoFirstFrame?(channel)
        }
    }
    
    public func onPublisherRenderVideoFirstFrame(_ channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherRenderVideoFirstFrame?(channel)
        }
    }
    
    public func onPublisherVideoSizeChanged(_ size: CGSize, channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherVideoSizeChanged?(size, channel: channel)
        }
    }
    
    public func onPublisherRelayCDNStateUpdate(_ infoList: [ZegoStreamRelayCDNInfo], streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherRelayCDNStateUpdate?(infoList, streamID: streamID)
        }
    }
    
    public func onPublisherVideoEncoderChanged(_ fromCodecID: ZegoVideoCodecID, to toCodecID: ZegoVideoCodecID, channel: ZegoPublishChannel) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherVideoEncoderChanged?(fromCodecID, to: toCodecID, channel: channel)
        }
    }
    
    public func onPublisherStreamEvent(_ eventID: ZegoStreamEvent, streamID: String, extraInfo: String) {
        for handler in eventHandlers.allObjects {
            handler.onPublisherStreamEvent?(eventID, streamID: streamID, extraInfo: extraInfo)
        }
    }
    
    public func onVideoObjectSegmentationStateChanged(_ state: ZegoObjectSegmentationState, channel: ZegoPublishChannel, errorCode: Int32) {
        for handler in eventHandlers.allObjects {
            handler.onVideoObjectSegmentationStateChanged?(state, channel: channel, errorCode: errorCode)
        }
    }
    
    // MARK: - Player
    public func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, streamID: streamID)
        }
    }
    
    public func onPlayerQualityUpdate(_ quality: ZegoPlayStreamQuality, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerQualityUpdate?(quality, streamID: streamID)
        }
    }
    
    public func onPlayerMediaEvent(_ event: ZegoPlayerMediaEvent, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerMediaEvent?(event, streamID: streamID)
        }
    }
    
    public func onPlayerRecvAudioFirstFrame(_ streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerRecvAudioFirstFrame?(streamID)
        }
    }
    
    public func onPlayerRecvVideoFirstFrame(_ streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerRecvVideoFirstFrame?(streamID)
        }
    }
    
    public func onPlayerRenderVideoFirstFrame(_ streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerRenderVideoFirstFrame?(streamID)
        }
    }
    
    public func onPlayerRenderCameraVideoFirstFrame(_ streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerRenderCameraVideoFirstFrame?(streamID)
        }
    }
    
    public func onPlayerVideoSizeChanged(_ size: CGSize, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerVideoSizeChanged?(size, streamID: streamID)
        }
    }
        
    public func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerSyncRecvSEI?(data, streamID: streamID)
        }
    }
    
    public func onPlayerRecvAudioSideInfo(_ data: Data, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerRecvAudioSideInfo?(data, streamID: streamID)
        }
    }
    
    public func onPlayerLowFpsWarning(_ codecID: ZegoVideoCodecID, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerLowFpsWarning?(codecID, streamID: streamID)
        }
    }
    
    public func onPlayerStreamEvent(_ eventID: ZegoStreamEvent, streamID: String, extraInfo: String) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerStreamEvent?(eventID, streamID: streamID, extraInfo: extraInfo)
        }
    }
    
    public func onPlayerVideoSuperResolutionUpdate(_ streamID: String, state: ZegoSuperResolutionState, errorCode: Int32) {
        for handler in eventHandlers.allObjects {
            handler.onPlayerVideoSuperResolutionUpdate?(streamID, state: state, errorCode: errorCode)
        }
    }
    
    // MARK: - Mixer
    public func onMixerRelayCDNStateUpdate(_ infoList: [ZegoStreamRelayCDNInfo], taskID: String) {
        for handler in eventHandlers.allObjects {
            handler.onMixerRelayCDNStateUpdate?(infoList, taskID: taskID)
        }
    }
    
    public func onMixerSoundLevelUpdate(_ soundLevels: [NSNumber : NSNumber]) {
        for handler in eventHandlers.allObjects {
            handler.onMixerSoundLevelUpdate?(soundLevels)
        }
    }
    
    public func onAutoMixerSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        for handler in eventHandlers.allObjects {
            handler.onAutoMixerSoundLevelUpdate?(soundLevels)
        }
    }
    
    // MARK: - Device
    public func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        for handler in eventHandlers.allObjects {
            handler.onCapturedSoundLevelUpdate?(soundLevel)
        }
    }
    
    public func onCapturedSoundLevelInfoUpdate(_ soundLevelInfo: ZegoSoundLevelInfo) {
        for handler in eventHandlers.allObjects {
            handler.onCapturedSoundLevelInfoUpdate?(soundLevelInfo)
        }
    }
    
    public func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        for handler in eventHandlers.allObjects {
            handler.onRemoteSoundLevelUpdate?(soundLevels)
        }
    }
    
    public func onRemoteSoundLevelInfoUpdate(_ soundLevelInfos: [String : ZegoSoundLevelInfo]) {
        for handler in eventHandlers.allObjects {
            handler.onRemoteSoundLevelInfoUpdate?(soundLevelInfos)
        }
    }
    
    public func onCapturedAudioSpectrumUpdate(_ audioSpectrum: [NSNumber]) {
        for handler in eventHandlers.allObjects {
            handler.onCapturedAudioSpectrumUpdate?(audioSpectrum)
        }
    }
    
    public func onRemoteAudioSpectrumUpdate(_ audioSpectrums: [String : [NSNumber]]) {
        for handler in eventHandlers.allObjects {
            handler.onRemoteAudioSpectrumUpdate?(audioSpectrums)
        }
    }
    
    public func onLocalDeviceExceptionOccurred(_ exceptionType: ZegoDeviceExceptionType, deviceType: ZegoDeviceType, deviceID: String) {
        for handler in eventHandlers.allObjects {
            handler.onLocalDeviceExceptionOccurred?(exceptionType, deviceType: deviceType, deviceID: deviceID)
        }
    }
    
    public func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userID = streamDict[streamID]
        if let userID = userID {
            let user = inRoomUserDict[userID]
            user?.isCameraOpen = state == .open
        }
        
        for handler in eventHandlers.allObjects {
            if let userID = userID {
                handler.onCameraOpen?(userID, isCameraOpen: state == .open)
            }
            handler.onRemoteCameraStateUpdate?(state, streamID: streamID)
        }
    }
    
    public func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userID = streamDict[streamID]
        if let userID = userID {
            let user = inRoomUserDict[userID]
            user?.isMicrophoneOpen = state == .open
        }
        
        for handler in eventHandlers.allObjects {
            if let userID = userID {
                handler.onMicrophoneOpen?(userID, isMicOpen: state == .open)
            }
            handler.onRemoteMicStateUpdate?(state, streamID: streamID)
        }
    }
    
    public func onRemoteSpeakerStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        for handler in eventHandlers.allObjects {
            handler.onRemoteSpeakerStateUpdate?(state, streamID: streamID)
        }
    }
    
    public func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        for handler in eventHandlers.allObjects {
            handler.onAudioRouteChange?(audioRoute)
        }
    }
    
    public func onAudioVADStateUpdate(_ state: ZegoAudioVADType, monitorType type: ZegoAudioVADStableStateMonitorType) {
        for handler in eventHandlers.allObjects {
            handler.onAudioVADStateUpdate?(state, monitorType: type)
        }
    }
    
    // MARK: - IM
    public func onIMRecvBroadcastMessage(_ messageList: [ZegoBroadcastMessageInfo], roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onIMRecvBroadcastMessage?(messageList, roomID: roomID)
        }
    }
    
    public func onIMRecvBarrageMessage(_ messageList: [ZegoBarrageMessageInfo], roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onIMRecvBarrageMessage?(messageList, roomID: roomID)
        }
    }
    
    public func onIMRecvCustomCommand(_ command: String, from fromUser: ZegoUser, roomID: String) {
        for handler in eventHandlers.allObjects {
            handler.onIMRecvCustomCommand?(command, from: fromUser, roomID: roomID)
        }
    }
    
    // MARK: - Utilities
    public func onPerformanceStatusUpdate(_ status: ZegoPerformanceStatus) {
        for handler in eventHandlers.allObjects {
            handler.onPerformanceStatusUpdate?(status)
        }
    }
    
    public func onNetworkModeChanged(_ mode: ZegoNetworkMode) {
        for handler in eventHandlers.allObjects {
            handler.onNetworkModeChanged?(mode)
        }
    }
    
    public func onNetworkSpeedTestError(_ errorCode: Int32, type: ZegoNetworkSpeedTestType) {
        for handler in eventHandlers.allObjects {
            handler.onNetworkSpeedTestError?(errorCode, type: type)
        }
    }
    
    public func onNetworkSpeedTestQualityUpdate(_ quality: ZegoNetworkSpeedTestQuality, type: ZegoNetworkSpeedTestType) {
        for handler in eventHandlers.allObjects {
            handler.onNetworkSpeedTestQualityUpdate?(quality, type: type)
        }
    }
    
    public func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        for handler in eventHandlers.allObjects {
            handler.onNetworkQuality?(userID, upstreamQuality: upstreamQuality, downstreamQuality: downstreamQuality)
        }
    }
    
    public func onNetworkTimeSynchronized() {
        for handler in eventHandlers.allObjects {
            handler.onNetworkTimeSynchronized?()
        }
    }
}
