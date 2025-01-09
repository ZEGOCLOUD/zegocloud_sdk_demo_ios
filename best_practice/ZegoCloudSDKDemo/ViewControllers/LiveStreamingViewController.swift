//
//  LiveStreamingViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import UIKit
import ZegoExpressEngine
import ZIM
import Toast
import AVKit


@objc public protocol LiveStreamingCallVCDelegate: AnyObject {
    @objc optional func getCurrentPipRenderStreamID(streamsDicts:[String:String]) -> String?
}

class LiveStreamingViewController: UIViewController {
    
    
    @IBOutlet weak var mainVideoView: VideoView!
    @IBOutlet weak var pkBattleContainer: PKBattleViewContainer!
    
    
    @IBOutlet weak var preBackgroundView: UIView!
    @IBOutlet weak var startLiveButton: UIButton!
    
    @IBOutlet weak var liveContainerView: UIView!
    @IBOutlet weak var userNameConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var memberButton: UIButton! {
        didSet {
            memberButton.addSubview(redDot)
        }
    }
    @IBOutlet weak var flipButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var minimizationButton: UIButton!
    @IBOutlet weak var endCoHostButton: UIButton!
    @IBOutlet weak var coHostButton: UIButton!
    @IBOutlet weak var coHostWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var pkButton: PKButton! {
        didSet {
            pkButton.viewController = self
            pkButton.layer.masksToBounds = true
            pkButton.layer.cornerRadius = 6
        }
    }
    
    @IBOutlet weak var giftButton: UIButton! {
        didSet {
            giftButton.layer.masksToBounds = true
            giftButton.layer.cornerRadius = 6
        }
    }
    
    lazy var inviteUserPKButton: UIButton = {
        let button: UIButton = UIButton()
        button.backgroundColor = UIColor.purple
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("invite user", for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.isHidden = true
        button.addTarget(self, action: #selector(inviterUserPKClick), for: .touchUpInside)
        return button
    }()
    
    lazy var redDot: UIView = {
        let redDotView = UIView(frame: CGRect(x: 40, y: 25, width: 8, height: 8))
        redDotView.backgroundColor = UIColor.red
        redDotView.layer.masksToBounds = true
        redDotView.layer.cornerRadius = 4
        redDotView.isHidden = true
        return redDotView
    }()
    
    
    lazy var coHostVideoContainerView: CoHostContainerView = {
        let view = CoHostContainerView(frame: .zero)
        return view
    }()
    
    lazy var giftView: GiftView = {
        let giftView = GiftView(frame: view.bounds)
        return giftView
    }()
    
    var alterView: UIAlertController?
    var coHostRequestAlterView: UIAlertController?
    
    var coHostVideoViews: [CoHostViewModel] = []
    
    var isMySelfHost: Bool = false
    var liveID: String = ""
    var userCount = 1
    
    var currentRoomRequestID: String?
    let liveManager = ZegoLiveStreamingManager.shared
    public weak var delegate: LiveStreamingCallVCDelegate?
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        print("\(String(describing: type(of: self))) \(#function)")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ExpressService.shared.enableCustomVideoRender(enable: true)
        
        ZegoMinimizeManager.shared.delegate = self
        ZegoMinimizeManager.shared.setupPipControllerWithSourceView(sourceView: view, isOneOnOneVideo: true)

        ZegoSDKManager.shared.zimService.addEventHandler(self)
        liveManager.addPKDelegate(self)
        liveManager.eventDelegates.add(self)
        if isMySelfHost {
            liveManager.hostUser = ZegoSDKManager.shared.currentUser
        } else {
            if checkIsPictureInPictureSupported() == false {
                self.view.makeToast("pip capability not supported", position: .center)
            }
        }
        
        configUI()
    }
    
    func checkIsPictureInPictureSupported() -> Bool {
        var supportPip = false
        if #available(iOS 15.0, *) {
            supportPip = AVPictureInPictureController.isPictureInPictureSupported()
        }
        return supportPip
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        inviteUserPKButton.frame = CGRect(origin: CGPointMake(view.bounds.width - 135, view.bounds.height - 150), size: CGSize(width: 120, height: 30))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if checkIsPictureInPictureSupported() == false {
            self.minimizationButton.isHidden = true
            return
        }
        
        if liveManager.isAudience(userID: ZegoSDKManager.shared.currentUser?.id ?? "") {
            self.minimizationButton.isHidden = false
        } else {
            self.minimizationButton.isHidden = true
        }
        if UIApplication.shared.applicationState == .active {
            if self.minimizationButton.isHidden == false {
                ZegoMinimizeManager.shared.destroy()
                ZegoMinimizeManager.shared.delegate = self
                ZegoMinimizeManager.shared.setupPipControllerWithSourceView(sourceView: view, isOneOnOneVideo: true)
            } else {
                ZegoMinimizeManager.shared.destroy()
            }
        }
    }
    
