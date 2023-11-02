//
//  PKBattleView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/1.
//

import UIKit

class PKBattleViewContainer: UIView {
    
    var pkBattleViews: [PKBattleView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout() {
        for pkBattleView in pkBattleViews {
            
        }
    }
}

extension PKBattleViewContainer: PKServiceDelegate {
    
    func onPKUserJoin(userID: String, extendedData: String) {
        onRoomPKUserJoin()
    }
    
    func onPKUserQuit(userID: String, extendedData: String) {
        guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
        let isCurrentUserHost: Bool = ZegoLiveStreamingManager.shared.isLocalUserHost()

        for pkView in pkBattleViews {
            if pkView.pkUser?.userID == userID {
                pkView.setPKUser(user: nil, isCurrentUserHost: false)
                break
            }
        }
        removeAllPKView()
        
        for pkUser in pkInfo.pkUserList {
            if pkUser.hasAccepted {
                let pkBattleView = PKBattleView()
                pkBattleView.setPKUser(user: pkUser, isCurrentUserHost: isCurrentUserHost)
                pkBattleViews.append(pkBattleView)
            }
        }
    }
    
    private func removeAllPKView() {
        for pkBattleView in pkBattleViews {
            pkBattleView.removeFromSuperview()
        }
        pkBattleViews.removeAll()
    }
    
    private func onRoomPKUserJoin() {
        guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
        removeAllPKView()
        for pkUser in pkInfo.pkUserList {
            if pkUser.hasAccepted {
                let pkBattleView: PKBattleView = PKBattleView()
                pkBattleView.setPKUser(user: pkUser, isCurrentUserHost: ZegoLiveStreamingManager.shared.isLocalUserHost())
                pkBattleViews.append(pkBattleView)
            }
        }
    }
}
