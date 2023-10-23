//
//  ViewController.swift
//

import UIKit
import ZegoExpressEngine
import Toast

class LiveStreamingVC: UIViewController {

    // The video stream for the host user is displayed here
    var hostCameraView: UIView!
    // Click to join or leave a call
    var leaveRoomButton: UIButton!
    
    var roomID: String = ""
    var isHost: Bool = false
    
    var localUserID = ""


    init(roomID: String, localUserID: String, isHost: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.roomID = roomID
        self.localUserID = localUserID
        self.isHost = isHost
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        ZegoExpressEngine.shared().setEventHandler(self)
        loginRoom()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logoutRoom()
        ZegoExpressEngine.shared().setEventHandler(nil)
    }
        

    
    private func initViews() {
        // Initializes the remote video view. This view displays video when a remote host joins the channel.
        hostCameraView = UIView()
        hostCameraView.frame = self.view.frame
        self.view.addSubview(hostCameraView)

        
        //  Button to join or leave a channel
        leaveRoomButton = UIButton(type: .system)
        leaveRoomButton.frame = CGRect(x: (self.view.frame.width - 80) / 2.0, y: self.view.frame.height - 150, width: 80, height: 40)
        leaveRoomButton.setTitle("leave room", for: .normal)
        leaveRoomButton.setTitleColor(UIColor.white, for: .normal)
        leaveRoomButton.backgroundColor = UIColor.lightGray

        leaveRoomButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(leaveRoomButton)
    }
    
    private func startPreview() {
        // Set up a view for the host's camera
        let canvas = ZegoCanvas(view: self.hostCameraView)
        ZegoExpressEngine.shared().startPreview(canvas)
    }

    private func stopPreview() {
        ZegoExpressEngine.shared().stopPreview()
    }
        
    private func startPublish() {
        // After calling the `loginRoom` method, call this method to publish streams.
        let streamID = "stream_" + localUserID
        ZegoExpressEngine.shared().startPublishingStream(streamID)
    }

    private func stopPublish() {
        ZegoExpressEngine.shared().stopPublishingStream()
    }
        
    private func startPlayStream(streamID: String) {
        // Start to play streams. Set the view for rendering the remote streams.
        let canvas = ZegoCanvas(view: self.hostCameraView)
        var config = ZegoPlayerConfig()
        config.resourceMode = .default
//        config.resourceMode = .onlyL3
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas, config:config)
    }

    private func stopPlayStream(streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
        

    private func loginRoom() {
        // The value of `userID` is generated locally and must be globally unique.
        let user = ZegoUser(userID: localUserID)
        // Users must log in to the same room to call each other.
        let roomConfig = ZegoRoomConfig()
        // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
        roomConfig.isUserStatusNotify = true
        // log in to a room
        ZegoExpressEngine.shared().loginRoom(self.roomID, user: user, config: roomConfig) { errorCode, extendedData in
            if errorCode == 0 {
                // Login room successful
                if self.isHost{
                    self.startPreview()
                    self.startPublish()
                }
            } else {
                // Login room failed
                self.view.makeToast("loginRoom faild \(errorCode)", duration: 2.0, position: .center)
            }
        }
    }

    private func logoutRoom() {
        ZegoExpressEngine.shared().logoutRoom()
    }


    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true)
    }
}

extension LiveStreamingVC : ZegoEventHandler {
    
    // Callback for updates on the status of the streams in the room.
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        // If users want to play the streams published by other users in the room, call the startPlayingStream method with the corresponding streamID obtained from the `streamList` parameter where ZegoUpdateType == ZegoUpdateTypeAdd.
        if updateType == .add {
            for stream in streamList {
                startPlayStream(streamID: stream.streamID)
            }
        } else {
            for stream in streamList {
                stopPlayStream(streamID: stream.streamID)
            }
        }
    }
    
    // Callback for updates on the current user's room connection status.
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        if errorCode != 0 {
            self.view.makeToast("onRoomStateUpdate: \(state.rawValue), errorCode: \(errorCode)")
        }
    }

    // Callback for updates on the status of other users in the room.
    // Users can only receive callbacks when the isUserStatusNotify property of ZegoRoomConfig is set to `true` when logging in to the room (loginRoom).
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
    }

}

