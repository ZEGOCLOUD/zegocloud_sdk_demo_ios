//
//  OneOnOneCallViewController.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/14.
//

import UIKit
import ZegoExpressEngine

class OneOnOneCallViewController: UIViewController {
    
    var callUserList: [CallUserInfo] = []
    
    @IBOutlet weak var largetViewContainer: UIView! {
        didSet {
            largetViewContainer.backgroundColor = .init(hex: "#4A4B4D")
        }
    }
    @IBOutlet weak var largeVideoView: VideoView!
    @IBOutlet weak var smallViewContainer: UIView! {
        didSet {
            smallViewContainer.backgroundColor = .init(hex: "#333437")
        }
    }
    @IBOutlet weak var smallVideoView: VideoView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        for user in callUserList {
            if user.userID == ZegoSDKManager.shared.currentUser?.id {
                smallVideoView.userID = user.userID
                smallVideoView.setNameLabel(user.userName)
                smallVideoView.setAvatar(user.headUrl ?? "")
                ZegoSDKManager.shared.expressService.startPreview(smallVideoView.renderView)
            } else {
                largeVideoView.userID = user.userID
                largeVideoView.setNameLabel(user.userName)
                largeVideoView.setAvatar(user.headUrl ?? "")
                ZegoSDKManager.shared.expressService.startPlayingStream(largeVideoView.renderView, streamID: user.streamID)
            }
        }
        if ZegoCallManager.shared.currentCallData?.type == .voice {
            smallVideoView.enableCamera(false)
            largeVideoView.enableCamera(false)
        }
    }

}

extension OneOnOneCallViewController: ExpressServiceDelegate {
    
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        if userID == smallVideoView.userID {
            smallVideoView.enableCamera(isCameraOpen)
        } else if userID == largeVideoView.userID {
            largeVideoView.enableCamera(isCameraOpen)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open {
            self.view.makeToast("remote user microphone close", duration: 2.0, position: .center)
        }
    }
}