    func updateCoHostContainerFrame() {
        coHostVideoContainerView.frame = CGRect(x: liveContainerView.bounds.width - 16 - 93, y: liveContainerView.bounds.size.height - 85 - getVideoContainerHeight(), width: 93, height: getVideoContainerHeight())
    }
    
    func getVideoContainerHeight() -> CGFloat {
        let count = coHostVideoViews.count > 3 ? 3 : coHostVideoViews.count
        if count == 0 {
            return 0
        } else {
            return CGFloat(124 * count + ((count - 1) * 5))
        }
    }
    
    func configUI() {
        view.backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
        liveContainerView.isHidden = isMySelfHost
        preBackgroundView.isHidden = !isMySelfHost
        giftButton.isHidden = isMySelfHost
        liveContainerView.addSubview(coHostVideoContainerView)
        ZegoSDKManager.shared.expressService.startSoundLevelMonitor()
        if isMySelfHost {
            ZegoSDKManager.shared.expressService.turnCameraOn(true)
            ZegoSDKManager.shared.expressService.turnMicrophoneOn(true)
            startPreviewIfHost()
            updateUserNameLabel(ZegoSDKManager.shared.expressService.currentUser?.name)
            self.view.addSubview(inviteUserPKButton)
        } else {
            userNameLabel.isHidden = true
            coHostButton.isHidden = false
            flipButton.isHidden = true
            micButton.isHidden = true
            cameraButton.isHidden = true
            
            ZegoSDKManager.shared.loginRoom(liveID, scenario: .broadcast) { [weak self] code, message in
                if code != 0 {
                    self?.view.makeToast(message, position: .center)
                }
            }
        }
    }
    
    func updateUserNameLabel(_ name: String?) {
        userNameLabel.isHidden = false
        userNameLabel.text = name
        userNameConstraint.constant = userNameLabel.intrinsicContentSize.width + 20
    }
    
    func startPreviewIfHost() {
        preBackgroundView.isHidden = !isMySelfHost
        if isMySelfHost {
            ZegoSDKManager.shared.expressService.startPreview(mainVideoView.renderView)
        }
    }
    
