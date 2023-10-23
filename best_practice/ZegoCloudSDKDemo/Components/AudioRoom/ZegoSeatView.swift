//
//  ZegoSeatView.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2023/5/6.
//

import UIKit

protocol ZegoSeatViewDelegate: AnyObject {
    func onSeatViewDidClick(_ roomSeat: ZegoLiveAudioRoomSeat)
}

class ZegoSeatView: UIView {
    
    var roomSeat: ZegoLiveAudioRoomSeat? {
        didSet {
            if let userName = roomSeat?.currentUser?.name {
                headLabel.text = String(userName.prefix(1))
                nameLabel.text = userName
            }
            hostIcon.isHidden = (!isHost || roomSeat?.currentUser == nil)
            seatIcon.isHidden = (roomSeat?.currentUser != nil)
            headLabel.isHidden = (roomSeat?.currentUser == nil)
            nameLabel.isHidden = (roomSeat?.currentUser == nil)
            if let userID = roomSeat?.currentUser?.id {
                setAvatarUrl(userID)
                headImageView.isHidden = false
            } else {
                headImageView.isHidden = true
            }
            if ZegoLiveAudioRoomManager.shared.getHostUser()?.id == ZegoSDKManager.shared.currentUser?.id {
                if roomSeat?.currentUser == nil {
                    seatIcon.image = isLock ? UIImage(named: "seat_lock_icon") : UIImage(named: "seat_icon_normal")
                }
            } else {
                if roomSeat?.currentUser == nil {
                    seatIcon.image = isLock ? UIImage(named: "seat_lock_icon") : UIImage(named: "seat_up_icon")
                }
            }
        }
    }
    
    var isHost: Bool {
        get {
            return roomSeat?.seatIndex == ZegoLiveAudioRoomManager.shared.hostSeatIndex
        }
    }
    
    var isLock: Bool = false
    
    weak var delegate: ZegoSeatViewDelegate?
    
    lazy var seatIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "seat_icon_normal")
        return imageView
    }()
    
    lazy var seatButton: UIButton = {
        let button: UIButton = UIButton(type: .system)
        button.addTarget(self, action: #selector(seatButtonClick), for: .touchUpInside)
        return button
    }()
    
    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.darkGray
        return label
    }()
    
    lazy var headImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    lazy var nameLabel: UILabel = {
        let label: UILabel = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    lazy var micIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "seat_close_mic")
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var hostIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "seat_host_icon")
        imageView.isHidden = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.seatIcon)
        self.addSubview(self.headLabel)
        self.addSubview(self.headImageView)
        self.addSubview(self.seatButton)
        self.addSubview(self.micIcon)
        self.addSubview(self.hostIcon)
        self.addSubview(nameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.seatIcon.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width)
        self.headLabel.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width)
        self.headLabel.layer.masksToBounds = true
        self.headLabel.layer.cornerRadius = self.frame.size.width / 2
        self.headImageView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width)
        self.headImageView.layer.masksToBounds = true
        self.headImageView.layer.cornerRadius = self.frame.size.width / 2
        self.seatButton.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width)
        self.micIcon.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width)
        self.hostIcon.frame = CGRect(x: 0, y: seatIcon.frame.maxY - 20, width: self.frame.size.width, height: 20)
        self.nameLabel.frame = CGRect(x: 0, y: self.seatIcon.frame.maxY, width: self.frame.size.width, height: 20)
    }
    
    func setAvatarUrl(_ userID: String) {
        if let url = ZegoSDKManager.shared.zimService.usersAvatarUrlDict[userID] {
            if let avatarUrl = URL(string: url) {
                headImageView.downloadedFrom(url: avatarUrl)
            }
        }
    }
    
    @objc func seatButtonClick() {
        if let roomSeat = roomSeat {
            delegate?.onSeatViewDidClick(roomSeat)
        }
    }

}
