//
//  PKBattleMixView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/11/2.
//

import UIKit

class PKBattleMixView: UIView {
    
    var w_ratio: CGFloat = 1
    var h_ratio: CGFloat = 1
    
    lazy var videoView: UIView = {
        let view = UIView()
        return view
    }()
    
    var pkAcceptUsers: [PKUser] = [] {
        didSet {
            createPKMaskView()
        }
    }
    
    var mixStreamID: String? {
        didSet {
            if let mixStreamID = mixStreamID {
                ZegoSDKManager.shared.expressService.startPlayingStream(self.videoView, streamID: mixStreamID)
            }
        }
    }
    
    lazy var mixMaskContainerView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    
    var mixMaskViews: [PKMixMaskView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(videoView)
        self.addSubview(mixMaskContainerView)
        ZegoLiveStreamingManager.shared.addPKDelegate(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        sizeConversion()
        videoView.frame = self.bounds
        mixMaskContainerView.frame = self.bounds
    }
    
    func createPKMaskView() {
        mixMaskViews.forEach { view in
            view.removeFromSuperview()
        }
        mixMaskViews.removeAll()
        for user in pkAcceptUsers {
            let view = PKMixMaskView(frame: convertToFrame(user.edgeInsets))
            view.user = user
            mixMaskContainerView.addSubview(view)
            mixMaskViews.append(view)
        }
    }
    
    func convertToFrame(_ inset: UIEdgeInsets) -> CGRect {
        let width = inset.right - inset.left
        let height = inset.bottom - inset.top
        let rect = CGRect(x: inset.left * w_ratio, y: inset.top * h_ratio, width: width * w_ratio, height: height * h_ratio)
        return rect
    }
    
    func sizeConversion() {
        w_ratio = self.bounds.size.width / 972
        h_ratio = self.bounds.size.height / 864
    }
}

class PKMixMaskView: UIView {
    
    var user: PKUser? {
        didSet {
            guard let user = user else { return }
            setNameLabel(user.userName)
        }
    }
    
    public lazy var backgroundView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .init(red: 74/255.0, green: 75/255.0, blue: 77/255.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public lazy var connectingView: PKConnectingView = {
        let view = PKConnectingView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var nameHeadLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.backgroundColor = UIColor.black
        label.layer.cornerRadius = 40
        label.layer.masksToBounds = true
        label.isHidden = true
        label.textAlignment = .center
        return label
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 10)
        label.backgroundColor = .init(red: 0.164706, green: 0.164706, blue: 0.164706, alpha: 0.5)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isHidden = true
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nameLabelWidthConstraint: NSLayoutConstraint = {
        nameLabel.widthAnchor.constraint(equalToConstant: 60)
    }()
    
    private func setNameLabel(_ name: String?) {
        nameLabel.text = name
        nameLabel.isHidden = false
        nameLabelWidthConstraint.constant = nameLabel.intrinsicContentSize.width + 15
        
        if let name = name,
           name.count > 0
        {
            nameHeadLabel.text = String(name[name.startIndex])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(backgroundView)
        self.addSubview(nameHeadLabel)
        self.addSubview(nameLabel)
        self.addSubview(connectingView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            connectingView.topAnchor.constraint(equalTo: topAnchor),
            connectingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            connectingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            connectingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            nameLabel.heightAnchor.constraint(equalToConstant: 22),
            nameLabelWidthConstraint
        ])
        
        NSLayoutConstraint.activate([
            nameHeadLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            nameHeadLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            nameHeadLabel.widthAnchor.constraint(equalToConstant: 80),
            nameHeadLabel.heightAnchor.constraint(equalToConstant: 80)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enableCamera(enable: Bool) {
        backgroundView.isHidden = enable
        nameHeadLabel.isHidden = enable
    }
    
    func isConnectingState(isConnecting: Bool) {
        connectingView.isHidden = !isConnecting
    }
    
}

extension PKBattleMixView: PKServiceDelegate {
    
    func onPKUserCameraOpen(userID: String, isCameraOpen: Bool) {
        mixMaskViews.forEach { view in
            if view.user?.userID == userID {
                view.enableCamera(enable: isCameraOpen)
            }
        }
    }
    
    func onPKUserConnecting(userID: String, duration: Int) {
        mixMaskViews.forEach { view in
            if view.user?.userID == userID {
                view.isConnectingState(isConnecting: duration > 5000)
            }
        }
    }
    
}
