//
//  PKForegroundView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/3.
//

import UIKit

class PKForegroundView: UIView {
    
    var containerView: UIView?

    var user: PKUser? {
        didSet {
            
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView = UIView()
        self.addSubview(containerView!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
    
}
