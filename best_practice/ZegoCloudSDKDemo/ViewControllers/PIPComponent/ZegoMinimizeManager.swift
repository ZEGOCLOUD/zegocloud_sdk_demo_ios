//
//  ZegoMinimizeManager.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2025/01/06.
//

import UIKit
import AVFoundation
import AVKit
import ZegoExpressEngine

protocol ZegoMinimizeManagerDelegate: AnyObject {
    func willStartPictureInPicture()
    func willStopPictureInPicture()
    func getCurrentPipRenderStreamID(streamsDict:[String:String]) -> String?
    
    func stopPipExitRoom()
}

extension ZegoMinimizeManagerDelegate {
    func willStartPictureInPicture() {}
    func willStopPictureInPicture() {}
    func getCurrentPipStreamID(streamsDict:[String:String]) {}
    
    func stopPipExitRoom(){}
}

class ZegoMinimizeManager: NSObject {
    
    var isNarrow: Bool = false {
        didSet {
            if isNarrow {
                startPip()
            }
        }
    }
    var isActive: Bool {
        get {
            return pipVC?.isPictureInPictureActive ?? false
        }
    }
    
    lazy var narrowWindow: ZegoCallNarrowWindow = {
        let narrow = ZegoCallNarrowWindow()
        return narrow
    }()
    
    var isEnablePip = false
    
    var isOneOnOneVideo: Bool = true
    var isPKStart: Bool = false
    var callVC: LiveStreamingViewController?
    var pipVC: AVPictureInPictureController?
    var pipView: ZegoCallVideoPipView?
    var pipAudioView: ZegoCallAudioPipView?
    
    weak var delegate: ZegoMinimizeManagerDelegate?
    
