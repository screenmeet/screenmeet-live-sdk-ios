//
//  SMControlBar.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 25.02.2021.
//

import UIKit

protocol SMControlBarDelegate {
    
    func micButtonTapped()
    
    func cameraButtonTapped()
    
    func screenShareButtonTapped()
    
    func optionButtonTapped()
    
    func hangUpButtonTapped()
}

class SMControlBar: UIStackView {
    
    private var buttons: [ButtonType: SMControlButton] = [:]
    
    var delegate: SMControlBarDelegate?
    
    private enum ButtonType: CaseIterable {
        case mic
        case camera
        case screenShare
        case option
        case hangUp
        
        var action: Selector {
            switch self {
            case .mic:
                return #selector(micButtonTapped)
            case .camera:
                return #selector(cameraButtonTapped)
            case .screenShare:
                return #selector(screenShareButtonTapped)
            case .option:
                return #selector(optionButtonTapped)
            case .hangUp:
                return #selector(hangUpButtonTapped)
            }
        }
        
        func colorForStatus(_ status: ButtonStatus) -> UIColor? {
            switch self {
            case .mic, .camera, .screenShare:
                switch status {
                case .enabled:
                    return UIColor(red: 53 / 255, green: 169 / 255, blue: 235 / 255, alpha: 1)
                case .disabled, .unavailable:
                    return UIColor(red: 122 / 255, green: 122 / 255, blue: 122 / 255, alpha: 1)
                }
            case .option:
                return UIColor(red: 122 / 255, green: 122 / 255, blue: 122 / 255, alpha: 1)
            case .hangUp:
                return UIColor(red: 215 / 255, green: 57 / 255, blue: 48 / 255, alpha: 1)
            }
        }
        
        func imageForStatus(_ status: ButtonStatus) -> UIImage? {
            let enabled: Bool
            switch status {
            case .enabled:
                enabled = true
            case .disabled, .unavailable:
                enabled = false
            }
            
            switch self {
            case .mic:
                return enabled ? UIImage(systemName: "mic.fill") : UIImage(systemName: "mic.slash.fill")
            case .camera:
                return enabled ? UIImage(systemName: "video.fill") : UIImage(systemName: "video.slash.fill")
            case .screenShare:
                return enabled ? UIImage(systemName: "iphone.badge.play") : UIImage(systemName: "iphone")
            case .option:
                return UIImage(systemName: "ellipsis")
            case .hangUp:
                return UIImage(systemName: "phone.down.fill")
            }
        }
    }
    
    enum ButtonStatus {
        case enabled
        case disabled
        case unavailable
    }
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 10
        
        for buttonType in ButtonType.allCases {
            let button = SMControlButton()
            
            button.setImage(buttonType.imageForStatus(.disabled), for: .normal)
            button.addTarget(self, action: buttonType.action, for: .touchUpInside)
            button.backgroundColor = buttonType.colorForStatus(.disabled)
            
            addArrangedSubview(button)
            buttons[buttonType] = button
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func micStatus(_ status: ButtonStatus) {
        changeStatusFor(.mic, to: status)
    }
    
    func cameraStatus(_ status: ButtonStatus) {
        changeStatusFor(.camera, to: status)
    }
    
    func screenShareStatus(_ status: ButtonStatus) {
        changeStatusFor(.screenShare, to: status)
    }
    
    func optionButtonBadgeCount(_ count: Int) {
        let color = UIColor(red: 136 / 255, green: 217 / 255, blue: 215 / 255, alpha: 1)
        if count <= 0 {
            buttons[.option]?.setBadgeImage(nil)
        } else if count <= 50 {
            buttons[.option]?.setBadgeImage(UIImage(systemName: "\(count).square.fill"), color: color, backgroundColor: .white)
        } else {
            buttons[.option]?.setBadgeImage(UIImage(systemName: "dot.square.fill"), color: color, backgroundColor: .white)
        }
    }
    
    private func changeStatusFor(_ buttonType: ButtonType, to status: ButtonStatus) {
        buttons[buttonType]?.setImage(buttonType.imageForStatus(status), for: .normal)
        buttons[buttonType]?.backgroundColor = buttonType.colorForStatus(status)
        
        if status == .unavailable {
            buttons[buttonType]?.setBadgeImage(UIImage(systemName: "exclamationmark.triangle.fill"), color: .red)
        } else {
            buttons[buttonType]?.setBadgeImage(nil)
        }
    }
    
    @IBAction private func micButtonTapped() {
        delegate?.micButtonTapped()
    }
    
    @IBAction private func cameraButtonTapped() {
        delegate?.cameraButtonTapped()
    }
    
    @IBAction private func screenShareButtonTapped() {
        delegate?.screenShareButtonTapped()
    }
    
    @IBAction private func optionButtonTapped() {
        delegate?.optionButtonTapped()
    }
    
    @IBAction private func hangUpButtonTapped() {
        delegate?.hangUpButtonTapped()
    }
}
