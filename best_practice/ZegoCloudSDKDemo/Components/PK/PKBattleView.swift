//
//  PKBattleView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/1.
//

import UIKit

class PKBattleView: UIView {
    
    var pkUser: PKUser?
    var isCurrentUserHost: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPKUser(user: PKUser?, isCurrentUserHost: Bool) {
        
    }

}