    static let shared = ZegoMinimizeManager()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    func setupAudioSession() {
        if #available(iOS 15.0, *) {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("PermissionFailed to set audio session, error: \(error)")
                }
            }
        }
    }
    
    
    func checkIsPictureInPictureSupported() -> Bool {
        var supportPip = false
        if #available(iOS 15.0, *) {
            supportPip = AVPictureInPictureController.isPictureInPictureSupported()
        }
        return supportPip
    }
    func setupPipControllerWithSourceView(sourceView: UIView, isOneOnOneVideo: Bool) {
        
        if checkIsPictureInPictureSupported() == false {
            return
        }
        
        self.isOneOnOneVideo = isOneOnOneVideo
        if let _ = pipVC {
            destroy()
        }
        if #available(iOS 15.0, *) {
            ExpressService.shared.addEventHandler(self)
            if isOneOnOneVideo {
                let callViewController = AVPictureInPictureVideoCallViewController();
                callViewController.preferredContentSize = CGSize(width: isOneOnOneVideo ? 9 : 1, height: isOneOnOneVideo ? 16 : 1)
                
                let pipContentSource = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: sourceView, contentViewController: callViewController)
                
                let pipController = AVPictureInPictureController(contentSource: pipContentSource)
                pipController.canStartPictureInPictureAutomaticallyFromInline = true
                pipController.delegate = self
                pipVC = pipController
                
                NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
            } else {
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func enableMultiTaskForZegoSDK(enable: Bool) {
        var params: String!
        if (enable){
            params = "{\"method\":\"liveroom.video.enable_ios_multitask\",\"params\":{\"enable\":true}}"
        } else {
            params = "{\"method\":\"liveroom.video.enable_ios_multitask\",\"params\":{\"enable\":false}}"
        }
        ExpressService.shared.callExperimentalAPI(params: params)
    }
    
    @objc func handleNotification(notification : NSNotification) {
        if notification.name == UIApplication.didBecomeActiveNotification {
            if !isNarrow {
                stopPiP()
            }
            pipView?.isEnablePreview = false
            pipView?.displayView.isHidden = true
        } else if notification.name == UIApplication.didEnterBackgroundNotification {
            
            getAllStreamIDAndUpdatePipStreamID()
            pipView?.isEnablePreview = false
        }
    }
    
    func getAllStreamIDAndUpdatePipStreamID() {
        var streamDict:[String:String] = ZegoSDKManager.shared.expressService.streamDict
        
        if isPKStart == true  {
            if ZegoLiveStreamingManager.shared.isHost(userID: ZegoSDKManager.shared.currentUser?.id ?? "") == true {
                // 房主
                guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
                streamDict.removeAll()
                for pkUser in pkInfo.pkUserList {
                    if pkUser.hasAccepted {
                        if pkUser.userID == ZegoSDKManager.shared.currentUser?.id {
                            
                        } else {
                            streamDict[pkUser.pkUserStream] = pkUser.userID
                        }
                    }
                }
            } else {
                streamDict.removeAll()
            }

        }
        
        let streamID:String = (self.delegate?.getCurrentPipRenderStreamID(streamsDict: streamDict) ?? "") as String
        if streamID.count > 0 {
            pipView?.updateCurrentPIPStreamID(streamID: streamID)
        }
    }
    
    func startPIPWithView(view: UIView) {
        if let pipView = self.pipView {
            pipView.removeFromSuperview()
            self.pipView = nil
        }
        view.backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
        self.isPKStart = ZegoLiveStreamingManager.shared.isPKStarted
        self.pipView = ZegoCallVideoPipView(frame: CGRectZero,isPKStart:self.isPKStart)
        self.pipView?.delegate = self
        if ZegoSDKManager.shared.expressService.currentUser?.streamID?.count ?? 0 > 0 {
            pipView?.isEnablePreview = true
        } else {
            pipView?.isEnablePreview = false
        }
        getAllStreamIDAndUpdatePipStreamID()
        view.addSubview(self.pipView!)
        self.pipView!.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.pipView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.pipView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.pipView!.topAnchor.constraint(equalTo: view.topAnchor),
            self.pipView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func stopPiP() {
        if #available(iOS 15.0, *) {
            if isOneOnOneVideo {
                guard let pipVC = pipVC else { return }
                if pipVC.isPictureInPictureActive {
                    isNarrow = false
                    pipVC.stopPictureInPicture()
                }
            } else {
                narrowWindow.closeNarrowWindow()
                callVC?.willStopPictureInPicture()
            }
        }
    }
    func startPip() {
        if #available(iOS 15.0, *) {
            if isOneOnOneVideo {
                guard let pipVC = pipVC else { return }
                pipVC.startPictureInPicture()
            } else {
                if let pipAudioView = pipAudioView {
                    pipAudioView.removeFromSuperview()
                    self.pipAudioView = nil
                }
                pipAudioView = ZegoCallAudioPipView()
                let desFrame: CGRect = CGRectMake(UIScreen.main.bounds.width - 65, 51 + ZegoCallNarrowWindow.getStatusBarHight(), 60, 60)
                self.narrowWindow.showNarrowWindow(contentView: pipAudioView!, desFrame: desFrame)
            }
        }
    }
    
    func destroy() {
        if #available(iOS 15.0, *) {
            stopPiP()
            pipVC?.contentSource = nil
            pipVC = nil
        }
    }
    
    func updateCallTime(time: String) {
        destroy()
        pipAudioView?.updateTime(time: time)
    }
    
}
extension ZegoMinimizeManager : ZegopipRenderDelegate {
    func stopPip() {
        delegate?.stopPipExitRoom()
        DispatchQueue.main.async {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            exit(0)
        }
    }
}

extension ZegoMinimizeManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        enableMultiTaskForZegoSDK(enable: true)
        if #available(iOS 15.0, *) {
            let vc: AVPictureInPictureVideoCallViewController? =
            pictureInPictureController.contentSource?.activeVideoCallContentViewController
            guard let vc = vc else { return }
            vc.view.backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
            startPIPWithView(view: vc.view)
        }
        delegate?.willStartPictureInPicture()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        debugPrint("pictureInPictureControllerDidStartPictureInPicture")
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        enableMultiTaskForZegoSDK(enable: false)
        delegate?.willStopPictureInPicture()
        pipView?.removeFromSuperview()
        if #available(iOS 15.0, *) {
            pictureInPictureController.contentSource?.activeVideoCallContentViewController.view.backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
        } else {
            // Fallback on earlier versions
        }
        debugPrint("pictureInPictureControllerWillStopPictureInPicture")
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        debugPrint("pictureInPictureControllerDidStopPictureInPicture")
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        debugPrint("failedToStartPictureInPictureWithError")
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        debugPrint("restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        completionHandler(true)
    }
}

extension ZegoMinimizeManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        
    }
}

extension ZegoMinimizeManager: ExpressServiceDelegate {
    func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        pipView?.onRemoteVideoFrameCVPixelBuffer(buffer, param: param, streamID: streamID)
    }
    
    func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        pipView?.onCapturedVideoFrameCVPixelBuffer(buffer, param: param, flipMode: flipMode, channel: channel)
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        pipView?.onRemoteSoundLevelUpdate(soundLevels)
    }
    
}
