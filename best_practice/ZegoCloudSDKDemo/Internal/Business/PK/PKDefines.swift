//
//  PKDefines.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/7/6.
//

import Foundation
import ZIM

public enum PKProtocolType: UInt, Codable {
    // start pk
    case startPK = 91000
    // end pk
    case endPK = 91001
    // resume pk
    case resume = 91002
}

public enum RoomPKState {
    case isNoPK
    case isRequestPK
    case isStartPK
}

enum SEIType: UInt {
    case deviceState
}

class PKInfo: NSObject {
    
    var requestID: String = ""
    var pkUserList: [PKUser] = []
    
}

class PKUser: NSObject{
     
    var userID: String
    var userName: String = ""
    var roomID: String = ""
    
    var camera: Bool = false
    var microphone: Bool = false
    
    var callUserState: ZIMCallUserState = .unknown
    var isMute: Bool = false
    var extendedData: String = ""
    
    var edgeInsets: UIEdgeInsets = .zero
    
    var hasAccepted: Bool {
        get {
            return callUserState == .accepted
        }
    }
    
    var isWaiting: Bool {
        get {
            return callUserState == .received
        }
    }
    
    var pkUserStream: String {
        get {
            return roomID + "_" + userID + "_main" + "_host"
        }
    }
    
    init(userID: String) {
        self.userID = userID
    }
    
    func toString() -> String {
        var dict: [String: Any] = [:]
        dict["uid"] = userID
        dict["rid"] = roomID
        dict["u_name"] = userName
        var edgeInsetsDict: [String: Any] = [:]
        edgeInsetsDict["top"] = edgeInsets.top
        edgeInsetsDict["left"] = edgeInsets.left
        edgeInsetsDict["right"] = edgeInsets.right
        edgeInsetsDict["bottom"] = edgeInsets.bottom
        dict["rect"] = edgeInsetsDict
        return dict.jsonString
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["uid"] = userID
        dict["rid"] = roomID
        dict["u_name"] = userName
        var edgeInsetsDict: [String: Any] = [:]
        edgeInsetsDict["top"] = edgeInsets.top
        edgeInsetsDict["left"] = edgeInsets.left
        edgeInsetsDict["right"] = edgeInsets.right
        edgeInsetsDict["bottom"] = edgeInsets.bottom
        dict["rect"] = edgeInsetsDict
        return dict
    }
    
    static func parse(string: String) -> PKUser {
        let jsonMap: [String : Any] = string.toDict ?? [:]
        let uid: String = jsonMap["uid"] as? String ?? ""
        let rid: String = jsonMap["rid"] as? String ?? ""
        let u_name: String = jsonMap["u_name"] as? String ?? ""
        let rectJsonMap: [String: Any]? = jsonMap["rect"] as? Dictionary
        var userEdgeInset: UIEdgeInsets = .zero
        if let rectJsonMap = rectJsonMap {
            let top: CGFloat = rectJsonMap["top"] as! CGFloat
            let left: CGFloat = rectJsonMap["left"] as! CGFloat
            let right: CGFloat = rectJsonMap["right"] as! CGFloat
            let bottom: CGFloat = rectJsonMap["bottom"] as! CGFloat
            userEdgeInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        }
        let pkUser = PKUser(userID: uid)
        pkUser.userName = u_name
        pkUser.roomID = rid
        pkUser.edgeInsets = userEdgeInset
        return pkUser
    }
}

class PKExtendedData: NSObject {
    
    var roomID: String?
    var userName: String?
    var type: Int = 91000
    var userID: String = ""
    var autoAccept: Bool = false
    
    static let STARK_PK: Int = 91000
    
    static func parse(extendedData: String) -> PKExtendedData? {
        let dict: [String: Any]? = extendedData.toDict
        if let dict = dict {
            if dict.keys.contains("type") {
                let type: Int = dict["type"] as! Int
                if type == STARK_PK {
                    let data: PKExtendedData = PKExtendedData()
                    data.type = type
                    data.roomID = dict["room_id"] as? String
                    data.userName = dict["user_name"] as? String
                    if dict.keys.contains("user_id") {
                        data.userID = dict["user_id"] as! String
                    }
                    if dict.keys.contains("auto_accept") {
                        data.autoAccept = dict["auto_accept"] as! Bool
                    }
                    return data
                }
            }
        }
        return nil
    }
    
    func toString() -> String? {
        var dict: [String: Any] = [:]
        dict["room_id"] = roomID
        dict["user_name"] = userName
        dict["type"] = type
        if !userID.isEmpty
        {
            dict["user_id"] = userID
        }
        dict["auto_accept"] = autoAccept
        return dict.jsonString
    }
    
}
