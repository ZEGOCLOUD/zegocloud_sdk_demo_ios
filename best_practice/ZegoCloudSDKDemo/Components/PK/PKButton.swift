//
//  PKButton.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/3.
//

import UIKit

class PKButton: UIButton, PKServiceDelegate {
    
    weak var viewController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
        self.setTitle("Start pk", for: .normal)
        self.addTarget(self, action: #selector(pkClick), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
        self.setTitle("Start pk", for: .normal)
        self.addTarget(self, action: #selector(pkClick), for: .touchUpInside)
    }

    @objc func pkClick() {
        let liveManger = ZegoLiveStreamingManager.shared
        if let _ = liveManger.pkInfo {
            self.setTitle("Start pk", for: .normal)
            if liveManger.isPKStarted {
                liveManger.quitPKBattle()
            } else {
                liveManger.endPKBattle()
            }
        } else {
            self.setTitle("End pk", for: .normal)
            let pkAlterView: UIAlertController = UIAlertController(title: "request pk", message: nil, preferredStyle: .alert)
            pkAlterView.addTextField { textField in
                textField.placeholder = "userID_1"
            }
            pkAlterView.addTextField { textField in
                textField.placeholder = "userID_2"
            }
            pkAlterView.addTextField { textField in
                textField.placeholder = "userID_3"
            }
            pkAlterView.addTextField { textField in
                textField.placeholder = "userID_4"
            }
            pkAlterView.addTextField { textField in
                textField.placeholder = "userID_5"
            }
            
            let sureAction: UIAlertAction = UIAlertAction(title: "sure", style: .default) { [weak self] action in
                var invitePKList: [String] = []
                if let textField1 = pkAlterView.textFields?[0],
                   let textField2 = pkAlterView.textFields?[1],
                   let textField3 = pkAlterView.textFields?[2],
                   let textField4 = pkAlterView.textFields?[3],
                   let textField5 = pkAlterView.textFields?[4]
                {
                    if let userID1 = textField1.text,
                       !userID1.isEmpty
                    {
                        invitePKList.append(userID1)
                    }
                    if let userID2 = textField2.text,
                       !userID2.isEmpty
                    {
                        invitePKList.append(userID2)
                    }
                    if let userID3 = textField3.text,
                       !userID3.isEmpty
                    {
                        invitePKList.append(userID3)
                    }
                    if let userID4 = textField4.text,
                       !userID4.isEmpty
                    {
                        invitePKList.append(userID4)
                    }
                    if let userID5 = textField5.text,
                       !userID5.isEmpty
                    {
                        invitePKList.append(userID5)
                    }
                }
                liveManger.invitePKbattle(targetUserIDList: invitePKList) { [weak self] code, requestID in
                    if code != 0 {
                        self?.setTitle("Start pk", for: .normal)
                        self?.viewController?.view.makeToast("invite pkbattle fail:\(code)", position: .center)
                    }
                }
            }
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "cancel ", style: .cancel) { action in
                self.setTitle("Start pk", for: .normal)
            }
            pkAlterView.addAction(sureAction)
            pkAlterView.addAction(cancelAction)
            self.viewController?.present(pkAlterView, animated: true)
        }
    }
    
    func onPKStarted() {
        self.setTitle("Quit pk", for: .normal)
    }
    
    func onPKEnded() {
        self.setTitle("Start pk", for: .normal)
    }
    
//    func onMixerStreamTaskFail(errorCode: Int) {
//        if ZegoLiveStreamingManager.shared.isPKStarted {
//            pkClick()
//        }
//    }
}
