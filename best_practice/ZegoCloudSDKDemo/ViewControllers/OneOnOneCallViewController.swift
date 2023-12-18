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
        for user in callUserList {
            if user.userInfo?.id == ZegoSDKManager.shared.currentUser?.id {
                smallVideoView.userID = user.userInfo?.id
                ZegoSDKManager.shared.expressService.startPreview(smallVideoView.renderView)
            } else {
                largeVideoView.userID = user.userInfo?.id
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
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open && ZegoCallManager.shared.currentCallData?.type == .video {
            self.view.makeToast("remote user camera close", duration: 2.0, position: .center)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if state != .open {
            self.view.makeToast("remote user microphone close", duration: 2.0, position: .center)
        }
    }
}
