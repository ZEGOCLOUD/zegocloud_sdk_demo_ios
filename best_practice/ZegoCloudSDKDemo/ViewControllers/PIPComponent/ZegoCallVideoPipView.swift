//
//  ZegoCallPipView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2025/01/06.
//

import UIKit
import AVFoundation
import AVKit
import ZegoExpressEngine

protocol ZegopipRenderDelegate: AnyObject {
    func stopPip()
}

class ZegoCallVideoPipView: ZegoCallPipView {
    
    public weak var delegate: ZegopipRenderDelegate?
    var isEnablePreview: Bool = false {
        didSet {
            previewView.isHidden = !isEnablePreview
        }
    }
    
    lazy var backgroundView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
        return view
    }()
    
    lazy var displayView: ZegoVideoRenderView = {
        let view = ZegoVideoRenderView()
        return view
    }()
    
    lazy var previewView: ZegoVideoRenderView = {
        let view = ZegoVideoRenderView()
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = AVPictureInPictureController.pictureInPictureButtonStopImage
        button.setBackgroundImage(UIImage(named: "nav_close"), for: .normal)
        button.addTarget(self, action: #selector(onClickClosePip), for: .touchUpInside)
        return button
    }()
    
    var isPKStart: Bool = false
    var mixStream: Bool = false
    init(frame: CGRect,isPKStart:Bool) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
        self.isPKStart = isPKStart
        ExpressService.shared.addEventHandler(self)
        addSubview(backgroundView)
        addSubview(displayView)
        // 目前只支持观众pip
//        addSubview(previewView)
//        addSubview(closeButton)
//        bringSubviewToFront(closeButton)

        getUsers()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        backgroundView.frame = bounds
        displayView.frame = bounds
//        previewView.frame = CGRect(x: Int(bounds.size.width * 0.6), y: 10, width: Int(bounds.size.width * 0.4), height: Int((bounds.size.width * 0.4)) * 16 / 9)
//        closeButton.frame = CGRectMake(20, 20, 30, 30)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }
    
    func getUsers() {
        var mainHostUser:ZegoSDKUser?
        var coHostUser:ZegoSDKUser?
        let streamDict:[String:String] = ZegoSDKManager.shared.expressService.streamDict
        let roomUsersDict:[String:ZegoSDKUser] = ZegoSDKManager.shared.expressService.inRoomUserDict
        var pkStreamsDict = [String:String]()

        if isPKStart == true {
            if ZegoLiveStreamingManager.shared.isHost(userID: ZegoSDKManager.shared.currentUser?.id ?? "") == true {
                // 自己是主播
                self.mixStream = false
                guard let pkInfo = ZegoLiveStreamingManager.shared.pkInfo else { return }
                for pkUser in pkInfo.pkUserList {
                    if pkUser.hasAccepted {
                        if pkUser.userID == ZegoSDKManager.shared.currentUser?.id {
                            
                        } else {
                            pkStreamsDict[pkUser.pkUserStream] = pkUser.userID
                        }
                    }
                }
            } else {
                // 观众
                self.mixStream = true
            }
        }
        for (_,userID) in streamDict {
            if userID == ZegoSDKManager.shared.expressService.currentUser?.id ?? "" {
                previewView.relevanceUser = ZegoSDKManager.shared.expressService.currentUser
            } else {
                for (_,sdkUser) in roomUsersDict {
                    
                    if mainHostUser == nil {
                        if let isMainHost = sdkUser.streamID?.hasSuffix("_main_host"), isMainHost {
                            mainHostUser = sdkUser as ZegoSDKUser
                        }
                    }
                    
                    if coHostUser == nil && mainHostUser == nil {
                        if ((sdkUser.streamID?.hasSuffix("_main_cohost")) != nil) {
//                            coHostUser = sdkUser as ZegoSDKUser
                        }
                    }
                }
            }
        }
        
        if self.mixStream == true {
            let user = ZegoSDKUser(id: "", name: "")
            user.streamID = "_mix"
            displayView.relevanceUser = user
        } else {
            if mainHostUser != nil {
                displayView.relevanceUser = mainHostUser! as ZegoSDKUser
            } else if coHostUser != nil{
                displayView.relevanceUser = coHostUser! as ZegoSDKUser
            } else {
                if pkStreamsDict.isEmpty == true {
                    let user = ZegoSDKUser(id: "", name: "")
                    user.streamID = "_mix"
                    displayView.relevanceUser = user
                } else {
                    if let firstElement = pkStreamsDict.first {
                        let (steamid, userid) = firstElement
                        print("First key: \(steamid), value: \(userid)")
                        let user = ZegoSDKUser(id: userid, name: "")
                        user.streamID = steamid
                        displayView.relevanceUser = user

                    }
                }
            }
        }
        
    }
    
    @objc func onClickClosePip() {
        if #available(iOS 15.0, *) {
            delegate?.stopPip()
        }
    }
    
    override func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        DispatchQueue.main.async {
            if self.displayView.relevanceUser?.streamID == streamID {
                self.displayView.onRemoteVideoFrameCVPixelBuffer(buffer, param: param, streamID: streamID)
            } else if streamID.hasSuffix("_mix") {
                self.displayView.onRemoteVideoFrameCVPixelBuffer(buffer, param: param, streamID: streamID)
            }
        }
    }
    
    override func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        DispatchQueue.main.async {
            self.previewView.onCapturedVideoFrameCVPixelBuffer(buffer, param: param, flipMode: flipMode, channel: channel)
        }
        
    }
    
    override func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        self.previewView.onRemoteSoundLevelUpdate(soundLevels)
    }
    
    override func updateCurrentPIPStreamID(streamID: String) {
        if streamID.count > 0 {
            self.displayView.relevanceUser?.streamID = streamID
        }
    }
}

