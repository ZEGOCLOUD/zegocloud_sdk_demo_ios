//
//  PKConnectingView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/3.
//

import UIKit

class PKConnectingView: UIView {
    
    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = "host is reconnecting..."
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.addSubview(tipLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tipLabel.frame = CGRect(x: 5, y: (frame.size.height / 2) - 10, width: frame.size.width - 10, height: 20)
    }

}
