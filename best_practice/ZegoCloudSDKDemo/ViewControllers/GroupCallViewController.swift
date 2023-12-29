//
//  GroupCallViewController.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/12/14.
//

import UIKit
import ZegoExpressEngine

class GroupCallViewController: UIViewController {
    
    var userViews: [GroupCallUserView] = []
    var callUserList: [CallUserInfo] = []

    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updateUserList()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupUserViewFrame()
    }
    
    func updateCallUserList(_ userList: [CallUserInfo]) {
        callUserList = userList
        updateUserList()
    }
    
    func updateUserList() {
        var needAddView: [GroupCallUserView] = []
        var needRemoveView: [GroupCallUserView] = []
        for user in callUserList {
            if let cacheView = getCacheView(userID: user.userID ?? "") {
                cacheView.callUserInfo = user
                needAddView.append(cacheView)
            } else {
                let view = GroupCallUserView()
                view.callUserInfo = user
                needAddView.append(view)
            }
        }
        needAddView.forEach { view in
            self.containerView.addSubview(view)
        }
        userViews.forEach { view in
            var isNeedDelected: Bool = true
            for addView in needAddView {
                if addView.callUserInfo?.userID == view.callUserInfo?.userID {
                    isNeedDelected = false
                    break
                }
            }
            if isNeedDelected {
                needRemoveView.append(view)
            }
        }
        needRemoveView.forEach { view in
            view.removeFromSuperview()
        }
        userViews = needAddView
        setupUserViewFrame()
    }
    
    func getCacheView(userID: String) -> GroupCallUserView?{
        for view in userViews {
            if view.callUserInfo?.userID == userID {
                return view
            }
        }
        return nil
    }
    
    func setupUserViewFrame() {
        let containerViewWidth = containerView.bounds.width
        let containerViewHeight = containerView.bounds.height
        if (userViews.count == 3) {
            for i in 0...(userViews.count - 1) {
                let left = i == 0 ? 0 : containerViewWidth / 2;
                let top = i == 2 ? containerViewHeight / 2 : 0;
                let width: CGFloat = containerViewWidth / 2
                let height: CGFloat = i == 0 ? containerViewHeight : containerViewHeight / 2
                let rect = CGRect(origin: CGPointMake(left, top), size: CGSizeMake(width, height))
                let view = userViews[i]
                view.frame = rect
            }
          } else if (userViews.count == 4) {
              let row: Int = 2
              let column: Int = 2
              let cellWidth: CGFloat = containerViewWidth / CGFloat(column)
              let cellHeight: CGFloat = containerViewHeight / CGFloat(row)
              var left: CGFloat
              var top: CGFloat
              for i in 0...(userViews.count - 1) {
                left = cellWidth * CGFloat((i % column))
                top = cellHeight * CGFloat((i < column ? 0 : 1))
                let rect = CGRect(origin: CGPointMake(left, top), size: CGSizeMake(cellWidth, cellHeight))
                let view = userViews[i]
                view.frame = rect
            }
          } else if (userViews.count == 5) {
              var lastLeft: CGFloat = 0
              var height: CGFloat = containerViewHeight / 2
              for i in 0...(userViews.count - 1) {
                  if (i == 2) {
                      lastLeft = 0
                  }
                  let width: CGFloat = i < 2 ? containerViewWidth / 2 : containerViewWidth / 3
                  let left: CGFloat = lastLeft + (width * CGFloat((i < 2 ? i : (i - 2))))
                  let top: CGFloat = i > 1 ? height : 0
                  let rect = CGRect(x: left, y: top, width: width, height: height)
                  let view = userViews[i]
                  view.frame = rect
              }
          } else if (userViews.count > 5) {
              let row: Int = userViews.count % 3 == 0 ? (userViews.count / 3) : (userViews.count / 3) + 1;
              let column: Int = 3
              let cellWidth: CGFloat = containerViewWidth / CGFloat(column)
              let cellHeight: CGFloat = containerViewHeight / CGFloat(row)
              var left: CGFloat
              var top: CGFloat
              for i in 0...(userViews.count - 1) {
                  left = cellWidth * (CGFloat)(i % column)
                  top = cellHeight * (CGFloat)(i / column)
                  let rect = CGRect(x: left, y: top, width: cellWidth, height: cellHeight)
                  let view = userViews[i]
                  view.frame = rect
              }
          }
    }

}

class GroupCallUserView: UIView {
    
    lazy var videoView: VideoView = {
        let view = VideoView()
        return view
    }()
    
    lazy var waitingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.isHidden = true
        view.addSubview(self.waitingLabel)
        return view
    }()
    
    lazy var waitingLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.text = "waiting..."
        label.textAlignment = .center
        return label
    }()
    
    var callUserInfo: CallUserInfo? {
        didSet {
            waitingView.isHidden = !(callUserInfo?.isWaiting ?? false)
            waitingLabel.isHidden = !(callUserInfo?.isWaiting ?? false)
            videoView.userID = callUserInfo?.userID
            videoView.setAvatar(callUserInfo?.headUrl ?? "")
            videoView.setNameLabel(callUserInfo?.userName)
            if callUserInfo?.userID == ZegoSDKManager.shared.currentUser?.id {
                ZegoSDKManager.shared.expressService.startPreview(videoView.renderView)
            } else {
                ZegoSDKManager.shared.expressService.startPlayingStream(videoView.renderView, streamID: callUserInfo?.streamID ?? "")
            }
            if ZegoCallManager.shared.currentCallData?.type == .voice {
                videoView.enableCamera(false)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(videoView)
        self.addSubview(waitingView)
        ZegoSDKManager.shared.expressService.addEventHandler(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        videoView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        waitingView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        waitingLabel.frame = CGRect(x: 0, y: (bounds.height / 2) - 10, width: bounds.width, height: 20)
    }
}

extension GroupCallUserView: ExpressServiceDelegate {
    
    func onCameraOpen(_ userID: String, isCameraOpen: Bool) {
        if userID == callUserInfo?.userID {
            videoView.enableCamera(isCameraOpen)
        }
    }
}
