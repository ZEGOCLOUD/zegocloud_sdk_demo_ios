//
//  LiveAudioRoomViewController.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2023/5/5.
//

import UIKit
import ZegoExpressEngine
import ZIM
import Toast

class LiveAudioRoomViewController: UIViewController {
    
    var mySelfRole: UserRole = .audience
    var liveID: String = ""
    var userCount = 1;
    
    var isLockSeat: Bool = false {
        didSet {
            if mySelfRole == .host {
                bottomSeatButton.setTitle(isLockSeat ? "UnLock":"LockSeat", for: .normal)
            }
        }
    }
    var isMicOn: Bool = false {
        didSet {
            micButton.setImage(UIImage(named: isMicOn ? "bottom_mic_on" : "bottom_mic_off"), for: .normal)
        }
    }
    
    
    var seatCollectionView: UIView?
    var seatViewList: [ZegoSeatView] = []
    
    var alterView: UIAlertController?
    var requestMemberVC: ApplyCoHostListViewController?
    let audioRoomManager = ZegoLiveAudioRoomManager.shared
    var currentRequestID: String?
    
    @IBOutlet weak var roomNameLabel: UILabel! {
        didSet {
            roomNameLabel.text = "Live audio room"
        }
    }
    @IBOutlet weak var roomIDLabel: UILabel! {
        didSet {
            roomIDLabel.text = "ID:\(liveID)"
        }
    }
    
    
    @IBOutlet weak var micButton: UIButton! {
        didSet {
            micButton.isHidden = mySelfRole == .audience
        }
    }
    
