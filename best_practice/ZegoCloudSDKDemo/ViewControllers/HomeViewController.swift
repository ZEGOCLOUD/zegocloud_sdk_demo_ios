//
//  HomeViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/30.
//

import UIKit
import ZIM

class HomeViewController: UIViewController {
    
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var liveIDTextField: UITextField!
    @IBOutlet weak var callTextField: UITextField!
    @IBOutlet weak var audioRoomTextField: UITextField!
    
    var userID: String = ""
    var userName: String = ""
    
    var invitee: CallUserInfo?
    
    weak var callWaitingVC: CallWaitingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIDLabel.text = "User ID: " + userID
        liveIDTextField.text = String(UInt32.random(in: 100..<1000))
        audioRoomTextField.text = String(UInt32.random(in: 100..<1000))
        
        ZegoCallManager.shared.addCallEventHandler(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        ZegoLiveStreamingManager.shared.addUserLoginListeners()
        if let liveVC = segue.destination as? LiveStreamingViewController {
            liveVC.isMySelfHost = segue.identifier! == "start_live"
            liveVC.liveID = liveIDTextField.text ?? ""
            liveVC.delegate = self
        }
        
        if let liveVC = segue.destination as? LiveAudioRoomViewController {
            liveVC.mySelfRole = segue.identifier! == "start_live_audio_room" ? .host : .audience
            liveVC.liveID = audioRoomTextField.text ?? ""
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        liveIDTextField.endEditing(true)
        callTextField.endEditing(true)
        audioRoomTextField.endEditing(true)
    }
    
    func getInviteeUsers() -> [String] {
        guard let inviteesUserID = callTextField.text else { return [] }
        let invitees = inviteesUserID.components(separatedBy: ",")
        if invitees.count > 1 {
            return invitees
        } else {
            return [inviteesUserID]
        }
    }
    
    // MARK: - Call Invitation
    @IBAction func voiceCallClick(_ sender: UIButton) {
        let invitees: [String] = getInviteeUsers()
        if getInviteeUsers().count > 1 {
            //group
            ZegoCallManager.shared.sendGroupVoiceCallInvitation(invitees) { code, requestID in
                if code != 0 {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                } else {
                    self.startOutgoingRing()
                }
            }
        } else {
            guard let inviteeUserID = callTextField.text else { return }
            invitee = CallUserInfo(userID: inviteeUserID)
            //send call invitation
            ZegoCallManager.shared.sendVoiceCallInvitation(inviteeUserID) { code, requestID in
                if code == 0 {
                    // call waiting
                    guard let invitee = self.invitee else { return }
                    self.startOutgoingRing()
                    self.showCallWaitingPage(invitee: invitee, isGroupCall: false)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        }
    }
    
    @IBAction func videoCallClick(_ sender: UIButton) {
        let invitees: [String] = getInviteeUsers()
        if getInviteeUsers().count > 1 {
            //group
            ZegoCallManager.shared.sendGroupVideoCallInvitation(invitees) { code, requestID in
                if code != 0 {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                } else {
                    self.startOutgoingRing()
                }
            }
        } else {
            guard let inviteeUserID = callTextField.text else { return }
            invitee = CallUserInfo(userID: inviteeUserID)
            //send call invitation
            ZegoCallManager.shared.sendVideoCallInvitation(inviteeUserID) { code, requestID in
                if code == 0 {
                    guard let invitee = self.invitee else { return }
                    self.startOutgoingRing()
                    self.showCallWaitingPage(invitee: invitee, isGroupCall: false)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        }
    }
    //MARK: customer
    func startIncomingRing() {
        
        let ringResourcePath = Bundle.main.path(forResource: "zego_incoming", ofType: "mp3")
        guard let ringResourcePath = ringResourcePath else { return }
        ZegoCallAudioPlayerTool.startPlay(ringResourcePath)
    }
    
    func startOutgoingRing() {
        let ringResourcePath = Bundle.main.path(forResource: "zego_outgoing", ofType: "mp3")
        guard let ringResourcePath = ringResourcePath else { return }
        ZegoCallAudioPlayerTool.startPlay(ringResourcePath)
    }
    func getMusicBundle() -> Bundle? {
        guard let resourcePath: String = Bundle.main.resourcePath else { return nil }
        let pathComponent = "/Frameworks/ZegoUIKitPrebuiltCall.framework/ZegoUIKitPrebuiltCall.bundle"
        let bundlePath = resourcePath + pathComponent
        let bundle = Bundle(path: bundlePath)
        return bundle
    }
}

// MARK: - Call Invitation
extension HomeViewController {
    func showCallWaitingPage(invitee: CallUserInfo?, isGroupCall: Bool) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isGroupCall = isGroupCall
        callWaitingVC.isInviter = true
        callWaitingVC.invitee = invitee
        self.callWaitingVC = callWaitingVC
        self.present(callWaitingVC, animated: true)
    }
    
    func showReceiveCallWaitingPage(inviter: CallUserInfo, callID: String, isGroupCall: Bool) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isGroupCall = isGroupCall
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        self.callWaitingVC = callWaitingVC
        self.present(callWaitingVC, animated: true)
    }
    
}

extension HomeViewController : LiveStreamingCallVCDelegate {
    func getCurrentPipRenderStreamID(streamsDicts:[String:String]) -> String? {
//        var streamid:String = ""
//        for (streamID,userID) in streamsDicts {
//            if streamID.hasSuffix("_main_cohost") && userID != self.userID {
//                streamid = streamID
//            }
//        }
        return ""
    }
}

extension HomeViewController: ZegoCallManagerDelegate {
    
    func onCallEnd() {
        ZegoCallAudioPlayerTool.stopPlay()
        callWaitingVC?.dismiss(animated: true)
        ZegoIncomingCallDialog.hide()
    }
    
    func onCallStart() {
        callWaitingVC?.dismiss(animated: true)
        showCallPage()
    }
    
    func onOutgoingCallInvitationRejected(userID: String, extendedData: String) {
        let callData = extendedData.toDict
        if let callData = callData, callData["reason"] as? String ?? "" == "busy" {
            self.view.makeToast("invitee is busy", duration: 2.0, position: .center)
        }
        ZegoCallAudioPlayerTool.stopPlay()
    }
    
    func onInComingCallInvitationTimeout(requestID: String) {
        callWaitingVC?.dismiss(animated: true)
        ZegoIncomingCallDialog.hide()
        ZegoCallAudioPlayerTool.stopPlay()
    }
    
    func showCallPage() {
        ZegoCallAudioPlayerTool.stopPlay()
        let callMainPage = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        
        let navgationVC = UINavigationController(rootViewController: callMainPage)
        navgationVC.modalPresentationStyle = .fullScreen
        self.present(navgationVC, animated: false)
    }
}
