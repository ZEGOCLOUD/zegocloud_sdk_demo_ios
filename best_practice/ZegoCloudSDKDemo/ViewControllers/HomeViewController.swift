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
    
    var invitee: ZegoSDKUser?

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDLabel.text = "User ID: " + userID
        liveIDTextField.text = String(UInt32.random(in: 100..<1000))
        audioRoomTextField.text = String(UInt32.random(in: 100..<1000))
        
        ZegoCallManager.shared.addCallEventHandler(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let liveVC = segue.destination as? LiveStreamingViewController {
            liveVC.isMySelfHost = segue.identifier! == "start_live"
            liveVC.liveID = liveIDTextField.text ?? ""
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
    
    // MARK: - Call Invitation
    @IBAction func voiceCallClick(_ sender: UIButton) {
        guard let inviteeUserID = callTextField.text else { return }
        invitee = ZegoSDKUser(id: inviteeUserID, name: "user_\(inviteeUserID)")
        //send call invitation
        ZegoCallManager.shared.sendVoiceCall(inviteeUserID) { requestID, sentInfo, error in
            if error.code == .success {
                // call waiting
                let errorInvitees = sentInfo.errorUserList.compactMap({ $0.userID })
                if errorInvitees.contains(inviteeUserID) {
                    self.view.makeToast("user is not online", duration: 2.0, position: .center)
                } else {
                    guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: invitee)
                }
            } else {
                self.view.makeToast("call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
            }
        }
    }
    
    @IBAction func videoCallClick(_ sender: UIButton) {
        guard let inviteeUserID = callTextField.text else { return }
        invitee = ZegoSDKUser(id: inviteeUserID, name: "user_\(inviteeUserID)")
        //send call invitation
        ZegoCallManager.shared.sendVideoCall(inviteeUserID) { requestID, sentInfo, error in
            if error.code == .success {
                // call waiting
                let errorInvitees = sentInfo.errorUserList.compactMap({ $0.userID })
                if errorInvitees.contains(inviteeUserID) {
                    self.view.makeToast("user is not online", duration: 2.0, position: .center)
                } else {
                    guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: invitee)
                }
            } else {
                self.view.makeToast("call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
            }
        }
    }
}

// MARK: - Call Invitation
extension HomeViewController {            
    func showCallWaitingPage(invitee: ZegoSDKUser) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = true
        callWaitingVC.invitee = invitee
        callWaitingVC.delegate = self
        self.present(callWaitingVC, animated: true)
    }
    
    func showReceiveCallWaitingPage(inviter: ZegoSDKUser, callID: String) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        self.present(callWaitingVC, animated: true)
    }
}

extension HomeViewController: CallWaitingViewControllerDelegate,
                                ZegoCallManagerDelegate {
    func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String) {
        //receive cancel call
        ZegoIncomingCallDialog.hide()
    }
    
    func onInComingUserRequestTimeout(requestID: String) {
        ZegoIncomingCallDialog.hide()
    }
    
    func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String) {
        self.view.makeToast("call is rejected:\(extendedData)", duration: 2.0, position: .center)
    }
    
    
    func startShowCallPage(_ remoteUser: ZegoSDKUser) {
        showCallPage(remoteUser)
    }
    
    func showCallPage(_ remoteUser: ZegoSDKUser) {
        let callMainPage = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        callMainPage.remoteUser = remoteUser
        self.present(callMainPage, animated: false)
    }
}
