//
//  VideoView.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/4.
//

import UIKit

public class VideoView: UIView {
    public lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .init(red: 74/255.0, green: 75/255.0, blue: 77/255.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public lazy var renderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var headImageView: UIImageView = {
        let headImage = UIImageView()
        headImage.backgroundColor = UIColor.white
        headImage.translatesAutoresizingMaskIntoConstraints = false
        headImage.layer.cornerRadius = 40
        headImage.layer.masksToBounds = true
        headImage.isHidden = true
        return headImage
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
    
    public var userID: String?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        initData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initData()
    }
    
    private func initData() {
        addSubview(backgroundView)
        addSubview(nameHeadLabel)
        addSubview(headImageView)
        addSubview(renderView)
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            renderView.topAnchor.constraint(equalTo: topAnchor),
            renderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            renderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            renderView.trailingAnchor.constraint(equalTo: trailingAnchor),
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
        
        NSLayoutConstraint.activate([
            headImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            headImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            headImageView.widthAnchor.constraint(equalToConstant: 80),
            headImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Public
    public func update(_ userID: String?, _ userName: String?) {
        self.userID = userID
        setNameLabel(userName)
    }
    
    public func setNameLabel(_ name: String?) {
        nameLabel.text = name
        nameLabel.isHidden = false
        nameLabelWidthConstraint.constant = nameLabel.intrinsicContentSize.width + 15
        
        if let name = name,
           name.count > 0
        {
            nameHeadLabel.text = String(name[name.startIndex])
        }
    }
    
    public func setAvatar(_ url: String) {
        if let avatarUrl = URL(string: url) {
            headImageView.downloadedFrom(url: avatarUrl)
            headImageView.isHidden = false
        }
    }
    
    public func enableCamera(_ enable: Bool) {
        renderView.isHidden = !enable
        nameHeadLabel.isHidden = enable
    }
    
    public func enableBorder(_ enable: Bool) {
        if enable {
            layer.borderColor = UIColor.gray.cgColor
            layer.borderWidth = 1.0
        } else {
            layer.borderWidth = 0.0
        }
    }
}
