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
    
    enum ButtonType: CaseIterable {
        case mic
        case camera
        case screenShare
        case option
        case hangUp
        
        var defaultStatus: Bool {
            switch self {
            case .mic:
                return true
            case .camera:
                return true
            case .screenShare, .option, .hangUp:
                return false
            }
        }
        
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
        
        func colorForStatus(_ status: Bool) -> UIColor? {
            switch self {
            case .mic, .camera, .screenShare:
                if status {
                    return UIColor(red: 33 / 255, green: 133 / 255, blue: 208 / 255, alpha: 1)
                } else {
                    return UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
                }
            case .option:
                return UIColor(red: 54 / 255, green: 48 / 255, blue: 55 / 255, alpha: 1)
            case .hangUp:
                return UIColor(red: 208 / 255, green: 25 / 255, blue: 25 / 255, alpha: 1)
            }
        }
        
        func imageForStatus(_ status: Bool) -> UIImage? {
            switch self {
            case .mic:
                return status ? UIImage(systemName: "mic.fill") : UIImage(systemName: "mic.slash.fill")
            case .camera:
                return status ? UIImage(systemName: "video.fill") : UIImage(systemName: "video.slash.fill")
            case .screenShare:
                return UIImage(systemName: "iphone")
            case .option:
                return UIImage(systemName: "ellipsis")
            case .hangUp:
                return UIImage(systemName: "phone.down.fill")
            }
        }
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 10
        
        for buttonType in ButtonType.allCases {
            let button = SMControlButton(type: .system)
            button.setup()
            
            button.setImage(buttonType.imageForStatus(buttonType.defaultStatus), for: .normal)
            button.addTarget(self, action: buttonType.action, for: .touchUpInside)
            button.backgroundColor = buttonType.colorForStatus(buttonType.defaultStatus)
            
            addArrangedSubview(button)
            buttons[buttonType] = button
        }
    }
    
    func micStatus(isEnabled: Bool) {
        changeStatusFor(.mic, to: isEnabled)
    }
    
    func cameraStatus(isEnabled: Bool) {
        changeStatusFor(.camera, to: isEnabled)
    }
    
    func screenShareStatus(isEnabled: Bool) {
        changeStatusFor(.screenShare, to: isEnabled)
    }
    
    private func changeStatusFor(_ buttonType: ButtonType, to status: Bool) {
        buttons[buttonType]?.setImage(buttonType.imageForStatus(status), for: .normal)
        buttons[buttonType]?.backgroundColor = buttonType.colorForStatus(status)
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
