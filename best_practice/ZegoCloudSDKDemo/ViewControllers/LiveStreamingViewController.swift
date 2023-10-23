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

class LiveStreamingViewController: UIViewController {

    @IBOutlet weak var mainStreamView: VideoView!
    @IBOutlet weak var streamViewContainer: UIView!
    @IBOutlet weak var streamViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var streamViewToTop: NSLayoutConstraint!
    
    
    @IBOutlet weak var anotherHostStreamView: UIView!
    @IBOutlet weak var preBackgroundView: UIView!
    @IBOutlet weak var startLiveButton: UIButton!
    @IBOutlet weak var mixerStreamView: UIView!
    @IBOutlet weak var mainStreamViewToRight: NSLayoutConstraint!

    
    @IBOutlet weak var liveContainerView: UIView!
    @IBOutlet weak var userNameConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var memberButton: UIButton! {
        didSet {
            memberButton.addSubview(redDot)
        }
    }
    @IBOutlet weak var flipButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var endCoHostButton: UIButton!
    @IBOutlet weak var coHostButton: UIButton!
    @IBOutlet weak var coHostWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var pkButton: UIButton! {
        didSet {
            pkButton.layer.masksToBounds = true
            pkButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var leftHostConnectingLabel: UILabel!
    @IBOutlet weak var rightHostConnectingLabel: UILabel!
    @IBOutlet weak var leftHostMaskView: UIView!
    @IBOutlet weak var rightHostMaskView: UIView!
    
    @IBOutlet weak var leftMainHostMaskView: UIView!
    @IBOutlet weak var rightMainHostMaskView: UIView!
    
    @IBOutlet weak var localHostMainForegroundView: UIView!
    @IBOutlet weak var localHostMainHeadLabel: UILabel! {
        didSet {
            localHostMainHeadLabel.layer.masksToBounds = true
            localHostMainHeadLabel.layer.cornerRadius = 40
            localHostMainHeadLabel.backgroundColor = UIColor.black
        }
    }
    
    @IBOutlet weak var anotherHostMainForegroundView: UIView!
    @IBOutlet weak var anotherHostMainHeadLabel: UILabel!{
        didSet {
            anotherHostMainHeadLabel.layer.masksToBounds = true
            anotherHostMainHeadLabel.layer.cornerRadius = 40
            anotherHostMainHeadLabel.backgroundColor = UIColor.black
        }
    }
    
    @IBOutlet weak var localHostMixForegroundView: UIView!
    @IBOutlet weak var localHostMixHeadLabel: UILabel! {
        didSet {
            localHostMixHeadLabel.layer.masksToBounds = true
            localHostMixHeadLabel.layer.cornerRadius = 40
            localHostMixHeadLabel.backgroundColor = UIColor.black
        }
    }
    
    @IBOutlet weak var anotherHostMixForegroundView: UIView!
    @IBOutlet weak var anotherHostMixHeadLabel: UILabel! {
        didSet {
            anotherHostMixHeadLabel.layer.masksToBounds = true
            anotherHostMixHeadLabel.layer.cornerRadius = 40
            anotherHostMixHeadLabel.backgroundColor = UIColor.black
        }
    }
    
    
    
    
    @IBOutlet weak var muteAudioButton: UIButton! {
        didSet {
            muteAudioButton.setImage(UIImage(named: "icon_speaker_normal"), for: .normal)
            muteAudioButton.setImage(UIImage(named: "icon_speaker_off"), for: .selected)
        }
    }
    
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
    
    var alterView: UIAlertController?
    var coHostRequestAlterView: UIAlertController?

    var coHostVideoViews: [CoHostViewModel] = []
    
    var isMySelfHost: Bool = false
    var liveID: String = ""
    var userCount = 1
    
    var currentRoomRequestID: String?
    let liveManager = ZegoLiveStreamingManager.shared
    
    deinit {
        print("\(String(describing: type(of: self))) \(#function)")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        liveManager.addUserLoginListeners()
        liveManager.addPKDelegate(self)
        liveManager.eventDelegates.add(self)
        if isMySelfHost {
            liveManager.hostUser = ZegoSDKManager.shared.currentUser
        }
        configUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        liveContainerView.isHidden = isMySelfHost
        preBackgroundView.isHidden = !isMySelfHost
        liveContainerView.addSubview(coHostVideoContainerView)
        if isMySelfHost {
            ZegoSDKManager.shared.expressService.turnCameraOn(true)
            ZegoSDKManager.shared.expressService.turnMicrophoneOn(true)
            startPreviewIfHost()
            updateUserNameLabel(ZegoSDKManager.shared.expressService.currentUser?.name)
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
            ZegoSDKManager.shared.expressService.startPreview(mainStreamView.renderView)
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
        
        mainStreamView.update(ZegoSDKManager.shared.expressService.currentUser?.id, ZegoSDKManager.shared.expressService.currentUser?.name)
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        func leaveRoom() {
            liveManager.isLiveStart = false
            liveManager.leaveRoom()
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
//        coHostVideoViews.forEach( { $0.removeFromSuperview() } )
        coHostVideoViews = coHostVideoViews.filter({ $0.user?.id != localUserID })
        coHostVideoContainerView.coHostModels = coHostVideoViews
        updateCoHostContainerFrame()
//        updateCoHostConstraints()
        coHostButton.isHidden = false
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
            mainStreamView.enableCamera(!sender.isSelected)
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
    
    @IBAction func pkButtonClick(_ sender: UIButton) {
        if liveManager.pkState == .isStartPK {
            liveManager.sendPKBattlesStopRequest()
            sender.setTitle("Start PK Battle", for: .normal)
        } else if liveManager.pkState == .isNoPK {
            sender.setTitle("Cancel PK Battle", for: .normal)
            var userIDTextField:UITextField = UITextField()
            let pkAlterView: UIAlertController = UIAlertController(title: "request pk", message: nil, preferredStyle: .alert)
            let sureAction: UIAlertAction = UIAlertAction(title: "sure", style: .default) { [weak self] action in
                guard let userID = userIDTextField.text else {
                    return
                }
                self?.liveManager.sendPKBattlesStartRequest(userID: userID) { [weak self] code, message in
                    if message.count > 0 {
                        sender.setTitle("Start PK Battle", for: .normal)
                        self?.view.makeToast(message, position: .center)
                    }
                }
            }
            let cancelAction: UIAlertAction = UIAlertAction(title: "cancel ", style: .cancel) { action in
                sender.setTitle("Start PK Battle", for: .normal)
            }
            pkAlterView.addTextField { textField in
                userIDTextField = textField
                userIDTextField.placeholder = "userID"
            }
            pkAlterView.addAction(sureAction)
            pkAlterView.addAction(cancelAction)
            self.present(pkAlterView, animated: true)
        } else {
            sender.setTitle("Start PK Battle", for: .normal)
            liveManager.cancelPKBattleRequest()
        }
    }
    
    @IBAction func muteAnotherAudioClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        liveManager.muteAnotherHostAudio(mute: sender.isSelected)
    }
    
    @IBAction func memberButtonClick(_ sender: Any) {
        if !isMySelfHost {
            return
        }
        let applyVC: ApplyCoHostListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ApplyCoHostListViewController") as! ApplyCoHostListViewController
        self.present(applyVC, animated: true)
    }
    
    
}

extension LiveStreamingViewController: ZegoLiveStreamingManagerDelegate {
    
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
            mainStreamView.enableCamera(isCameraOpen)
        } else {
            let videoViews = coHostVideoViews.filter({ $0.user?.id == userID })
            videoViews.forEach({ $0.isCamerOn = isCameraOpen})
            coHostVideoContainerView.cameraStateChange(userID, isOn: isCameraOpen)
        }
    }
    
    
    func showMixView() {
        mixerStreamView.isHidden = false
        streamViewContainer.isHidden = true
        mainStreamViewToRight.constant = 0
    }
    
    func startPKUpdateUI() {
        if isMySelfHost {
            pkButton.setTitle("End PK Battle", for: .normal)
            mainStreamViewToRight.constant = self.view.frame.size.width * 0.5
            mixerStreamView.isHidden = true
            streamViewContainer.isHidden = false
            let height = streamViewContainer.bounds.size.width * (480 / 540)
            streamViewToBottom.constant =  streamViewContainer.bounds.size.height - height
            streamViewToTop.constant = 45
            
            leftHostMaskView.isHidden = true
            rightHostMaskView.isHidden = true
            leftMainHostMaskView.isHidden = true
            rightMainHostMaskView.isHidden = true
            
            muteAudioButton.isHidden = false
        }
    }
    
    func endPKUpdateUI() {
        mixerStreamView.isHidden = true
        streamViewContainer.isHidden = false
        leftHostMaskView.isHidden = true
        rightHostMaskView.isHidden = true
        leftMainHostMaskView.isHidden = true
        rightMainHostMaskView.isHidden = true
        streamViewToBottom.constant = 0
        streamViewToTop.constant = 0
        mainStreamViewToRight.constant = 0
        anotherHostMainHeadLabel.isHidden = true
        if isMySelfHost {
            muteAudioButton.isHidden = true
            muteAudioButton.isSelected = false
            pkButton.setTitle("Start PK Battle", for: .normal)
        }
    }
    
    func onAnotherHostIsReconnecting() {
        if isMySelfHost {
            rightMainHostMaskView.isHidden = false
        } else {
            rightHostMaskView.isHidden = false
        }
        liveManager.muteAnotherHostAudio(mute: true)
    }
    
    func onHostIsReconnecting() {
        if isMySelfHost {
            leftMainHostMaskView.isHidden = false
        } else {
            leftHostMaskView.isHidden = false
        }
    }
    
    func onHostIsConnected() {
        if isMySelfHost {
            leftMainHostMaskView.isHidden = true
        } else {
            leftHostMaskView.isHidden = true
        }
    }
    
    func onAnotherHostIsConnected() {
        if isMySelfHost {
            rightMainHostMaskView.isHidden = true
        } else {
            rightHostMaskView.isHidden = true
        }
        liveManager.muteAnotherHostAudio(mute: muteAudioButton.isSelected)
    }
    
    func onLocalHostCameraStatus(isOn: Bool) {
        if isMySelfHost {
            localHostMainForegroundView.isHidden = isOn
            localHostMainHeadLabel.text = headName(liveManager.hostUser?.name ?? "")
        } else {
            localHostMixForegroundView.isHidden = isOn
            localHostMixHeadLabel.text = headName(liveManager.hostUser?.name ?? "")
        }
    }
    
    
    func onAnotherHostCameraStatus(isOn: Bool) {
        if isMySelfHost {
            anotherHostMainForegroundView.isHidden = isOn
            anotherHostMainHeadLabel.isHidden = isOn
            anotherHostMainHeadLabel.text = headName(liveManager.pkInfo?.pkUser.name ?? "")
        } else {
            anotherHostMixForegroundView.isHidden = isOn
            anotherHostMixHeadLabel.text = headName(liveManager.pkInfo?.pkUser.name ?? "")
        }
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
            ZegoSDKManager.shared.expressService.startPlayingStream(mainStreamView.renderView, streamID: streamID)
            updateUserNameLabel(userName)
            mainStreamView.update(userID, userName)
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
    
    func onIncomingPKRequestReceived(requestID: String) {
        coHostRequestAlterView?.dismiss(animated: false)
        
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
    
    
    func onIncomingPKRequestCancelled() {
        alterView?.dismiss(animated: true)
    }
    
    func onOutgoingPKRequestRejected() {
        self.view.makeToast("pk request is rejected", position: .center)
        pkButton.setTitle("Start PK Battle", for: .normal)
    }
    
    func onIncomingPKRequestTimeout() {
        alterView?.dismiss(animated: true)
    }
    
    func onOutgoingPKRequestTimeout() {
        pkButton.setTitle("Start PK Battle", for: .normal)
    }
    
    func onStartPlayMixerStream() {
        ZegoSDKManager.shared.expressService.startPlayingStream(mixerStreamView, streamID: ZegoSDKManager.shared.expressService.generateMixerStreamID())
        coHostButton.isSelected = false
        coHostWidthConstraint.constant = 0
    }
    
    func onStopPlayMixerStream() {
        guard let roomID = ZegoSDKManager.shared.expressService.currentRoomID else {
            return
        }
        ZegoSDKManager.shared.expressService.stopPlayingStream(String(format: "%@_mix", roomID))
        coHostButton.isSelected = false
        mixerStreamView.isHidden = true
        coHostWidthConstraint.constant = 165
    }
    
    func onMixerStreamTaskFail(errorCode: Int) {
        self.view.makeToast("mixer stream fail:\(errorCode)", position: .center)
        if liveManager.pkState == .isStartPK {
            pkButtonClick(pkButton)
        }
    }
    
    func onPKStarted(roomID: String, userID: String) {
        startPKUpdateUI()
        if isMySelfHost {
            let anotherHostStreamID = roomID + "_" + userID + "_main" + "_host"
            ZegoSDKManager.shared.expressService.startPlayingStream(anotherHostStreamView, streamID: anotherHostStreamID)
            ZegoSDKManager.shared.zimService.roomRequestDict.forEach { (_, value) in
                ZegoSDKManager.shared.zimService.rejectRoomRequest(value.requestID, extendedData: nil, callback: nil)
            }
        } else {
            if liveManager.pkState == .isStartPK && liveManager.isCoHost(userID: ZegoSDKManager.shared.currentUser?.id ?? "") {
                self.view.makeToast("host start pk, end cohost", position: .center)
            }
            endCoHostAction(endCoHostButton)
        }
    }
    
    func onPKEnded(roomID: String, userID: String) {
        endPKUpdateUI()
        if isMySelfHost {
            let anotherHostStreamID = roomID + "_" + userID + "_main" + "_host"
            ZegoSDKManager.shared.expressService.stopPlayingStream(anotherHostStreamID)
        }
    }

    
    func onPKViewAvaliable() {
        if (!isMySelfHost) {
            showMixView()
        }
    }
    
}

