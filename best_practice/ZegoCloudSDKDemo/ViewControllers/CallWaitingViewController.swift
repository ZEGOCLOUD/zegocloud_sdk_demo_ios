//
//  ZegoUIKitPrebuiltCallWaitingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZIM

protocol CallWaitingViewControllerDelegate: AnyObject {
    func startShowCallPage(_ remoteUser: ZegoSDKUser)
}

class CallWaitingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoCallManager.shared.addCallEventHandler(self)
    }
    
    @IBOutlet weak var backgroundImage: UIImageView! {
        didSet {
            backgroundImage.image = UIImage(named: "call_waiting_bg")
        }
    }
    
    @IBOutlet weak var videoPreviewView: UIView! {
        didSet {
            if ZegoCallManager.shared.currentCallData?.type == .video {
                ZegoSDKManager.shared.expressService.turnCameraOn(true)
                ZegoSDKManager.shared.expressService.startPreview(videoPreviewView)
            }
        }
    }
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 50
            if !self.isInviter {
                self.setHeadUserName(invitee?.name)
            }
        }
    }
    
    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            userNameLabel.text = invitee?.name
        }
    }
    @IBOutlet weak var callStatusLabel: UILabel!
    
    @IBOutlet weak var declineView: UIView! {
        didSet {
            declineView.isHidden = self.isInviter
        }
    }
    @IBOutlet weak var acceptView: UIView! {
        didSet {
            acceptView.isHidden = self.isInviter
        }
    }
    
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var declineButtonLabel: UILabel!
    @IBOutlet weak var cancelInviationButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton! {
        didSet {
            if ZegoCallManager.shared.currentCallData?.type == .video {
                acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
            } else {
                acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
            }
        }
    }
    @IBOutlet weak var acceptButtonLabel: UILabel!
    @IBOutlet weak var switchFacingCameraButton: UIButton!
    
    var invitee: ZegoSDKUser? {
        didSet {
            if isInviter {
                self.setHeadUserName(invitee?.name)
                self.userNameLabel.text = invitee?.name
            }
        }
    }
    var inviter: ZegoSDKUser? {
        didSet {
            if !self.isInviter {
                self.setHeadUserName(inviter?.name)
                self.userNameLabel.text = inviter?.name
            }
        }
    }
        
    
    var isInviter: Bool = false {
        didSet {
            if isInviter {
                self.cancelInviationButton.isHidden = false
                self.acceptView.isHidden = true
                self.declineView.isHidden = true
            } else {
                self.cancelInviationButton.isHidden = true
                self.acceptView.isHidden = false
                self.declineView.isHidden = false
            }
            
        }
    }
    
    var showDeclineButton: Bool = true {
        didSet {
            if showDeclineButton == false {
                self.declineView.isHidden = true
                let acceptRect: CGRect = self.acceptView.frame
                let x: CGFloat = (self.view.frame.width - acceptRect.width)/2
                self.trailingConstraint.constant = x
            }
        }
    }
    
    weak var delegate: CallWaitingViewControllerDelegate?
    
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    

    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
    
    @IBAction func declineButtonClick(_ sender: Any) {
        guard let callID = ZegoCallManager.shared.currentCallData?.callID else { return }
        ZegoCallManager.shared.rejectCallRequest(requestID: callID, callback: nil)
        ZegoSDKManager.shared.logoutRoom()
        self.dismiss(animated: true)
    }
    
    @IBAction func handupButtonClick(_ sender: Any) {
        guard let inviteeUserID = invitee?.id,
              let callID = ZegoCallManager.shared.currentCallData?.callID
        else { return }
        ZegoCallManager.shared.cancelCallRequest(requestID: callID, userID: inviteeUserID, callback: nil)
        ZegoSDKManager.shared.logoutRoom()
        self.dismiss(animated: true)
    }
    
    @IBAction func acceptButtonClick(_ sender: Any) {
        guard let callID = ZegoCallManager.shared.currentCallData?.callID else { return }
        ZegoCallManager.shared.acceptCallRequest(requestID: callID) { requestID, error in
            if error.code == .success {
                guard let remoteUser = ZegoCallManager.shared.currentCallData?.inviter else { return }
                self.showCallPage(remoteUser)
            }
        }
    }
    
    func showCallPage(_ remoteUser: ZegoSDKUser) {
        DispatchQueue.main.async {
            self.dismiss(animated: false)
            self.delegate?.startShowCallPage(remoteUser)
        }
    }

}

extension CallWaitingViewController: ZegoCallManagerDelegate {
    
    func onOutgoingUserRequestAccepted(requestID: String, invitee: String, extendedData: String) {
        guard let remoteUser = ZegoCallManager.shared.currentCallData?.invitee else { return }
        showCallPage(remoteUser)
    }
    
    func onOutgoingUserRequestRejected(requestID: String, invitee: String, extendedData: String) {
        let callData = extendedData.toDict
        if let callData = callData, callData["reason"] as? String ?? "" == "busy" {
            self.view.makeToast("invitee is busy", duration: 2.0, position: .center)
        }
        ZegoCallManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func onInComingUserRequestCancelled(requestID: String, inviter: String, extendedData: String) {
        self.dismiss(animated: true)
    }
    
    func onInComingUserRequestTimeout(requestID: String) {
        ZegoCallManager.shared.leaveRoom()
        self.dismiss(animated: true)
    }
    
    func onOutgoingUserRequestTimeout(requestID: String) {
        ZegoCallManager.shared.leaveRoom()
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
