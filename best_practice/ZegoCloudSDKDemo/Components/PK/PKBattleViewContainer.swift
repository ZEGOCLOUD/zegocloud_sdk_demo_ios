//
//  PKBattleView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/1.
//

import UIKit

class PKBattleViewContainer: UIView {
    
    var pkBattleViews: [PKBattleView] = []
    
    lazy var mixVideoView: PKBattleMixView = {
        let view = PKBattleMixView()
        return view
    }()
    
    var w_ratio: CGFloat = 1
    var h_ratio: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        initData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initData()
    }
    
    func initData() {
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
        if !ZegoLiveStreamingManager.shared.isLocalUserHost() {
            self.addSubview(mixVideoView)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sizeConversion()
        if !ZegoLiveStreamingManager.shared.isLocalUserHost() {
            mixVideoView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        }
    }
    
    func updateLayout() {
        if ZegoLiveStreamingManager.shared.isLocalUserHost() {
            for pkBattleView in pkBattleViews {
                if let pkUser = pkBattleView.pkUser {
                    pkBattleView.frame = convertToFrame(pkUser.edgeInsets)
                    self.addSubview(pkBattleView)
                }
            }
        }
    }
    
    func convertToFrame(_ inset: UIEdgeInsets) -> CGRect {
        let width = inset.right - inset.left
        let height = inset.bottom - inset.top
        let rect = CGRect(x: inset.left * w_ratio, y: inset.top * h_ratio, width: width * w_ratio, height: height * h_ratio)
        return rect
    }
    
    func sizeConversion() {
        w_ratio = self.bounds.size.width / 1080
        h_ratio = self.bounds.size.height / 960
    }
}

extension PKBattleViewContainer: PKServiceDelegate {
    
    func onPKUserConnecting(userID: String, duration: Int) {
        
    }
    
    func onPKUserJoin(userID: String, extendedData: String) {
        onRoomPKUserJoin()
    }
    
    func onPKUserUpdate(userList: [String]) {
        onRoomPKUserJoin()
    }
    
    func onPKUserQuit(userID: String, extendedData: String) {
        guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
        let isCurrentUserHost: Bool = ZegoLiveStreamingManager.shared.isLocalUserHost()

        for pkView in pkBattleViews {
            if pkView.pkUser?.userID == userID {
                pkView.setPKUser(user: nil, addVideoView: false)
                break
            }
        }
        removeAllPKView()
        for pkUser in pkInfo.pkUserList {
            if pkUser.hasAccepted {
                let pkBattleView = PKBattleView()
                pkBattleView.setPKUser(user: pkUser, addVideoView: isCurrentUserHost)
                pkBattleViews.append(pkBattleView)
            }
        }
        updateLayout()
    }
    
    private func removeAllPKView() {
        for pkBattleView in pkBattleViews {
            pkBattleView.removeFromSuperview()
        }
        pkBattleViews.removeAll()
    }
    
    private func onRoomPKUserJoin() {
        guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
        if ZegoLiveStreamingManager.shared.isLocalUserHost() {
            removeAllPKView()
            for pkUser in pkInfo.pkUserList {
                if pkUser.hasAccepted {
                    let pkBattleView: PKBattleView = PKBattleView()
                    pkBattleView.setPKUser(user: pkUser, addVideoView: ZegoLiveStreamingManager.shared.isLocalUserHost())
                    pkBattleViews.append(pkBattleView)
                }
            }
            updateLayout()
        } else {
            // is not host display mixe view
            mixVideoView.pkAcceptUsers = pkInfo.pkUserList.filter({ user in
                return user.hasAccepted
            })
            mixVideoView.mixStreamID = "\(ZegoSDKManager.shared.expressService.currentRoomID ?? "")_mix"
        }
    }
}
