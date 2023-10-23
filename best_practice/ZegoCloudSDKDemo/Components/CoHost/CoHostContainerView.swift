//
//  CoHostContainerView.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/10/12.
//

import UIKit

class CoHostContainerView: UIView, ExpressServiceDelegate {
    
    var coHostModels: [CoHostViewModel] = [] {
        didSet {
            updateScrollerView()
        }
    }
    
    var videoViews: [VideoView] = []
    
    lazy var scrollerView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        ZegoSDKManager.shared.expressService.addEventHandler(self)
        self.addSubview(scrollerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateScrollerView() {
        videoViews.forEach { view in
            view.removeFromSuperview()
        }
        var y: CGFloat = 0.0
        for coHostModel in coHostModels {
            let view = VideoView(frame: CGRectMake(0, y, 93, 124.0))
            view.enableBorder(true)
            view.enableCamera(coHostModel.isCamerOn)
            view.update(coHostModel.user?.id, coHostModel.user?.name)
            videoViews.append(view)
            scrollerView.addSubview(view)
            if coHostModel.user?.id == ZegoSDKManager.shared.currentUser?.id {
                ZegoSDKManager.shared.expressService.stopPreview()
                ZegoSDKManager.shared.expressService.startPreview(view.renderView, viewMode: .aspectFill)
            } else {
                ZegoSDKManager.shared.expressService.startPlayingStream(view.renderView, streamID: coHostModel.streamID ?? "", viewMode: .aspectFill)
            }
            y = y + 124.0 + 5
        }
        scrollerView.contentSize = CGSizeMake(93, y)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollerView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }
    
    func cameraStateChange(_ userID: String, isOn: Bool) {
        for model in coHostModels {
            for view in videoViews {
                if view.userID == model.user?.id {
                    view.enableCamera(model.isCamerOn)
                }
            }
        }
    }

}

