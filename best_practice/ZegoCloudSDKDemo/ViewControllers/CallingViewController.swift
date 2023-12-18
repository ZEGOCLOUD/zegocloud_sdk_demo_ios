//
//  CallingViewController.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZegoExpressEngine
import ZIM

enum CallButtonType: Int {
    case hangUpButton
    case toggleCameraButton
    case toggleMicrophoneButton
    case switchCameraButton
    case swtichAudioOutputButton
}

class CallingViewController: UIViewController {
    
    
    @IBOutlet weak var callSubviewContainer: UIView!
    @IBOutlet weak var bottomBar: UIView! {
        didSet {
            bottomBar.backgroundColor = .init(hex: "#333437", alpha: 0.9)
        }
    }
    var localUser: ZegoSDKUser? {
        get {
            return ZegoSDKManager.shared.currentUser
        }
    }
    var buttonList: [CallButtonType] {
        get {
            if type == .voice {
                return [.toggleMicrophoneButton, .hangUpButton, .swtichAudioOutputButton]
            } else {
                return [.toggleMicrophoneButton, .toggleCameraButton,.hangUpButton, .swtichAudioOutputButton, .switchCameraButton]
            }
        }
    }
    var type: CallType {
        get {
            return ZegoCallManager.shared.currentCallData?.type ?? .voice
        }
    }
    
    private var margin: CGFloat {
        get {
            if type == .voice {
                return 55.5
            } else {
                return 21.5
            }
        }
    }
    
    private var itemSpace: CGFloat {
        get {
            if type == .voice {
                return (ScreenWidth - 111 - 180) / 2
            } else {
                return (ScreenWidth - 43 - 300) / 4
            }
         }
    }
    
    let itemSize: CGSize = CGSize.init(width: 60, height: 60)
    
    var isFrontFacingCamera: Bool = true
    
    var callDisplayVC: UIViewController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoCallManager.shared.addCallEventHandler(self)
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        setDeviceStatus()
        setUpBottomBar()
        
