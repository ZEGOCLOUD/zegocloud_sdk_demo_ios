//
//  ViewController.swift
//

import UIKit
import ZegoExpressEngine
import Toast

// Get your AppID and AppSign from ZEGOCLOUD Console
// [My Projects -> AppID] : https://console.zegocloud.com/project
let appID : UInt32 =
let appSign: String = 

class ViewController: UIViewController {
    
    // The video stream for the local user is displayed here
    var localView: UIView!
    // The video stream for the remote user is displayed here
    var remoteView: UIView!
    // Click to join or leave a call
    var callButton: UIButton!
    
    var localUserID = "user_" + String(Int.random(in: 1...100))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createEngine()
        initViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destroyEngine()
    }
        
    private func createEngine() {
        let profile = ZegoEngineProfile()
        
        // Get your AppID and AppSign from ZEGOCLOUD Console
        //[My Projects -> AppID] : https://console.zegocloud.com/project
        profile.appID = appID
        profile.appSign = appSign
        // Use the default scenario.
        profile.scenario = .default
        // Create a ZegoExpressEngine instance and set eventHandler to [self].
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
    }

    private func destroyEngine() {
        ZegoExpressEngine.destroy(nil)
    }
    
    private func initViews() {
        // Initializes the remote video view. This view displays video when a remote host joins the channel.
        remoteView = UIView()
        remoteView.frame = self.view.frame
        self.view.addSubview(remoteView)
        
        // Initializes the local video window. This view displays video when the local user is a host.
        localView = UIView()
        localView.frame = CGRect(x: 200, y: 80, width: 135, height: 240)
        self.view.addSubview(localView)
        
        //  Button to join or leave a channel
        callButton = UIButton(type: .system)
        callButton.frame = CGRect(x: (self.view.frame.width - 80) / 2.0, y: self.view.frame.height - 150, width: 80, height: 80)
        callButton.setBackgroundImage(UIImage(named: "call_icon"), for: .normal)
        callButton.setBackgroundImage(UIImage(named: "call_hand_up_icon"), for: .selected)

        callButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(callButton)
    }
    
    private func startPreview() {
        // Set up a view for the local video preview
        let canvas = ZegoCanvas(view: self.localView)
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
        let canvas = ZegoCanvas(view: self.remoteView)
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
    }

    private func stopPlayStream(streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
        

    private func loginRoom() {
        // The value of `userID` is generated locally and must be globally unique.
        let user = ZegoUser(userID: localUserID)
        // The value of `roomID` is generated locally and must be globally unique.
        // Users must log in to the same room to call each other.
        let roomID = "room_1"
        let roomConfig = ZegoRoomConfig()
        // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
        roomConfig.isUserStatusNotify = true
        // log in to a room
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: roomConfig) { errorCode, extendedData in
            if errorCode == 0 {
                // Login room successful
                self.startPreview()
                self.startPublish()
            } else {
                // Login room failed
            }
        }
    }

    private func logoutRoom() {
        ZegoExpressEngine.shared().logoutRoom()
    }


    @objc func buttonAction(sender: UIButton!) {
        sender.isSelected = !sender.isSelected;
        if sender.isSelected {
            loginRoom()
        } else {
            logoutRoom()
        }
    }
}

extension ViewController : ZegoEventHandler {
    
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

