//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

@objc protocol IncomingCallDialogDelegate: AnyObject {
    @objc optional func onAcceptButtonClick(_ remoteUser: CallUserInfo)
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
    
    @IBOutlet weak var headImageView: UIImageView! {
        didSet {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = 21
        }
    }
    
    
    weak var delegate: IncomingCallDialogDelegate?
    
    var callData: ZegoCallDataModel? {
        get {
            return ZegoCallManager.shared.currentCallData
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(viewTap))
        self.addGestureRecognizer(tapClick)
    }
    
    static func show() -> ZegoIncomingCallDialog {
        return showTipView()
    }
    
    private static func showTipView() -> ZegoIncomingCallDialog {
        let tipView: ZegoIncomingCallDialog = Bundle.main.loadNibNamed("ZegoIncomingCallDialog", owner: self, options: nil)?.first as! ZegoIncomingCallDialog
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y + 8, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.setHeadUrl()
        tipView.setHeadUserName()
        tipView.userNameLabel.text = tipView.callData?.inviter?.userName ?? ""
        switch tipView.callData?.type ?? .voice {
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
    
    private func setHeadUserName() {
        guard let userName = callData?.inviter?.userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
    
    private func setHeadUrl() {
        guard let avatarUrl = URL(string: callData?.inviter?.headUrl ?? "") else { return }
        headImageView.isHidden = false
        headImageView.downloadedFrom(url: avatarUrl)
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
        guard let inviter = callData?.inviter else { return }
        showCallWaitingPage(inviter: inviter)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallWaitingPage(inviter: CallUserInfo) {
        let callWaitingVC: CallWaitingViewController = Bundle.main.loadNibNamed("CallWaitingViewController", owner: self, options: nil)?.first as! CallWaitingViewController
        callWaitingVC.modalPresentationStyle = .fullScreen
        callWaitingVC.isInviter = false
        callWaitingVC.inviter = inviter
        callWaitingVC.delegate = currentViewController() as? any CallWaitingViewControllerDelegate
        currentViewController()?.present(callWaitingVC, animated: true)
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        guard let inviter = callData?.inviter,
              let callID = callData?.callID
        else { return }
        ZegoCallManager.shared.acceptCallInvitation(requestID: callID) { requestID, error in
            if error.code == .ZIMErrorCodeSuccess {
                self.delegate?.onAcceptButtonClick?(inviter)
                ZegoIncomingCallDialog.hide()
            } else {
                self.makeToast("accept call failed:\(error.code.rawValue)", duration: 2.0, position: .center)
            }
        }
    }
    
    @IBAction func rejectButtonClick(_ sender: UIButton) {
        guard let callID = callData?.callID else { return }
        ZegoCallManager.shared.rejectCallInvitation(requestID: callID, callback: nil)
        ZegoIncomingCallDialog.hide()
    }
    
    func showCallMainPage(_ remoteUser: ZegoSDKUser) {
        let callMainPage: CallingViewController = Bundle.main.loadNibNamed("CallingViewController", owner: self, options: nil)?.first as! CallingViewController
        callMainPage.modalPresentationStyle = .fullScreen
        currentViewController()?.present(callMainPage, animated: true)
    }
    
}
