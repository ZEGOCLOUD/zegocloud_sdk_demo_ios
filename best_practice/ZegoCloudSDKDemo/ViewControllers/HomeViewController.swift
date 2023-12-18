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
            ZegoCallManager.shared.sendGroupVoiceCall(invitees) { code, requestID in
                if code == 0 {
                    // call waiting
                    //guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: nil, isGroupCall: true)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        } else {
            guard let inviteeUserID = callTextField.text else { return }
            invitee = ZegoSDKUser(id: inviteeUserID, name: "user_\(inviteeUserID)")
            //send call invitation
            ZegoCallManager.shared.sendVoiceCall(inviteeUserID) { code, requestID in
                if code == 0 {
                    // call waiting
                    guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: invitee, isGroupCall: false)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        }
        
//        ZegoCallManager.shared.sendVoiceCall(inviteeUserID) { requestID, sentInfo, error in
//            if error.code == .success {
//                // call waiting
//                let errorInvitees = sentInfo.errorUserList.compactMap({ $0.userID })
//                if errorInvitees.contains(inviteeUserID) {
//                    self.view.makeToast("user is not online", duration: 2.0, position: .center)
//                } else {
//                    guard let invitee = self.invitee else { return }
//                    self.showCallWaitingPage(invitee: invitee)
//                }
//            } else {
//                self.view.makeToast("call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
//            }
//        }
    }
    
    @IBAction func videoCallClick(_ sender: UIButton) {
        let invitees: [String] = getInviteeUsers()
        if getInviteeUsers().count > 1 {
            //group
            ZegoCallManager.shared.sendGroupVideoCall(invitees) { code, requestID in
                if code == 0 {
                    // call waiting
                    //guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: nil, isGroupCall: true)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        } else {
            guard let inviteeUserID = callTextField.text else { return }
            invitee = ZegoSDKUser(id: inviteeUserID, name: "user_\(inviteeUserID)")
            //send call invitation
            ZegoCallManager.shared.sendVideoCall(inviteeUserID) { code, requestID in
                if code == 0 {
                    guard let invitee = self.invitee else { return }
                    self.showCallWaitingPage(invitee: invitee, isGroupCall: false)
                } else {
                    self.view.makeToast("call failed:\(code)", duration: 2.0, position: .center)
                }
            }
        }
        
//        ZegoCallManager.shared.sendVideoCall(inviteeUserID) { requestID, sentInfo, error in
//            if error.code == .success {
//                // call waiting
//                let errorInvitees = sentInfo.errorUserList.compactMap({ $0.userID })
//                if errorInvitees.contains(inviteeUserID) {
//                    self.view.makeToast("user is not online", duration: 2.0, position: .center)
//                } else {
//                    guard let invitee = self.invitee else { return }
//                    self.showCallWaitingPage(invitee: invitee)
//                }
//            } else {
//                self.view.makeToast("call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
//            }
//        }
    }
}

// MARK: - Call Invitation
extension HomeViewController {            
    func showCallWaitingPage(invitee: ZegoSDKUser?, isGroupCall: Bool) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isGroupCall = isGroupCall
        callWaitingVC.isInviter = true
        callWaitingVC.invitee = invitee
        callWaitingVC.delegate = self
        self.callWaitingVC = callWaitingVC
        self.present(callWaitingVC, animated: true)
    }
    
    func showReceiveCallWaitingPage(inviter: ZegoSDKUser, callID: String, isGroupCall: Bool) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isGroupCall = isGroupCall
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        self.callWaitingVC = callWaitingVC
        self.present(callWaitingVC, animated: true)
    }
}

extension HomeViewController: CallWaitingViewControllerDelegate,
                                ZegoCallManagerDelegate {
    
    func onCallEnd() {
        callWaitingVC?.dismiss(animated: true)
        ZegoIncomingCallDialog.hide()
    }
    
    func onCallStart() {
        callWaitingVC?.dismiss(animated: true)
        guard let currentCallData = ZegoCallManager.shared.currentCallData,
        let inviter = currentCallData.inviter?.userInfo
        else { return }
        startShowCallPage(inviter)
    }
    
    func startShowCallPage(_ remoteUser: ZegoSDKUser) {
        showCallPage(remoteUser)
    }
    
    func showCallPage(_ remoteUser: ZegoSDKUser) {
        let callMainPage = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        self.present(callMainPage, animated: false)
    }
}
