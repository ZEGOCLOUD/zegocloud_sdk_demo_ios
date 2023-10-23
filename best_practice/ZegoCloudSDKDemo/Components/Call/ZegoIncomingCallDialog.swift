//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

@objc protocol IncomingCallDialogDelegate: AnyObject {
    @objc optional func onAcceptButtonClick(_ remoteUser: ZegoSDKUser)
}

class ZegoIncomingCallDialog: UIView {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 21
            headLabel.textAlignment = .center
        }
    }
    
    weak var delegate: IncomingCallDialogDelegate?
    
    private var type: CallType = .voice
    var inviter: ZegoSDKUser?
    var callID: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(viewTap))
        self.addGestureRecognizer(tapClick)
    }
    
    static func show(_ inviter: ZegoSDKUser, callID: String, type: CallType) -> ZegoIncomingCallDialog {
        return showTipView(inviter, callID: callID, type: type)
    }
    
    private static func showTipView(_ inviter: ZegoSDKUser, callID: String, type: CallType) -> ZegoIncomingCallDialog {
        let tipView: ZegoIncomingCallDialog = Bundle.main.loadNibNamed("ZegoIncomingCallDialog", owner: self, options: nil)?.first as! ZegoIncomingCallDialog
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y + 8, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.type = type
        tipView.callID = callID
        tipView.inviter = inviter
        tipView.setHeadUserName(inviter.name)
        tipView.userNameLabel.text = inviter.name
        switch type {
        case .voice:
            tipView.messageLabel.text = "voice call"
            tipView.acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
        case .video:
            tipView.messageLabel.text =  "video call"
            tipView.acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
        }
        tipView.showTip()
        return tipView
    }
    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
        
    public static func hide() {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is ZegoIncomingCallDialog {
                    let view: ZegoIncomingCallDialog = subview as! ZegoIncomingCallDialog
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func showTip()  {
        KeyWindow().addSubview(self)
    }

    
    @objc func viewTap() {
        guard let inviter = inviter else { return }
        showCallWaitingPage(inviter: inviter)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallWaitingPage(inviter: ZegoSDKUser) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        callWaitingVC.delegate = currentViewController() as? any CallWaitingViewControllerDelegate
        currentViewController()?.present(callWaitingVC, animated: true)
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        guard let inviter = inviter,
        let callID = callID
        else { return }
        ZegoCallManager.shared.acceptCallRequest(requestID: callID) { requestID, error in
            if error.code == .success {
                self.delegate?.onAcceptButtonClick?(inviter)
                ZegoIncomingCallDialog.hide()
                self.showCallMainPage(inviter)
            } else {
                self.makeToast("accept call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
            }
        }
    }
    
    @IBAction func rejectButtonClick(_ sender: UIButton) {
        guard let callID = callID else { return }
        ZegoCallManager.shared.rejectCallRequest(requestID: callID, callback: nil)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallMainPage(_ remoteUser: ZegoSDKUser) {
        let callMainPage: CallingViewController = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        callMainPage.remoteUser = remoteUser
        currentViewController()?.present(callMainPage, animated: true)
    }
    
}