    // MARK: - Actions
    @IBAction func startLive(_ sender: UIButton) {
        // join room and publish
        ZegoSDKManager.shared.loginRoom(liveID, scenario: .broadcast) { [weak self] code, message in
            guard let self = self else { return }
            if code != 0 {
                self.view.makeToast(message, position: .center)
            } else {
                self.liveManager.addPKDelegate(self)
            }
            self.liveManager.hostUser = ZegoSDKManager.shared.currentUser
            ZegoSDKManager.shared.expressService.startPublishingStream(self.liveManager.getHostMainStreamID())
        }
        
        // modify UI
        preBackgroundView.isHidden = true
        liveContainerView.isHidden = false
        pkButton.isHidden = false
        liveManager.isLiveStart = true
        
        mainVideoView.update(ZegoSDKManager.shared.expressService.currentUser?.id, ZegoSDKManager.shared.expressService.currentUser?.name)
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        ExpressService.shared.enableCustomVideoRender(enable: false)
        dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        func leaveRoom() {
            liveManager.isLiveStart = false
            liveManager.leaveRoom()
            ExpressService.shared.enableCustomVideoRender(enable: false)
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
    
    @IBAction func switchCamera(_ sender: UIButton) {
        ZegoSDKManager.shared.expressService.useFrontCamera(!ZegoSDKManager.shared.expressService.isUsingFrontCamera)
    }
    
    @IBAction func endCoHostAction(_ sender: UIButton) {
        let localUserID = ZegoSDKManager.shared.expressService.currentUser!.id
        ZegoSDKManager.shared.expressService.stopPublishingStream()
        ZegoSDKManager.shared.expressService.stopPreview()
        coHostVideoViews = coHostVideoViews.filter({ $0.user?.id != localUserID })
        coHostVideoContainerView.coHostModels = coHostVideoViews
        updateCoHostContainerFrame()
        coHostButton.isHidden = liveManager.isPKStarted
        endCoHostButton.isHidden = true
        
        flipButton.isHidden = true
        micButton.isHidden = true
        cameraButton.isHidden = true
        flipButtonConstraint.constant = 16
    }
    
    @IBAction func micAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        ZegoSDKManager.shared.expressService.turnMicrophoneOn(!sender.isSelected)
    }
    
    @IBAction func cameraAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        ZegoSDKManager.shared.expressService.turnCameraOn(!sender.isSelected)
        
        if isMySelfHost {
            mainVideoView.enableCamera(!sender.isSelected)
        } else {
            let videoViews = coHostVideoViews.filter({ $0.user?.id ==  ZegoSDKManager.shared.expressService.currentUser?.id})
            videoViews.forEach({ $0.isCamerOn = !sender.isSelected})
            coHostVideoContainerView.cameraStateChange(ZegoSDKManager.shared.currentUser?.id ?? "", isOn: !sender.isSelected)
        }
    }
    
    
    @IBAction func coHostAction(_ sender: UIButton) {
        func clickButton() {
            sender.isSelected = !sender.isSelected
            coHostWidthConstraint.constant = sender.isSelected ? 210 : 165
        }
        clickButton()
        
        guard let receiverID = liveManager.hostUser?.id else {
            self.view.makeToast("Host is not in the room.", position: .center)
            clickButton()
            return
        }
        
        let requestType: RoomRequestType = sender.isSelected ? .applyCoHost : .cancelCoHostApply
        let commandDict: [String: AnyObject] = ["room_request_type": requestType.rawValue as AnyObject]
        if requestType == .applyCoHost {
            ZegoSDKManager.shared.zimService.sendRoomRequest(receiverID, extendedData: commandDict.jsonString) { [weak self] code, message, messageID in
                if code != 0 {
                    self?.view.makeToast("send custom signaling protocol Failed: \(code)", position: .center)
                    clickButton()
                } else {
                    self?.currentRoomRequestID = ZegoSDKManager.shared.zimService.roomRequestDict[messageID ?? ""]?.requestID;
                }
            }
        } else {
            guard let currentRoomRequestID = currentRoomRequestID else { return }
            ZegoSDKManager.shared.zimService.cancelRoomRequest(currentRoomRequestID, extendedData: nil) { code, message, requestID in
                if code != 0 {
                    self.view.makeToast("send custom signaling protocol Failed: \(code)", position: .center)
                    clickButton()
                }
            }
        }
    }
    
    //    @IBAction func muteAnotherAudioClick(_ sender: UIButton) {
    //        sender.isSelected = !sender.isSelected
    //        liveManager.mutePKUser(mute: sender.isSelected, callback: nil)
    //    }
    
    @IBAction func memberButtonClick(_ sender: Any) {
        if !isMySelfHost {
            return
        }
        let applyVC: ApplyCoHostListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ApplyCoHostListViewController") as! ApplyCoHostListViewController
        self.present(applyVC, animated: true)
    }
    
