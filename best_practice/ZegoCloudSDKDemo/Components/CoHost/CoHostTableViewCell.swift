//
//  CoHostTableViewCell.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/6/30.
//

import UIKit

protocol CoHostTableViewCellDelegate: AnyObject {
    func agreeCoHostApply(request: RoomRequest)
    func disAgreeCoHostApply(request: RoomRequest)
}

class CoHostInfo: NSObject {
    var userID: String
    var userName: String
    var messageID: String
    
    init(userID: String, userName: String, messageID: String) {
        self.userID = userID
        self.userName = userName
        self.messageID = messageID
    }
}

class CoHostTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton! {
        didSet {
            agreeButton.layer.masksToBounds = true
            agreeButton.layer.cornerRadius = 8
        }
    }
    @IBOutlet weak var disAgreeButton: UIButton! {
        didSet {
            disAgreeButton.layer.masksToBounds = true
            disAgreeButton.layer.cornerRadius = 8
        }
    }
    
    
    weak var delegate: CoHostTableViewCellDelegate?
    
    var request: RoomRequest? {
        didSet {
            userNameLabel.text = ZegoSDKManager.shared.getUser(request?.senderID ?? "")?.name
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func agreeClick(_ sender: Any) {
        guard let request = request else { return }
        delegate?.agreeCoHostApply(request: request)
    }
    
    @IBAction func disAgreeClick(_ sender: Any) {
        guard let request = request else { return }
        delegate?.disAgreeCoHostApply(request: request)
    }
    
    
}
