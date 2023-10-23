//
//  RoomSeatService.swift
//  ZegoLiveStreamingPkbattlesDemo
//
//  Created by zego on 2023/7/10.
//

import UIKit
import ZIM
import ZegoExpressEngine

@objc protocol RoomSeatServiceDelegate: AnyObject {
    @objc optional func onSeatChanged(_ seatList: [ZegoLiveAudioRoomSeat])
}

class RoomSeatService: NSObject {
    
    let eventDelegates: NSHashTable<RoomSeatServiceDelegate> = NSHashTable(options: .weakMemory)
    
    var seatList: [ZegoLiveAudioRoomSeat] = []
    var batchOperation: Bool = false
    var hostSeatIndex: Int = 0 {
        didSet {
            for seat in seatList {
                if seat.seatIndex == hostSeatIndex {
                    seat.currentUser = ZegoLiveAudioRoomManager.shared.getHostUser()
                }
            }
        }
    }
    
    func addSeatServiceEventHandler(_ eventHandler: RoomSeatServiceDelegate) {
        eventDelegates.add(eventHandler)
    }
    
    func initWithConfig(_ layoutConfig: ZegoLiveAudioRoomLayoutConfig) {
        seatList.removeAll()
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        ZegoSDKManager.shared.zimService.addEventHandler(self)
        
        initSeat(layoutConfig)
    }
    
    func initSeat(_ layoutConfig: ZegoLiveAudioRoomLayoutConfig) {
        for columIndex in 0..<layoutConfig.rowConfigs.count {
            let rowConfig = layoutConfig.rowConfigs[columIndex]
            for rowIndex in 0..<rowConfig.count {
                let roomSeat = ZegoLiveAudioRoomSeat()
                roomSeat.columnIndex = columIndex
                roomSeat.rowIndex = rowIndex
                roomSeat.seatIndex = seatList.count
                seatList.append(roomSeat)
            }
        }
    }
    