        if let roomID = ZegoCallManager.shared.currentCallData?.callID {
            ZegoSDKManager.shared.loginRoom(roomID, scenario: (type == .voice) ? .standardVoiceCall : .standardVideoCall) { code, message in
                if code == 0 {
                    ZegoSDKManager.shared.expressService.startPublishingStream(ZegoCallManager.shared.getMainStreamID())
                    self.setupCallSubView()
                } else {
                    self.view.makeToast("login room fail:\(code)", duration: 2.0, position: .center)
                }
            }
        }
    }
    
    func setupCallSubView() {
        guard let callUserList = ZegoCallManager.shared.currentCallData?.callUserList else { return }
        var enableShowUsers: [CallUserInfo] = []
        for user in callUserList {
            if user.isWaiting || user.hasAccepted {
                enableShowUsers.append(user)
            }
        }
        if enableShowUsers.count > 2 {
            if let callDisplayVC = callDisplayVC,
               callDisplayVC is GroupCallViewController
            {
                (callDisplayVC as! GroupCallViewController).callUserList = enableShowUsers
            } else {
                callSubviewContainer.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                let viewController: GroupCallViewController = GroupCallViewController(nibName: "GroupCallViewController", bundle: nil)
                viewController.callUserList = enableShowUsers
                callDisplayVC = viewController
            }
        } else {
            if let callDisplayVC = callDisplayVC,
               callDisplayVC is OneOnOneCallViewController
            {
                (callDisplayVC as! OneOnOneCallViewController).callUserList = enableShowUsers
            } else {
                callSubviewContainer.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                let viewController: OneOnOneCallViewController = OneOnOneCallViewController(nibName: "OneOnOneCallViewController", bundle: nil)
                viewController.callUserList = enableShowUsers
                callDisplayVC = viewController
            }
        }
        addChild(callDisplayVC)
        callSubviewContainer.addSubview(callDisplayVC.view)
        callDisplayVC.didMove(toParent: self)
        callDisplayVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            callDisplayVC.view.topAnchor.constraint(equalTo: callSubviewContainer.topAnchor),
            callDisplayVC.view.bottomAnchor.constraint(equalTo: callSubviewContainer.bottomAnchor),
            callDisplayVC.view.leadingAnchor.constraint(equalTo: callSubviewContainer.leadingAnchor),
            callDisplayVC.view.trailingAnchor.constraint(equalTo: callSubviewContainer.trailingAnchor)
        ])
    }
    
    func setDeviceStatus() {
        ZegoSDKManager.shared.expressService.turnMicrophoneOn(true)
        if type == .video {
            ZegoSDKManager.shared.expressService.turnCameraOn(true)
        } else {
            ZegoSDKManager.shared.expressService.turnCameraOn(false)
        }
        ZegoSDKManager.shared.expressService.setAudioRouteToSpeaker(defaultToSpeaker: true)
        ZegoSDKManager.shared.expressService.useFrontCamera(isFrontFacingCamera)
    }
    
    func setUpBottomBar() {
        var index = 0
        var lastView: UIView?
        for type in buttonList {
            let button: UIButton = UIButton(type: .custom)
            button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
            if index == 0 {
                button.frame = CGRect.init(x: self.margin, y: (70 - itemSize.height) * 0.5, width: itemSize.width, height: itemSize.width)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect.init(x: lastView.frame.maxX + itemSpace, y: lastView.frame.minY, width: itemSize.width, height: itemSize.height)
                }
            }
            lastView = button
            index = index + 1
            switch type {
            case .hangUpButton:
                button.tag = 100
                button.setImage(UIImage(named: "call_hand_up_icon"), for: .normal)
            case .toggleCameraButton:
                button.tag = 101
                button.setImage(UIImage(named: "icon_camera_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_camera_off"), for: .selected)
            case .toggleMicrophoneButton:
                button.tag = 102
                button.setImage(UIImage(named: "icon_mic_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_mic_off"), for: .selected)
            case .switchCameraButton:
                button.tag = 103
                button.setImage(UIImage(named: "icon_camera_overturn"), for: .normal)
            case .swtichAudioOutputButton:
                button.tag = 104
                button.setImage(UIImage(named: "icon_speaker_normal"), for: .normal)
                button.setImage(UIImage(named: "icon_speaker_off"), for: .selected)
            }
            bottomBar.addSubview(button)
        }
    }
    
    @objc func buttonClick(_ sender: UIButton) {
        switch sender.tag {
        case 100:
//            ZegoCallManager.shared.clearCallData()
            ZegoCallManager.shared.quitCall(ZegoCallManager.shared.currentCallData?.callID ?? "", callback: nil)
            ZegoCallManager.shared.leaveRoom()
            self.dismiss(animated: true)
        case 101:
            sender.isSelected = !sender.isSelected
            ZegoSDKManager.shared.expressService.turnCameraOn(!sender.isSelected)
        case 102:
            sender.isSelected = !sender.isSelected
            ZegoSDKManager.shared.expressService.turnMicrophoneOn(!sender.isSelected)
        case 103:
            isFrontFacingCamera = !isFrontFacingCamera
            ZegoSDKManager.shared.expressService.useFrontCamera(isFrontFacingCamera)
        case 104:
            sender.isSelected = !sender.isSelected
            ZegoSDKManager.shared.expressService.setAudioRouteToSpeaker(defaultToSpeaker: !sender.isSelected)
        default:
            break
        }
    }
    
    
    func showLocalPreview() {
        if type == .video {
           // ZegoSDKManager.shared.expressService.startPreview(smallVideoView)
        }
        ZegoSDKManager.shared.expressService.startPublishingStream(ZegoCallManager.shared.getMainStreamID())
    }

}

extension CallingViewController: ExpressServiceDelegate, ZIMServiceDelegate, ZegoCallManagerDelegate {
    
    func onCallUserJoin(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onCallUserQuit(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onCallEnd() {
        ZegoCallManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open && type == .video {
            self.view.makeToast("remote user camera close", duration: 2.0, position: .center)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open {
            self.view.makeToast("remote user microphone close", duration: 2.0, position: .center)
        }
    }
    
//    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
//        if updateType == .delete {
//            for user in userList {
//                if user.userID == remoteUser?.id {
//                    ZegoCallManager.shared.clearCallData()
//                    ZegoCallManager.shared.leaveRoom()
//                    self.dismiss(animated: true)
//                }
//            }
//        }
//    }
    
//    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
//        for stream in streamList {
//            if updateType == .add {
//                if type == .video {
//                    ZegoSDKManager.shared.expressService.startPlayingStream(largeVideoView, streamID: stream.streamID, viewMode: .aspectFill)
//                } else {
//                    ZegoSDKManager.shared.expressService.startPlayingStream(nil, streamID: stream.streamID)
//                }
//            } else {
//                ZegoSDKManager.shared.expressService.stopPlayingStream(stream.streamID)
//            }
//        }
//    }
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        if state == .disconnected {
            self.view.makeToast("zim disconnected", duration: 2.0, position: .center)
        } else if state == .connecting {
            self.view.makeToast("zim connecting", duration: 2.0, position: .center)
        } else if state == .reconnecting {
            self.view.makeToast("zim reconnecting", duration: 2.0, position: .center)
        }
    }
    
}
