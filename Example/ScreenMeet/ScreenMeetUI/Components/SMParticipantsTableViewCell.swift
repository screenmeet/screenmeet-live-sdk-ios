//
//  SMParticipantsTableViewCell.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 10.03.2021.
//

import UIKit
import ScreenMeetSDK

class SMParticipantsTableViewCell: UITableViewCell {
    
    private let micImageView: UIImageView = {
        let image = UIImage(systemName: "mic.slash.fill")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let cameraImageView: UIImageView = {
        let image = UIImage(systemName: "video.slash.fill")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = label.font.withSize(14)
        return label
    }()
    
    private let starImageView: UIImageView = {
        let image = UIImage(systemName: "star.fill")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .orange
        imageView.isHidden = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        addSubview(micImageView)
        addSubview(cameraImageView)
        addSubview(nameLabel)
        addSubview(starImageView)
        
        NSLayoutConstraint.activate([
            micImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            micImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            micImageView.widthAnchor.constraint(equalToConstant: 20),
            micImageView.widthAnchor.constraint(equalTo: micImageView.heightAnchor),
            micImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            micImageView.trailingAnchor.constraint(equalTo: cameraImageView.leadingAnchor, constant: -10),
            
            cameraImageView.centerYAnchor.constraint(equalTo: micImageView.centerYAnchor),
            cameraImageView.widthAnchor.constraint(equalToConstant: 20),
            cameraImageView.widthAnchor.constraint(equalTo: cameraImageView.heightAnchor),
            cameraImageView.trailingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: -10),
            
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),

            starImageView.centerYAnchor.constraint(equalTo: micImageView.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 20),
            starImageView.widthAnchor.constraint(equalTo: starImageView.heightAnchor),
            starImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with participant: SMParticipant) {
        nameLabel.text = participant.name
        starImageView.isHidden = participant.role != .HOST
        
        if participant.callerState.audioEnabled {
            let image = UIImage(systemName: "mic.fill")
            micImageView.image = image
            micImageView.tintColor = UIColor(red: 33 / 255, green: 133 / 255, blue: 208 / 255, alpha: 1)
        } else {
            let image = UIImage(systemName: "mic.slash.fill")
            cameraImageView.image = image
            micImageView.tintColor = UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
        }
        
        if participant.callerState.videoEnabled {
            let image = UIImage(systemName: "video.fill")
            cameraImageView.image = image
            cameraImageView.tintColor = UIColor(red: 33 / 255, green: 133 / 255, blue: 208 / 255, alpha: 1)
        } else {
            let image = UIImage(systemName: "video.slash.fill")
            cameraImageView.image = image
            cameraImageView.tintColor = UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
        }
    }
    
    func setup(with name: String, audioState: Bool, videoState: Bool) {
        nameLabel.text = name
        
        if audioState {
            let image = UIImage(systemName: "mic.fill")
            micImageView.image = image
            micImageView.tintColor = UIColor(red: 33 / 255, green: 133 / 255, blue: 208 / 255, alpha: 1)
        } else {
            let image = UIImage(systemName: "mic.slash.fill")
            cameraImageView.image = image
            micImageView.tintColor = UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
        }
        
        if videoState {
            let image = UIImage(systemName: "video.fill")
            cameraImageView.image = image
            cameraImageView.tintColor = UIColor(red: 33 / 255, green: 133 / 255, blue: 208 / 255, alpha: 1)
        } else {
            let image = UIImage(systemName: "video.slash.fill")
            cameraImageView.image = image
            cameraImageView.tintColor = UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
        }
    }
}
