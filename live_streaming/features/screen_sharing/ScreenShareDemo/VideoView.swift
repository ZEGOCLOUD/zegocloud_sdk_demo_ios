//
//  VideoView.swift
//  ScreenShareDemo
//
//  Created by Kael Ding on 2023/5/19.
//

import UIKit

public class VideoView: UIView {
    
    public lazy var renderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configUI()
    }
    
    func configUI() {
        
        backgroundColor = .init(red: 74/255.0, green: 75/255.0, blue: 77/255.0, alpha: 1.0)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.gray.cgColor
        
        addSubview(renderView)
        NSLayoutConstraint.activate([
            renderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            renderView.topAnchor.constraint(equalTo: topAnchor),
            renderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