    @IBAction func sendGiftClick(_ sender: Any) {
        ZegoSDKManager.shared.zimService.sendRoomCommand(command: "gift") { code, message in
            if code == 0 {
                debugPrint("send gift sucess!")
                DispatchQueue.main.async {
                    self.giftView.show("vap.mp4", container: self.view)
                }
            } else {
                debugPrint("send gift fail! errorCode:\(code)")
            }
        }
    }
    
    @IBAction func onClickPip(_ sender: Any) {
    
        ZegoMinimizeManager.shared.pipView?.isEnablePreview = ZegoSDKManager.shared.currentUser?.streamID?.count ?? 0 > 0 ? true : false
        if #available(iOS 15.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                ZegoMinimizeManager.shared.isNarrow = true
                ZegoMinimizeManager.shared.callVC = self
                self.dismiss(animated: false)
            }
        }
        
    }
    
}
extension LiveStreamingViewController: ZegoMinimizeManagerDelegate {
    func getCurrentPipRenderStreamID(streamsDict: [String : String]) -> String? {
        return ""//self.delegate?.getCurrentPipRenderStreamID?(streamsDicts: streamsDict)
    }
    
    func willStopPictureInPicture() {
        if let callVC = ZegoMinimizeManager.shared.callVC,
           ZegoMinimizeManager.shared.isNarrow
        {
            ZegoMinimizeManager.shared.isNarrow = false
            currentViewController()?.present(callVC, animated: false)
            ZegoMinimizeManager.shared.callVC = nil
        }
    }
    
    func stopPipExitRoom() {
        closeButtonAction(UIButton(type: .custom))
    }
}


extension LiveStreamingViewController: ZegoLiveStreamingManagerDelegate {
    
    func onRoomCommandReceived(senderID: String, command: String) {
        if (senderID != ZegoSDKManager.shared.currentUser?.id) && command == "gift" {
            DispatchQueue.main.async {
                self.giftView.show("vap.mp4", container: self.view)
            }
        }
    }
    
    func onRoomStreamAdd(streamList: [ZegoStream]) {
        for stream in streamList {
            addCoHost(stream)
        }
    }
    
    func onRoomStreamDelete(streamList: [ZegoStream]) {
        for stream in streamList {
            removeCoHost(stream)
        }
    }
    
    func onRoomUserAdd(userList: [ZegoUser]) {
        userCount = userCount + userList.count;
        memberButton.setTitle("\(userCount)", for: .normal)
    }
    
    func onRoomUserDelete(userList: [ZegoUser]) {
        userList.forEach { user in
            if (user.userID == coHostRequestAlterView?.restorationIdentifier) {
                coHostRequestAlterView?.dismiss(animated: false);
            }
        }
        userCount = userCount - userList.count;
        memberButton.setTitle("\(userCount)", for: .normal)
    }
    
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        if liveManager.isHost(userID: userID) {
            mainVideoView.enableCamera(isCameraOpen)
        } else {
            let videoViews = coHostVideoViews.filter({ $0.user?.id == userID })
            videoViews.forEach({ $0.isCamerOn = isCameraOpen})
            coHostVideoContainerView.cameraStateChange(userID, isOn: isCameraOpen)
        }
    }
    
    func startPKUpdateUI() {
        mainVideoView.isHidden = true
        pkBattleContainer.isHidden = false
        coHostButton.isHidden = true
        coHostWidthConstraint.constant = 0
        inviteUserPKButton.isHidden = false
    }
    
    func endPKUpdateUI() {
        mainVideoView.isHidden = false
        pkBattleContainer.isHidden = true
        coHostButton.isHidden = isMySelfHost
        coHostWidthConstraint.constant = 165
        inviteUserPKButton.isHidden = true
    }
    
    func headName(_ userName: String) -> String {
        if userName.count > 0 {
            return String(userName[userName.startIndex])
        }
        return ""
    }
}

// MARK: - CoHost
extension LiveStreamingViewController {
    
