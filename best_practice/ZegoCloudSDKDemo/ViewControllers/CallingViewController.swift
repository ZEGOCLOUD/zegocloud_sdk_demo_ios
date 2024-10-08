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
    
    lazy var addUserButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.setTitle("+", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        button.addTarget(self, action: #selector(addMemberClick), for: .touchUpInside)
        return button
    }()
    
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
        setupNavBar()
        ZegoCallManager.shared.addCallEventHandler(self)
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        setDeviceStatus()
        setUpBottomBar()
        
        if let currentCallData = ZegoCallManager.shared.currentCallData,
           let roomID = currentCallData.callID
        {
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
    
    func setupNavBar() {
        self.navigationItem.title =  "Call Page"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addUserButton)
    }
    
    func setupCallSubView() {
        guard let callUserList = ZegoCallManager.shared.currentCallData?.callUserList,
              let _ = ZegoSDKManager.shared.expressService.currentRoomID
        else { return }
        var enableShowUsers: [CallUserInfo] = []
        for user in callUserList {
            if user.isWaiting || user.hasAccepted {
                enableShowUsers.append(user)
            }
        }
        let seatUserList = seatingArrangement(enableShowUsers)
        if seatUserList.count > 2 {
            if let callDisplayVC = callDisplayVC,
               callDisplayVC is GroupCallViewController
            {
                (callDisplayVC as! GroupCallViewController).updateCallUserList(seatUserList)
            } else {
                callSubviewContainer.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                let viewController: GroupCallViewController = GroupCallViewController(nibName: "GroupCallViewController", bundle: nil)
                viewController.callUserList = seatUserList
                callDisplayVC = viewController
            }
        } else {
            if let callDisplayVC = callDisplayVC,
               callDisplayVC is OneOnOneCallViewController
            {
                (callDisplayVC as! OneOnOneCallViewController).callUserList = seatUserList
            } else {
                callSubviewContainer.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                let viewController: OneOnOneCallViewController = OneOnOneCallViewController(nibName: "OneOnOneCallViewController", bundle: nil)
                viewController.callUserList = seatUserList
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
    
    func seatingArrangement(_ enableShowUserList: [CallUserInfo]) -> [CallUserInfo] {
        var userList: [CallUserInfo] = []
        var waitingUser: [CallUserInfo] = []
        var localUserInfo: CallUserInfo?
        for callUserInfo in enableShowUserList {
            if callUserInfo.userID == ZegoSDKManager.shared.currentUser?.id {
                localUserInfo = callUserInfo
            } else {
                if callUserInfo.isWaiting {
                    waitingUser.append(callUserInfo)
                }
                if callUserInfo.hasAccepted {
                    userList.append(callUserInfo)
                }
            }
        }
        if let localUserInfo = localUserInfo {
            userList.insert(localUserInfo, at: 0)
        }
        userList.append(contentsOf: waitingUser)
        return userList
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
            ZegoCallManager.shared.quitCall(ZegoCallManager.shared.currentCallData?.callID ?? "", callback: nil)
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
    
    @objc func addMemberClick(_ sender: Any) {
        let addAlterView: UIAlertController = UIAlertController(title: "add member", message: nil, preferredStyle: .alert)
        addAlterView.addTextField { textField in
            textField.placeholder = "userID"
        }
        
        let sureAction: UIAlertAction = UIAlertAction(title: "sure", style: .default) { action in
            var addMemberList: [String] = []
            if let textField = addAlterView.textFields?[0] {
                if let userID = textField.text,
                   !userID.isEmpty
                {
                    addMemberList.append(userID)
                }
            }
            ZegoCallManager.shared.inviteUserToJoinCall(addMemberList, callback: nil)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel ", style: .cancel) { action in
            
        }
        addAlterView.addAction(sureAction)
        addAlterView.addAction(cancelAction)
        self.present(addAlterView, animated: true)
    }

}

extension CallingViewController: ZIMServiceDelegate, ZegoCallManagerDelegate {
    
    func onOutgoingCallInvitationTimeout(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onCallUserUpdate(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onOutgoingCallInvitationAccepted(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onCallUserQuit(userID: String, extendedData: String) {
        setupCallSubView()
    }
    
    func onCallEnd() {
        ZegoCallAudioPlayerTool.stopPlay()
        self.dismiss(animated: true)
    }
    
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
