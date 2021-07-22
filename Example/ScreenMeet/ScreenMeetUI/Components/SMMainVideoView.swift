//
//  SMMainVideoView.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 11.03.2021.
//

import UIKit
import WebRTC
import ScreenMeetSDK

class SMMainVideoView: UIView {
    
    private weak var currentVideoVideTrack: RTCVideoTrack?
    
    var rtcVideoView: RTCMTLVideoView = {
        let rtcVideoView = RTCMTLVideoView()
        rtcVideoView.translatesAutoresizingMaskIntoConstraints = false
        return rtcVideoView
    }()
    
    var imageView: UIImageView = {
        let image = UIImage(named: "sm_logo.png")
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    var micImageView: UIImageView = {
        let image = UIImage(systemName: "mic.slash.fill")
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 219 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Me"
        label.textColor = .white
        label.font = label.font.withSize(14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var rtcVideoViewAspectRatioConstraint: NSLayoutConstraint!
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        topView.layer.insertSublayer(gradientLayer, at: 0)
        topView.addSubview(micImageView)
        topView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            micImageView.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
            micImageView.widthAnchor.constraint(equalToConstant: 14),
            micImageView.heightAnchor.constraint(equalTo: micImageView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: topView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: micImageView.trailingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: topView.trailingAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: topView.centerXAnchor, constant: 8)
        ])
        
        addSubview(rtcVideoView)
        addSubview(imageView)
        addSubview(topView)
        
        rtcVideoViewAspectRatioConstraint = rtcVideoView.heightAnchor.constraint(equalTo: rtcVideoView.widthAnchor)
        
        NSLayoutConstraint.activate([
            rtcVideoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            rtcVideoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rtcVideoView.widthAnchor.constraint(equalTo: widthAnchor),
            rtcVideoViewAspectRatioConstraint,
            
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 50),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            
            topView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            topView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = topView.bounds
    }
    
    func update(with participant: SMParticipant) {
        update(with: participant.name, audioState: participant.avState.audioState == .MICROPHONE, videoState: participant.avState.videoState == .CAMERA, videoTrack: participant.videoTrack)
    }
    
    func update(with name: String?, audioState: Bool, videoState: Bool, videoTrack: RTCVideoTrack?) {
        
        #if arch(arm64)
            NSLog("ARM64")
        #else
            NSLog("Not ARM64")
        #endif
        currentVideoVideTrack?.remove(rtcVideoView)
        currentVideoVideTrack = videoTrack
        
        rtcVideoView.contentMode = .scaleAspectFit
        videoTrack?.add(rtcVideoView)
        
        nameLabel.text = name
        micImageView.isHidden = audioState
        imageView.isHidden = videoState
        rtcVideoView.isHidden = !videoState
    }
}