    func showReaDot() {
        if isMySelfHost {
            redDot.isHidden = ZegoSDKManager.shared.zimService.roomRequestDict.count == 0
        } else {
            redDot.isHidden = true
        }
    }
    
    func onReceiveAcceptCoHostApply() {
        self.view.makeToast("onReceiveAcceptCoHostApply", position: .center)
        let streamID = liveManager.getCoHostMainStreamID()
        let userID = ZegoSDKManager.shared.expressService.currentUser?.id ?? ""
        let userName = ZegoSDKManager.shared.expressService.currentUser?.name ?? ""
        addCoHost(streamID, userID, userName, isMySelf: true)
        coHostButton.isHidden = true
        coHostButton.isSelected = !coHostButton.isSelected
        endCoHostButton.isHidden = false
        
        flipButton.isHidden = false
        micButton.isHidden = false
        cameraButton.isHidden = false
        flipButtonConstraint.constant = 116;
    }
    
    func onReceiveCancelCoHostApply(){
        coHostRequestAlterView?.dismiss(animated: true)
        self.view.makeToast("onReceiveCancelCoHostApply", position: .center)
    }
    
    func onReceiveRefuseCoHostApply(){
        self.view.makeToast("onReceiveRefuseCoHostApply", position: .center)
        coHostButton.isSelected = false
        coHostWidthConstraint.constant = coHostButton.isSelected ? 210 : 165
    }
    
    func addCoHost(_ stream: ZegoStream) {
        addCoHost(stream.streamID, stream.user.userID, stream.user.userName)
    }
    
    func addCoHost(_ streamID: String, _ userID: String, _ userName: String, isMySelf: Bool = false) {
        let isHost = streamID.hasSuffix("_host")
        if isHost {
            ZegoSDKManager.shared.expressService.startPlayingStream(mainVideoView.renderView, streamID: streamID)
            updateUserNameLabel(userName)
            mainVideoView.update(userID, userName)
        }
        // add cohost
        else {
            if isMySelf {
                ZegoSDKManager.shared.expressService.startPublishingStream(streamID)
            }
            let coHostViewModel: CoHostViewModel = CoHostViewModel()
            coHostViewModel.user = ZegoSDKUser(id: userID, name: userName)
            coHostViewModel.streamID = streamID
            coHostVideoViews.insert(coHostViewModel, at: 0)
            coHostVideoContainerView.coHostModels = coHostVideoViews
            updateCoHostContainerFrame()
        }
    }
    
    func removeCoHost(_ stream: ZegoStream) {
        ZegoSDKManager.shared.expressService.stopPlayingStream(stream.streamID)
        let isHost = stream.streamID.hasSuffix("_host")
        if isHost {
            
        } else {
            coHostVideoViews = coHostVideoViews.filter({ $0.user?.id != stream.user.userID })
            coHostVideoContainerView.coHostModels = coHostVideoViews
            updateCoHostContainerFrame()
        }
    }
    
    @objc func inviterUserPKClick() {
        let invitePKAlterView: UIAlertController = UIAlertController(title: "invite user pk", message: nil, preferredStyle: .alert)
        invitePKAlterView.addTextField { textField in
            textField.placeholder = "userID"
        }
        let sureAction: UIAlertAction = UIAlertAction(title: "sure", style: .default) { [weak self] action in
            if let textField = invitePKAlterView.textFields?[0] {
                if let userID = textField.text,
                   !userID.isEmpty
                {
                    self?.liveManager.invitePKBattle(targetUserID: userID, callback: { code, requestID in
                        if code != 0 {
                            self?.view.makeToast("invite user pk fail:\(code)", position: .center)
                        }
                    })
                }
            }
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel ", style: .cancel, handler: nil)
        invitePKAlterView.addAction(sureAction)
        invitePKAlterView.addAction(cancelAction)
        self.present(invitePKAlterView, animated: true)
    }
}

extension LiveStreamingViewController: ZIMServiceDelegate {
    