    @IBOutlet weak var memberButton: UIButton! {
        didSet {
            if mySelfRole == .host {
                memberButton.isHidden = false
            } else {
                memberButton.isHidden = true
            }
        }
    }
    @IBOutlet weak var bottomSeatButton: UIButton! {
        didSet {
            bottomSeatButton.layer.borderColor = UIColor.darkGray.cgColor
            bottomSeatButton.layer.borderWidth = 1
            bottomSeatButton.layer.cornerRadius = 4
            bottomSeatButton.layer.masksToBounds = true
            if mySelfRole == .host {
                bottomSeatButton.isHidden = false
                bottomSeatButton.setTitle(isLockSeat ? "UnLock":"LockSeat", for: .normal)
            } else if mySelfRole == .coHost {
                bottomSeatButton.isHidden = false
                bottomSeatButton.setTitle("LeaveSeat", for: .normal)
            } else {
                bottomSeatButton.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var applyBecomeSpeakerButton: UIButton! {
        didSet {
            applyBecomeSpeakerButton.isHidden = mySelfRole != .audience
            applyBecomeSpeakerButton.layer.borderColor = UIColor.darkGray.cgColor
            applyBecomeSpeakerButton.layer.borderWidth = 1
            applyBecomeSpeakerButton.layer.cornerRadius = 4
            applyBecomeSpeakerButton.layer.masksToBounds = true
        }
    }
    
    var isApply: Bool = false {
        didSet {
            if isApply {
                applyBecomeSpeakerButton.setTitle("Cancel Apply", for: .normal)
            } else {
                applyBecomeSpeakerButton.setTitle("ApplyBecomeSpeaker", for: .normal)
            }
        }
    }
    
    
    func updateRole(_ role: UserRole) {
        mySelfRole = role
        if mySelfRole == .host {
            micButton.isHidden = false
            bottomSeatButton.isHidden = false
            bottomSeatButton.setTitle(isLockSeat ? "UnLock":"LockSeat", for: .normal)
            applyBecomeSpeakerButton.isHidden = true
        } else if mySelfRole == .coHost {
            micButton.isHidden = false
            bottomSeatButton.isHidden = false
            bottomSeatButton.setTitle("LeaveSeat", for: .normal)
            applyBecomeSpeakerButton.isHidden = true
        } else {
            ZegoSDKManager.shared.expressService.stopPublishingStream()
            micButton.isHidden = true
            bottomSeatButton.isHidden = true
            applyBecomeSpeakerButton.isHidden = false
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoLiveAudioRoomManager.shared.delegate = self
        ZegoLiveAudioRoomManager.shared.addSeatServiceEventHandler(self)
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        ZegoLiveAudioRoomManager.shared.initWithConfig(ZegoLiveAudioRoomLayoutConfig())
        ZegoSDKManager.shared.expressService.turnCameraOn(false);
        setupUI()
        
        ZegoSDKManager.shared.loginRoom(liveID, scenario: .highQualityChatroom) { code, message in
            if code == 0 {
                ZegoSDKManager.shared.expressService.startSoundLevelMonitor()
                self.joinRoomAfterUpdateRoomInfo()
            }
        }
    }
    
    @IBAction func memberButtonClick(_ sender: Any) {
        if mySelfRole != .host { return }
        let applyVC: ApplyCoHostListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ApplyCoHostListViewController") as! ApplyCoHostListViewController
        self.present(applyVC, animated: true)
    }
    
    
    
    
    func setupUI() {
        seatCollectionView = UIView()
        self.view.addSubview(seatCollectionView!)
        let seatViewW: CGFloat = 60
        let seatViewH: CGFloat = 80
        var index = 0
        var seatCollectionViewW = 0;
        var seatCollectionViewH = 0;
        for seat in ZegoLiveAudioRoomManager.shared.seatList {
            let seatView = ZegoSeatView(frame: CGRect(x: seatViewW * CGFloat(seat.rowIndex) + (10.0 * CGFloat(seat.rowIndex)), y: seatViewH * CGFloat(seat.columnIndex) + CGFloat((10 * seat.columnIndex)), width: seatViewW, height: seatViewH))
            seatView.roomSeat = seat
            seatView.delegate = self
            seatCollectionView?.addSubview(seatView)
            index = index + 1
            if index == ZegoLiveAudioRoomManager.shared.seatList.count {
                seatCollectionViewH = (seat.columnIndex + 1) * Int(seatViewH) + (seat.columnIndex * 10)
                seatCollectionViewW = (seat.rowIndex + 1) * Int(seatViewW) + (seat.rowIndex * 10)
            }
            seatViewList.append(seatView)
        }
        seatCollectionView?.frame = CGRect(x: (Int(self.view.frame.size.width) - seatCollectionViewW) / 2, y: 200, width: seatCollectionViewW, height: seatCollectionViewH)
        
    }
    
    
    @IBAction func micButtonClick(_ sender: Any) {
        isMicOn = !isMicOn
        ZegoSDKManager.shared.expressService.turnMicrophoneOn(isMicOn)
    }
    
    @IBAction func bottomSeatClick(_ sender: Any) {
        if mySelfRole == .host {
            ZegoLiveAudioRoomManager.shared.lockSeat(!ZegoLiveAudioRoomManager.shared.isSeatLocked())
        } else if mySelfRole == .coHost {
            for seat in ZegoLiveAudioRoomManager.shared.seatList {
                if seat.currentUser?.id == ZegoSDKManager.shared.currentUser?.id {
                    ZegoLiveAudioRoomManager.shared.leaveSeat(seatIndex: seat.seatIndex) { roomID, errorKeys, errorInfo in
                        if errorInfo.code == .success && !errorKeys.contains("\(seat.seatIndex)") {
                            self.updateRole(.audience)
                            self.updateSeatView()
                        }
                    }
                    break
                }
            }
        }
    }
    
    @IBAction func applyBecomeSpeaker(_ sender: Any) {
        if !isApply {
            if let host = audioRoomManager.getHostUser() {
                let commandDict: [String: AnyObject] = ["room_request_type": RoomRequestType.applyCoHost.rawValue as AnyObject]
                ZegoSDKManager.shared.zimService.sendRoomRequest(host.id, extendedData: commandDict.jsonString) { code, message, messageID in
                    if code == 0 {
                        self.currentRequestID = ZegoSDKManager.shared.zimService.roomRequestDict[messageID ?? ""]?.requestID
                        self.view.makeToast("send apply sucess~", duration: 1.0, position: .center)
                    }
                }
            }
        } else {
            if let _ = audioRoomManager.getHostUser() {
                guard let currentRequestID = currentRequestID else { return }
                ZegoSDKManager.shared.zimService.cancelRoomRequest(currentRequestID, extendedData: nil) { code, message, requestID in
                    if code != 0 {
                        self.view.makeToast("cancel apply fail", duration: 1.0, position: .center)
                    }
                }
            }
        }
        isApply = !isApply
    }
    
    
    @IBAction func leaveRoom(_ sender: Any) {
        let leaveRoomAlterView: UIAlertController = UIAlertController(title: "Leave the room", message: "Are you sure to leave the room?", preferredStyle: .alert)
        let sureButton: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action in
            ZegoLiveAudioRoomManager.shared.leaveRoom()
            self.dismiss(animated: true)
        }
        let cancelButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        leaveRoomAlterView.addAction(sureButton)
        leaveRoomAlterView.addAction(cancelButton)
        self.present(leaveRoomAlterView, animated: true)
    }
    
    
    
    func joinRoomAfterUpdateRoomInfo() {
        if mySelfRole == .host {
            ZegoLiveAudioRoomManager.shared.setSelfHost()
            //take seat
            ZegoLiveAudioRoomManager.shared.takeSeat(seatIndex: 0) { roomID, errorKeys, errorInfo in
                if errorInfo.code == .success && !errorKeys.contains(ZegoSDKManager.shared.currentUser?.id ?? "") {
                    self.openMicAndStartPublishStream()
                    ZegoLiveAudioRoomManager.shared.hostSeatIndex = 0
                    self.updateSeatView()
                }
            }
        }
    }
    
    func updateSeatView() {
        for seatView in seatViewList {
            for seat in ZegoLiveAudioRoomManager.shared.seatList {
                seatView.isLock = isLockSeat
                if seatView.roomSeat?.seatIndex == seat.seatIndex {
                    seatView.roomSeat = seat
                }
            }
        }
    }
    
    func openMicAndStartPublishStream() {
        isMicOn = true
        ZegoSDKManager.shared.expressService.turnMicrophoneOn(isMicOn)
        if mySelfRole == .host {
            ZegoSDKManager.shared.expressService.startPublishingStream(audioRoomManager.getHostMainStreamID())
        } else {
            ZegoSDKManager.shared.expressService.startPublishingStream(audioRoomManager.getCoHostMainStreamID())
        }
    }
    
    deinit {
        audioRoomManager.unInit()
    }

}

extension LiveAudioRoomViewController: ExpressServiceDelegate {
    
    func onMicrophoneOpen(_ userID: String, isMicOpen: Bool) {
        if userID == ZegoSDKManager.shared.currentUser?.id {
            isMicOn = isMicOpen
        }
    }
}

extension LiveAudioRoomViewController: ZegoSeatViewDelegate {
    func onSeatViewDidClick(_ roomSeat: ZegoLiveAudioRoomSeat) {
        if mySelfRole == .audience {
            if roomSeat.currentUser == nil {
                if !isLockSeat && roomSeat.seatIndex != ZegoLiveAudioRoomManager.shared.hostSeatIndex {
                    takeSeat(roomSeat.seatIndex)
                }
            }
        } else if mySelfRole == .host {
            if roomSeat.currentUser?.id != nil && roomSeat.currentUser?.id != ZegoSDKManager.shared.currentUser?.id {
                showRemoveOrMuteUserAlter(roomSeat: roomSeat)
            }
        } else {
            if isLockSeat || roomSeat.currentUser?.id == ZegoSDKManager.shared.currentUser?.id || (roomSeat.seatIndex == ZegoLiveAudioRoomManager.shared.hostSeatIndex && mySelfRole != .host) || mySelfRole == .host { return }
            var localUserSeat: ZegoLiveAudioRoomSeat?
            for seat in ZegoLiveAudioRoomManager.shared.seatList {
                if seat.currentUser?.id == ZegoSDKManager.shared.currentUser?.id {
                    localUserSeat = seat
                    break
                }
            }
            if let localUserSeat = localUserSeat {
                ZegoLiveAudioRoomManager.shared.switchSeat(fromSeatIndex: localUserSeat.seatIndex, toSeatIndex: roomSeat.seatIndex) { roomID, errorInfo in
                    if errorInfo.code == .success {
                        if self.mySelfRole == .host {
                            ZegoLiveAudioRoomManager.shared.hostSeatIndex = roomSeat.seatIndex
                        }
                        self.updateSeatView()
                    }
                }
            }
        }
    }
    
    func showRemoveOrMuteUserAlter(roomSeat: ZegoLiveAudioRoomSeat) {
        let alterView: UIAlertController = UIAlertController(title: "Remove or Mute the speaker", message: "", preferredStyle: .actionSheet)
        let removeAction: UIAlertAction = UIAlertAction(title: "remove the speaker", style: .default) { action in
            self.audioRoomManager.emptySeat(seatIndex: roomSeat.seatIndex) { roomID, errorKeys, error in
                if !errorKeys.contains("\(roomSeat.seatIndex)") {
                    self.view.makeToast("remove speaker success", duration: 1.0, position: .center)
                } else {
                    self.view.makeToast("remove speaker fail", duration: 1.0, position: .center)
                }
            }
        }
        let targetUser: ZegoSDKUser? = ZegoSDKManager.shared.getUser(roomSeat.currentUser?.id ?? "")
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: .cancel)
        alterView.addAction(removeAction)
        if let targetUser = targetUser {
            let muteAction: UIAlertAction = UIAlertAction(title: targetUser.isMicrophoneOpen ? "mute the speaker" : "unMute the speaker", style: .default) { action in
                guard let userID = roomSeat.currentUser?.id else { return }
                self.audioRoomManager.muteSpeaker(userID, isMute: targetUser.isMicrophoneOpen ? true : false) { code, message in
                    if code == 0 {
                        self.view.makeToast("controls success", duration: 1.0, position: .center)
                    } else {
                        self.view.makeToast("controls fail", duration: 1.0, position: .center)
                    }
                }
            }
            alterView.addAction(muteAction)
        }
        let kickOutAction: UIAlertAction = UIAlertAction(title: "kick out the speaker", style: .default) { action in
            self.audioRoomManager.kickOutRoom(targetUser?.id ?? "") { code, message in
                if code == 0 {
                    self.view.makeToast("kick out speaker success", duration: 1.0, position: .center)
                } else {
                    self.view.makeToast("kick out speaker fail:\(code)", duration: 1.0, position: .center)
                }
            }
        }
        alterView.addAction(kickOutAction)
        alterView.addAction(cancelAction)
        self.present(alterView, animated: true)
    }
    
    func takeSeat(_ seatIndex: Int) {
        ZegoLiveAudioRoomManager.shared.takeSeat(seatIndex: seatIndex) { roomID, errorKeys, errorInfo in
            if errorInfo.code == .success && !errorKeys.contains(ZegoSDKManager.shared.currentUser?.id ?? "") {
                self.updateRole(.coHost)
                self.openMicAndStartPublishStream()
                self.updateSeatView()
            }
        }
    }
}

extension LiveAudioRoomViewController: RoomSeatServiceDelegate {
    
    func onSeatChanged(_ seatList: [ZegoLiveAudioRoomSeat]) {
        updateSeatView()
        var isFindMyself = false
        for roomSeat in audioRoomManager.seatList {
            if roomSeat.currentUser?.id == ZegoSDKManager.shared.currentUser?.id {
                isFindMyself = true
                break
            }
        }
        if !isFindMyself {
            updateRole(.audience)
        }
    }
}

extension LiveAudioRoomViewController: ZegoLiveAudioRoomManagerDelegate {
    
    func onHostChanged(_ user: ZegoSDKUser) {
        updateSeatView()
    }
    
    func onSeatLockChanged(_ lock: Bool) {
        isLockSeat = lock
        updateSeatView()
    }
    
    func onQueryUserInfoSucess() {
        updateSeatView()
    }
    
    func onReceiveMuteUserSpeaker(_ userID: String, isMute: Bool) {
        if userID == ZegoSDKManager.shared.currentUser?.id {
            if isMute {
                self.view.makeToast("You've been mute speaker by the host", duration: 1.0, position: .center)
            } else {
                self.view.makeToast("Your microphone is turned on by the host", duration: 1.0, position: .center)
            }
            if mySelfRole == .coHost {
                ZegoSDKManager.shared.expressService.turnMicrophoneOn(!isMute)
            }
        }
    }
    
    func onReceiveKickOutRoom() {
        ZegoLiveAudioRoomManager.shared.leaveRoom()
        self.dismiss(animated: true)
        self.view.makeToast("You've been kick out of the room by the host", duration: 1.0, position: .center)
    }

}

extension LiveAudioRoomViewController: ZIMServiceDelegate {
    
    func onInComingRoomRequestReceived(requestID: String, extendedData: String) {
        self.view.makeToast("receive become speaker apply", duration: 1.0, position: .center)
    }
    
    func onOutgoingRoomRequestAccepted(requestID: String, extendedData: String) {
        isApply = false
        for seat in ZegoLiveAudioRoomManager.shared.seatList {
            if seat.currentUser == nil {
                self.takeSeat(seat.seatIndex)
                break
            }
        }
    }
    
    func onOutgoingRoomRequestRejected(requestID: String, extendedData: String) {
        isApply = false
        self.view.makeToast("apply is reject", duration: 1.0, position: .center)
    }
}
