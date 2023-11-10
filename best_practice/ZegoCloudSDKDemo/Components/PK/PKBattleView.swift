//
//  PKBattleView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/1.
//

import UIKit

class PKBattleView: UIView {
    
    var pkUser: PKUser? {
        didSet {
            foregroundView.user = pkUser
        }
    }
    var addVideoView: Bool = false
    
    var backgroundView: UIView! {
        didSet {
            backgroundView.backgroundColor = UIColor.blue
        }
    }
    var foregroundView: PKForegroundView!
    var connectingTipView: PKConnectingView!
    var videoView: VideoView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
        ZegoLiveStreamingManager.shared.addDelegate(self)
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
        
        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        foregroundView = PKForegroundView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        connectingTipView = PKConnectingView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        connectingTipView.isHidden = true
        
        videoView = VideoView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        self.addSubview(backgroundView)
        self.addSubview(videoView)
        self.addSubview(foregroundView)
        self.addSubview(connectingTipView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.backgroundColor = UIColor.blue
        backgroundView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        foregroundView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        connectingTipView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        videoView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
    
    func setPKUser(user: PKUser?, addVideoView: Bool) {
        let lastUser = pkUser
        pkUser = user
        self.addVideoView = addVideoView
        videoView.update(user?.userID, user?.userName)
        if let pkUser = pkUser {
            if addVideoView && user?.userID == ZegoSDKManager.shared.currentUser?.id {
                videoView.backgroundColor = UIColor.black
                ZegoSDKManager.shared.expressService.startPreview(videoView.renderView)
            } else {
                videoView.backgroundColor = UIColor.blue
                ZegoSDKManager.shared.expressService.startPlayingStream(videoView.renderView, streamID: pkUser.pkUserStream)
            }
        } else {
            if let lastUser = lastUser {
                ZegoSDKManager.shared.expressService.stopPlayingStream(lastUser.pkUserStream)
            }
        }
    }
    
    func mutePlayAudio(mute: Bool) {
        if let streamID = pkUser?.pkUserStream {
            ZegoSDKManager.shared.expressService.mutePlayStreamAudio(streamID: streamID, mute: mute)
        }
    }
    
}

extension PKBattleView: PKServiceDelegate, ZegoLiveStreamingManagerDelegate {
    
    func onPKUserCameraOpen(userID: String, isCameraOpen: Bool) {
        if userID == pkUser?.userID {
            backgroundView.isHidden = isCameraOpen
            videoView.enableCamera(isCameraOpen)
        }
    }
    
    func onPKUserConnecting(userID: String, duration: Int) {
        if userID == pkUser?.userID {
            let timeout = duration > 5000
            let pkUserMuted = ZegoLiveStreamingManager.shared.isPKUserMuted(userID: userID)
            if timeout {
                if !pkUserMuted {
                    ZegoLiveStreamingManager.shared.mutePKUser(muteUserList: [userID], mute: true) { errorCode, info in
                        if errorCode == 0 {
                            self.mutePlayAudio(mute: true)
                        }
                    }
                }
            } else {
                if pkUserMuted {
                    ZegoLiveStreamingManager.shared.mutePKUser(muteUserList: [userID], mute: false) { errorCode, info in
                        if errorCode == 0 {
                            self.mutePlayAudio(mute: false)
                        }
                    }
                }
            }
            connectingTipView.isHidden = duration > 5000 ? false : true
        }
    }   
    
    //MARK: -ZegoLiveStreamingManagerDelegate
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        if userID == pkUser?.userID {
            backgroundView.isHidden = isCameraOpen
            videoView.enableCamera(isCameraOpen)
        }
    }
}