extension ZegoCallVideoPipView: ExpressServiceDelegate {
    
    private func onCameraOpen(_ user: ZegoSDKUser, isCameraOpen: Bool) {
        if user.id == ZegoSDKManager.shared.expressService.currentUser!.id {
            previewView.onCameraOn(user, isOn: isCameraOpen)
        } else {
            displayView.onCameraOn(user, isOn: isCameraOpen)
        }
    }
}

class ZegoVideoRenderView: UIView {
    
    var displayLayer: AVSampleBufferDisplayLayer?
    var relevanceUser: ZegoSDKUser? {
        didSet {
            if relevanceUser?.id == ZegoSDKManager.shared.expressService.currentUser?.id ?? "" {
                backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
            } else {
                backgroundColor = UIColor(hex: "#000000", alpha: 0.1)
            }
            headView.text = relevanceUser?.name
            headView.isHidden = relevanceUser?.isCameraOpen ?? true
        }
    }
    
    lazy var displayView: UIView = {
        let view = UIView()
        displayLayer = AVSampleBufferDisplayLayer()
        displayLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(displayLayer!)
        return view
    }()
    
    lazy var headView: ZegoPipHeadView = {
        let view = ZegoPipHeadView()
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headView)
        addSubview(displayView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayView.frame = bounds
        displayLayer?.frame = displayView.bounds
        let headW: CGFloat = 0.4 * bounds.width
        let headH: CGFloat = 0.4 * bounds.width
        headView.frame = CGRect(x: (bounds.width - headW) / 2, y: (bounds.height - headH) * 0.5, width: headW, height: headH)
    }
    
    func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        let sampleBuffer: CMSampleBuffer? = createSampleBuffer(pixelBuffer: buffer)
        if let sampleBuffer = sampleBuffer {
            self.displayLayer?.enqueue(sampleBuffer)
            if self.displayLayer?.status == .failed {
                
            }
        }
    }
    
    func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        let sampleBuffer: CMSampleBuffer? = createSampleBuffer(pixelBuffer: buffer)
        if let sampleBuffer = sampleBuffer {
            self.displayLayer?.enqueue(sampleBuffer)
        }
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        
    }

    
    func createSampleBuffer(pixelBuffer: CVPixelBuffer?) -> CMSampleBuffer? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        
        // Do not set specific time info
        var timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.invalid, decodeTimeStamp: CMTime.invalid)
        
        // Get video info
        var videoInfo: CMVideoFormatDescription? = nil
        let result = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
        guard result == noErr, let videoInfo = videoInfo else {
            assertionFailure("Error occurred: \(result)")
            return nil
        }
        
        var sampleBuffer: CMSampleBuffer? = nil
        let sampleBufferResult = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoInfo, sampleTiming: &timing, sampleBufferOut: &sampleBuffer)
        
        guard sampleBufferResult == noErr, let sampleBuffer = sampleBuffer else {
            assertionFailure("Error occurred: \(sampleBufferResult)")
            return nil
        }
        
        // Attachments settings
        let attachments: CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
        let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(dict, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        
        return sampleBuffer
    }
    
    func onCameraOn(_ user: ZegoSDKUser, isOn: Bool) {
        if user.id == relevanceUser?.id {
            displayView.isHidden = !isOn
            headView.isHidden = isOn
        }
    }
    
}

class ZegoPipHeadView: UIView {
    
    var font: UIFont? {
        didSet {
            guard let font = font else { return }
            self.headLabel.font = font
        }
    }
    
    var text: String? {
        didSet {
            guard let text = text else { return }
            if text.count > 0 {
                let firstStr: String = String(text[text.startIndex])
                self.headLabel.text = firstStr
            }
        }
    }
    
    var lastUrl: String?
    
    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.colorWithHexString("#222222")
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        return label
    }()
    
    lazy var headImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.headLabel)
        self.addSubview(self.headImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.headLabel.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.headLabel.layer.masksToBounds = true
        self.headLabel.layer.cornerRadius = self.frame.size.width * 0.5
        self.headImageView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.headImageView.layer.masksToBounds = true
        self.headImageView.layer.cornerRadius = self.frame.size.width * 0.5
    }
    
    func setHeadLabelText(_ text: String) {
        self.headLabel.text = text
    }
}