    func tryTakeSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        ZegoSDKManager.shared.zimService.setRoomAttributes("\(seatIndex)", value: localUser.id) { roomID, errorKeys, errorInfo in
            if errorInfo.code == .success && !errorKeys.contains("\(seatIndex)") {
                for seat in self.seatList {
                    if seat.seatIndex == seatIndex {
                        seat.currentUser = localUser
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        }
    }
    
    func takeSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        guard let localUser = ZegoSDKManager.shared.currentUser else { return }
        ZegoSDKManager.shared.zimService.setRoomAttributes("\(seatIndex)", value: localUser.id) { roomID, errorKeys, errorInfo in
            if errorInfo.code == .success && !errorKeys.contains("\(seatIndex)") {
                for seat in self.seatList {
                    if seat.seatIndex == seatIndex {
                        seat.currentUser = localUser
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        }
    }

    
    func switchSeat(fromSeatIndex: Int, toSeatIndex: Int, callback: ZIMRoomAttributesBatchOperatedCallback?) {
        if !batchOperation {
            ZegoSDKManager.shared.zimService.beginRoomPropertiesBatchOperation()
            batchOperation = true
            tryTakeSeat(seatIndex: toSeatIndex, callback: nil)
            leaveSeat(seatIndex: fromSeatIndex, callback: nil)
            ZegoSDKManager.shared.zimService.endRoomPropertiesBatchOperation { roomID, errorInfo in
                self.batchOperation = false
                guard let callback = callback else { return }
                callback(roomID, errorInfo)
            }
        }
    }
    
    func leaveSeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        ZegoSDKManager.shared.zimService.deletedRoomAttributes(["\(seatIndex)"]) { roomID, errorKeys, errorInfo in
            if errorInfo.code == .success && !errorKeys.contains("\(seatIndex)") {
                for seat in self.seatList {
                    if seat.seatIndex == seatIndex {
                        seat.currentUser = nil
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        }
    }
    
    func emptySeat(seatIndex: Int, callback: ZIMRoomAttributesOperatedCallback?) {
        ZegoSDKManager.shared.zimService.deletedRoomAttributes(["\(seatIndex)"], isForce: true) { roomID, errorKeys, errorInfo in
            if errorInfo.code == .success && !errorKeys.contains("\(seatIndex)") {
                for seat in self.seatList {
                    if seat.seatIndex == seatIndex {
                        seat.currentUser = nil
                    }
                }
            }
            guard let callback = callback else { return }
            callback(roomID,errorKeys,errorInfo)
        }
    }
    
    func removeRoomData() {
        batchOperation = false
        seatList.removeAll()
        hostSeatIndex = 0
    }
    
}

extension RoomSeatService: ExpressServiceDelegate {
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for user in userList {
            if updateType == .delete {
                var changeSeatList: [ZegoLiveAudioRoomSeat] = []
                for seat in seatList {
                    if seat.currentUser?.id == user.userID {
                        seat.currentUser = nil
                        changeSeatList.append(seat)
                    }
                }
                if changeSeatList.count > 0 {
                    for delegate in eventDelegates.allObjects {
                        delegate.onSeatChanged?(changeSeatList)
                    }
                }
            } else {
                var changeSeatList: [ZegoLiveAudioRoomSeat] = []
                for seat in seatList {
                    if seat.currentUser?.id == user.userID && seat.currentUser?.name != user.userName {
                        seat.currentUser?.name = user.userName
                        changeSeatList.append(seat)
                    }
                }
                if changeSeatList.count > 0 {
                    for delegate in eventDelegates.allObjects {
                        delegate.onSeatChanged?(changeSeatList)
                    }
                }
            }
        }
    }
}

extension RoomSeatService: ZIMServiceDelegate {
    
    func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
        var changeSeatList: [ZegoLiveAudioRoomSeat] = []
        if updateInfo.action == .set {
            for (key,value) in updateInfo.roomAttributes {
                for seat in seatList {
                    if String(seat.seatIndex) == key {
                        if value == ZegoSDKManager.shared.currentUser?.id {
                            seat.currentUser = ZegoSDKManager.shared.currentUser
                        } else {
                            seat.currentUser = ZegoSDKManager.shared.getUser(value) ?? ZegoSDKUser(id: value, name: "")
                        }
                        changeSeatList.append(seat)
                    }
                }
            }
        } else {
            for (key,_) in updateInfo.roomAttributes {
                for seat in seatList {
                    if String(seat.seatIndex) == key {
                        seat.currentUser = nil
                        changeSeatList.append(seat)
                    }
                }
            }
        }
        
        for delegate in eventDelegates.allObjects {
            delegate.onSeatChanged?(changeSeatList)
        }
    }
    
    func zim(_ zim: ZIM, roomAttributesBatchUpdated updateInfo: [ZIMRoomAttributesUpdateInfo], roomID: String) {
        var changeSeatList: [ZegoLiveAudioRoomSeat] = []
        for info in updateInfo {
            if info.action == .set {
                for (key,value) in info.roomAttributes {
                    for seat in seatList {
                        if String(seat.seatIndex) == key {
                            if value == ZegoSDKManager.shared.currentUser?.id {
                                seat.currentUser = ZegoSDKManager.shared.currentUser
                            } else {
                                seat.currentUser = ZegoSDKManager.shared.getUser(value) ?? ZegoSDKUser(id: value, name: "")
                            }
                            changeSeatList.append(seat)
                        }
                    }
                }
            } else {
                for (key,_) in info.roomAttributes {
                    for seat in seatList {
                        if String(seat.seatIndex) == key {
                            seat.currentUser = nil
                            changeSeatList.append(seat)
                        }
                    }
                }
            }
        }
        for delegate in eventDelegates.allObjects {
            delegate.onSeatChanged?(changeSeatList)
        }
    }
    
}
