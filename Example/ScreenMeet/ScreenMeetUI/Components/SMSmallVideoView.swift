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
    private weak var currentVideoTrack: RTCVideoTrack?
    private var stackView: UIStackView!
    
    #if arch(arm64)
        var rtcVideoView: RTCMTLVideoView = RTCMTLVideoView()
    #else
        var rtcVideoView: RTCEAGLVideoView = RTCEAGLVideoView()
    #endif
    
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
    
    var cameraImageView: UIImageView = {
        let image = UIImage(systemName: "video.slash.fill")
        
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
    
    private var rtcVideoViewAspectRatioConstraint: NSLayoutConstraint!
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        rtcVideoView.translatesAutoresizingMaskIntoConstraints = false
        rtcVideoView.delegate = self
        
        stackView = UIStackView()
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(rtcVideoView)
        addSubview(imageView)
        addSubview(stackView)
        addSubview(bottomView)
        bottomView.layer.insertSublayer(gradientLayer, at: 0)
        bottomView.addSubview(nameLabel)
        stackView.addArrangedSubview(micImageView)
        stackView.addArrangedSubview(cameraImageView)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: bottomView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
        ])
        
        rtcVideoViewAspectRatioConstraint = rtcVideoView.heightAnchor.constraint(equalTo: rtcVideoView.widthAnchor)
        
        NSLayoutConstraint.activate([
            rtcVideoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            rtcVideoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rtcVideoView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor),
            rtcVideoView.widthAnchor.constraint(greaterThanOrEqualTo: widthAnchor),
            rtcVideoViewAspectRatioConstraint,
            
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            
            micImageView.widthAnchor.constraint(equalToConstant: 12),
            micImageView.heightAnchor.constraint(equalTo: micImageView.widthAnchor),
            
            cameraImageView.widthAnchor.constraint(equalToConstant: 12),
            cameraImageView.heightAnchor.constraint(equalTo: cameraImageView.widthAnchor),
            
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
        
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = bottomView.bounds
    }
    
    func update(with participant: SMParticipant) {
        update(with: participant.name, audioState: participant.avState.audioState == .MICROPHONE, videoState: participant.avState.videoState != .NONE, videoTrack: participant.videoTrack)
    }
    
    func update(with name: String?, audioState: Bool, videoState: Bool, videoTrack: RTCVideoTrack?, isFloating: Bool = false) {
        if videoTrack != nil {
            currentVideoTrack?.remove(rtcVideoView)
            currentVideoTrack = videoTrack
            videoTrack?.add(rtcVideoView)
        }
        else {
            rtcVideoView.removeFromSuperview()
            currentVideoTrack?.remove(rtcVideoView)
            currentVideoTrack = nil
            
            createRenderingView()
        }
        
        nameLabel.text = name
        micImageView.isHidden = audioState
        imageView.isHidden = videoState
        rtcVideoView.isHidden = !videoState
        cameraImageView.isHidden = true
        layer.borderColor = audioState ? UIColor.white.cgColor : UIColor(red: 219 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1).cgColor
        
        if isFloating {
            let enabledColor = UIColor(red: 53 / 255, green: 169 / 255, blue: 235 / 255, alpha: 1)
            let disabledColor = UIColor(red: 219 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1)
            let mainParticipantVideoState = (SMUserInterface.manager.mainParticipant?.avState.videoState ?? .NONE) != .NONE
            imageView.isHidden = mainParticipantVideoState || videoState
            rtcVideoView.isHidden = !(mainParticipantVideoState || videoState)
            
            micImageView.isHidden = false
            micImageView.tintColor = audioState ? enabledColor : disabledColor
            micImageView.image = audioState ? UIImage(systemName: "mic.fill") : UIImage(systemName: "mic.slash.fill")
            
            cameraImageView.isHidden = false
            cameraImageView.tintColor = videoState ? enabledColor : disabledColor
            cameraImageView.image = videoState ? UIImage(systemName: "video.fill") : UIImage(systemName: "video.slash.fill")
            
            layer.borderColor = UIColor(red: 255 / 255, green: 166 / 255, blue: 99 / 255, alpha: 1).cgColor
        }
    }
    
    private func createRenderingView() {
        /* Recreate RTCVideoView as the previous one might contain some previous track frame*/
        rtcVideoView.removeFromSuperview()
        #if arch(arm64)
            rtcVideoView = RTCMTLVideoView()
        #else
            rtcVideoView = RTCEAGLVideoView()
        #endif
        rtcVideoView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(rtcVideoView)
        
        rtcVideoViewAspectRatioConstraint = rtcVideoView.heightAnchor.constraint(equalTo: rtcVideoView.widthAnchor)
        
        NSLayoutConstraint.activate([
            rtcVideoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            rtcVideoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rtcVideoView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor),
            rtcVideoView.widthAnchor.constraint(greaterThanOrEqualTo: widthAnchor),
            rtcVideoViewAspectRatioConstraint
        ])
        
        bringSubviewToFront(bottomView)
        bringSubviewToFront(stackView)
        
        #if arch(arm64)
            rtcVideoView.videoContentMode = .scaleAspectFill
        #endif
    }
}

extension SMSmallVideoView: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        
    }
    
}

