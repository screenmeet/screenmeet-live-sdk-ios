//
//  SMSmallVideoView.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 10.03.2021.
//

import UIKit
import WebRTC
import ScreenMeetSDK

class SMSmallVideoView: UIView {
    
    var rtcVideoView: RTCEAGLVideoView = {
        let rtcVideoView = RTCEAGLVideoView()
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
        label.font = label.font.withSize(12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(rtcVideoView)
        addSubview(imageView)
        addSubview(micImageView)
        addSubview(bottomView)
        bottomView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: bottomView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            rtcVideoView.topAnchor.constraint(equalTo: topAnchor),
            rtcVideoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rtcVideoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rtcVideoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            micImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            micImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            micImageView.widthAnchor.constraint(equalToConstant: 12),
            micImageView.heightAnchor.constraint(equalTo: micImageView.widthAnchor),
            
            bottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        backgroundColor = .black
        clipsToBounds = true
        layer.cornerRadius = 3
        layer.borderWidth = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = bottomView.bounds

        bottomView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func update(with participant: SMParticipant) {
        update(with: participant.name, audioState: participant.avState.audioState == .MICROPHONE, videoState: participant.avState.videoState == .CAMERA, videoTrack: participant.videoTrack)
    }
    
    func update(with name: String?, audioState: Bool, videoState: Bool, videoTrack: RTCVideoTrack?) {
        videoTrack?.add(rtcVideoView)
        nameLabel.text = name
        micImageView.isHidden = audioState
        imageView.isHidden = videoState
        rtcVideoView.isHidden = !videoState
        layer.borderColor = audioState ? UIColor.white.cgColor : UIColor(red: 219 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1).cgColor
    }
}
