//
//  LiveViewController.swift
//  ScreenShareDemo
//
//  Created by Kael Ding on 2023/5/15.
//

import UIKit
import ZegoExpressEngine

let screenShareExtensionIdentifier = "com.zegocloud.ScreenShareDemo.ScreenShareDemoScreenShare"

class LiveViewController: UIViewController {
    
    @IBOutlet weak var mainStreamView: VideoView!
    @IBOutlet weak var smallStreamView: VideoView!
    @IBOutlet weak var cameraButton: UIButton! {
        didSet {
            cameraButton.setTitle("Disable Camera", for: .normal)
            cameraButton.setTitle("Enable Camera", for: .selected)
        }
    }
    @IBOutlet weak var screenShareButton: UIButton! {
        didSet {
            screenShareButton.setTitle("Start Screen Sharing", for: .normal)
            screenShareButton.setTitle("Stop Screen Sharing", for: .selected)
        }
    }
    @IBOutlet weak var shareStatusLabel: UILabel!
    
    var isMySelfHost: Bool = false
    var liveID: String = ""
    var userID: String = ""
    var userName: String = ""
    
    var isScreenSharing: Bool = false
    
    var currentMainStreamID: String = ""
    var currentScreenShareStreamID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        ZegoExpressEngine.shared().setEventHandler(self)
        
        configUI()
        configScreenCapture()
    }
    
    func configUI() {
        smallStreamView.isHidden = true
        cameraButton.isHidden = !isMySelfHost
        screenShareButton.isHidden = !isMySelfHost
        
        loginRoom()
        
        if isMySelfHost {
            startPreview(mainStreamView.renderView)
            startPublish()
        }
    }
    
    func configScreenCapture() {
        ZegoExpressEngine.shared().setVideoSource(.screenCapture, channel: .aux)
        ZegoExpressEngine.shared().setAudioSource(.screenCapture, channel: .aux)
        
        let videoConfig = ZegoVideoConfig(preset: .preset1080P)
        ZegoExpressEngine.shared().setVideoConfig(videoConfig, channel: .aux)
    }
    
    func loginRoom() {
        let user = ZegoUser(userID: userID, userName: userName)
        ZegoExpressEngine.shared().loginRoom(liveID, user: user)
    }
    
    func logoutRoom() {
        ZegoExpressEngine.shared().logoutRoom()
    }
    
    func startPreview(_ view: UIView) {
        let canvas = ZegoCanvas(view: view)
        ZegoExpressEngine.shared().startPreview(canvas)
    }
    
    func startPublish() {
        ZegoExpressEngine.shared().startPublishingStream(mainStreamID())
    }
    
    func startPlayingMainStream(_ streamID: String, view: UIView) {
        let canvas = ZegoCanvas(view: view)
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
    }
    
    func startPlayingScreenShareStream(_ streamID: String, view: UIView) {
        let canvas = ZegoCanvas(view: view)
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
    }
    
    func stopPlayingStream(_ streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
    
    func startScreenCapture() {
        let config = ZegoScreenCaptureConfig()
        config.captureAudio = true
        config.captureVideo = true
        ZegoExpressEngine.shared().startScreenCapture(config)
        ZegoExpressEngine.shared().startPublishingStream(screenShareStreamID(), channel: .aux)
        smallStreamView.isHidden = false
        startPreview(smallStreamView.renderView)
    }
    
    func stopScreenCapture() {
        ZegoExpressEngine.shared().stopScreenCapture()
        ZegoExpressEngine.shared().stopPublishingStream(.aux)
        
        smallStreamView.isHidden = true
        startPreview(mainStreamView.renderView)
    }
    
    func mainStreamID() -> String {
        "\(liveID)_\(userID)_main"
    }
    
    func screenShareStreamID() -> String {
        "\(liveID)_\(userID)_screen_share"
    }
    
    @IBAction func closeAction(_ sender: Any) {
        func leaveRoom() {
            logoutRoom()
            dismiss(animated: true)
        }
        
        if !isMySelfHost {
            leaveRoom()
            return
        }
        let alert = UIAlertController(title: "Stop the Live", message: "Are you sure to stop the live?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let okAction = UIAlertAction(title: "Stop it", style: .default) { _ in
            leaveRoom()
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    @IBAction func cameraAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let isCameraEnabled = !sender.isSelected
        ZegoExpressEngine.shared().enableCamera(isCameraEnabled)
        let dict = ["isCameraEnabled": isCameraEnabled]
        ZegoExpressEngine.shared().setStreamExtraInfo(dict.jsonString)
        if isScreenSharing {
            smallStreamView.renderView.isHidden = sender.isSelected
            mainStreamView.renderView.isHidden = false
        } else {
            mainStreamView.renderView.isHidden = sender.isSelected
            smallStreamView.renderView.isHidden = false
        }
    }
    
    @IBAction func screenShareAction(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            startScreenCapture()
            isScreenSharing = true
            shareStatusLabel.isHidden = false
        } else {
            stopScreenCapture()
            isScreenSharing = false
            shareStatusLabel.isHidden = true
        }
        
        let broadcastPickerView = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: 44, height: 44))
        broadcastPickerView.preferredExtension = screenShareExtensionIdentifier
        for subView in broadcastPickerView.subviews {
            if let subView = subView as? UIButton {
                subView.sendActions(for: .allEvents)
                break
            }
        }
    }
}

extension LiveViewController: ZegoEventHandler {
    
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        print("onRoomStateUpdate: \(state.rawValue), errorCode: \(errorCode), roomID: \(roomID)")
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        print("onPublisherStateUpdate: \(state.rawValue), errorCode: \(errorCode), streamID: \(streamID)")
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        for stream in streamList {
            let streamID = stream.streamID
            let isScreenShare = streamID.hasSuffix("_screen_share")
            if updateType == .add {
                if isScreenShare {
                    currentScreenShareStreamID = streamID
                    startPlayingMainStream(streamID, view: mainStreamView.renderView)
                    startPlayingScreenShareStream(currentMainStreamID, view: smallStreamView.renderView)
                    smallStreamView.isHidden = false
                    isScreenSharing = true
                } else {
                    currentMainStreamID = streamID
                    startPlayingMainStream(streamID, view: mainStreamView.renderView)
                }
            } else {
                if isScreenShare {
                    smallStreamView.isHidden = true
                    startPlayingMainStream(currentMainStreamID, view: mainStreamView.renderView)
                    stopPlayingStream(streamID)
                    isScreenSharing = false
                } else {
                    smallStreamView.isHidden = true
                    stopPlayingStream(currentMainStreamID)
                    stopPlayingStream(currentScreenShareStreamID)
                }
            }
        }
    }
        
    func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        for stream in streamList {
            let dict = stream.extraInfo.toDict
            if let isCameraEnabled = dict?["isCameraEnabled"] as? Bool {
                if isScreenSharing {
                    smallStreamView.renderView.isHidden = !isCameraEnabled
                    mainStreamView.renderView.isHidden = false
                } else {
                    mainStreamView.renderView.isHidden = !isCameraEnabled
                    smallStreamView.renderView.isHidden = false
                }
            }
        }
    }
}