    func onInComingRoomRequestReceived(requestID: String, extendedData: String) {
        showReaDot()
    }
    
    func onInComingRoomRequestCancelled(requestID: String, extendedData: String) {
        showReaDot()
    }
    
    func onAcceptIncomingRoomRequest(errorCode: UInt, requestID: String, extendedData: String) {
        showReaDot()
    }
    
    func onRejectIncomingRoomRequest(errorCode: UInt, requestID: String, extendedData: String) {
        showReaDot()
    }
    
    func onOutgoingRoomRequestAccepted(requestID: String, extendedData: String) {
        onReceiveAcceptCoHostApply()
    }
    
    func onOutgoingRoomRequestRejected(requestID: String, extendedData: String) {
        onReceiveRefuseCoHostApply()
    }
    
}

extension LiveStreamingViewController: PKServiceDelegate {
    
    func onPKBattleReceived(requestID: String, info: ZIMCallInvitationReceivedInfo) {
        coHostRequestAlterView?.dismiss(animated: false)
        let inviterExtendedData = PKExtendedData.parse(extendedData: info.extendedData)
        if let inviterExtendedData = inviterExtendedData,
           inviterExtendedData.autoAccept
        {
            liveManager.acceptPKStartRequest(requestID: requestID)
        } else {
            alterView = UIAlertController(title: "receive pk request", message: "", preferredStyle: .alert)
            let acceptButton: UIAlertAction = UIAlertAction(title: "accept", style: .default) { [weak self] action in
                self?.liveManager.acceptPKStartRequest(requestID: requestID)
            }
            let rejectButton: UIAlertAction = UIAlertAction(title: "reject", style: .cancel) { [weak self] action in
                self?.liveManager.rejectPKStartRequest(requestID: requestID)
            }
            alterView!.addAction(acceptButton)
            alterView!.addAction(rejectButton)
            self.present(alterView!, animated: true)
        }
    }
    
    
    func onIncomingPKRequestCancelled() {
        alterView?.dismiss(animated: true)
    }
    
    func onOutgoingPKRequestRejected() {
        self.view.makeToast("pk request is rejected", position: .center)
        pkButton.setTitle("Start PK Battle", for: .normal)
    }
    
    func onIncomingPKRequestTimeout() {
        self.view.makeToast("pk request timeout", position: .center)
        alterView?.dismiss(animated: true)
    }
    
    func onOutgoingPKRequestTimeout() {
        pkButton.setTitle("Start PK Battle", for: .normal)
    }
    
    func onPKStarted() {
        startPKUpdateUI()
        if !isMySelfHost {
            if liveManager.isPKStarted && liveManager.isCoHost(userID: ZegoSDKManager.shared.currentUser?.id ?? "") {
                self.view.makeToast("host start pk, end cohost", position: .center)
            }
            endCoHostAction(endCoHostButton)
        } else {
            ZegoSDKManager.shared.zimService.roomRequestDict.forEach { (_, value) in
                ZegoSDKManager.shared.zimService.rejectRoomRequest(value.requestID, extendedData: nil, callback: nil)
            }
        }
    }
    
    func onPKEnded() {
        endPKUpdateUI()
        alterView?.dismiss(animated: false)
        if liveManager.isLocalUserHost() {
            ZegoSDKManager.shared.expressService.startPreview(mainVideoView.renderView)
        } else {
            ZegoSDKManager.shared.expressService.startPlayingStream(mainVideoView, streamID: liveManager.getHostMainStreamID())
        }
    }
    
    func onPKUserConnecting(userID: String, duration: Int) {
        if duration > 60000 {
            if userID != ZegoSDKManager.shared.currentUser?.id {
                liveManager.removeUserFromPKBattle(userID: userID)
            } else {
                liveManager.quitPKBattle()
            }
        }
    }
    
    func onPKMixTaskFail(code: Int32) {
        self.view.makeToast("pk mix task fail:\(code)", position: .center)
    }
    
}

