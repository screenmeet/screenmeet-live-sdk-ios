//
//  SMFloatingVideoView.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 04.06.2021.
//

import UIKit
import ScreenMeetSDK
import WebRTC

class SMFloatingVideoView: UIView {
    
    private let smallVideoView: SMSmallVideoView = {
        let view = SMSmallVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var tapGesture: UITapGestureRecognizer!
    
    private var panGesture: UIPanGestureRecognizer!
    
    private var position: Position = .leftTop
    
    private var lastOrientation: UIDeviceOrientation!
    
    enum Position {
        case leftTop
        case leftBottom(width: CGFloat, height: CGFloat)
        case rightTop(width: CGFloat, height: CGFloat)
        case rightBottom(width: CGFloat, height: CGFloat)
        
        var point: CGPoint {
            guard let window = UIApplication.shared.windows.first else {
                return .zero
            }
            
            switch self {
            case .leftTop:
                return CGPoint(x: 10 + window.safeAreaInsets.left, y: 10 + window.safeAreaInsets.top)
            case .leftBottom(_, let height):
                return CGPoint(x: 10 + window.safeAreaInsets.left, y: window.bounds.height - 10 - window.safeAreaInsets.bottom - height)
            case .rightTop(let width, _):
                return CGPoint(x: window.bounds.width - 10 - window.safeAreaInsets.right - width, y: 10 + window.safeAreaInsets.top)
            case .rightBottom(let width, let height):
                return CGPoint(x: window.bounds.width - 10 - window.safeAreaInsets.right - width, y: window.bounds.height - 10 - window.safeAreaInsets.bottom - height)
            }
        }
        
        static func closestPosition(for frame: CGRect) -> Position {
            let screenSize = UIScreen.main.bounds
            let point = CGPoint(x: screenSize.width / 2 - frame.width / 2, y: screenSize.height / 2 - frame.height / 2)
            
            switch (frame.origin.x, frame.origin.y) {
            case (...point.x, ...point.y):
                return .leftTop
            case (point.x..<CGFloat.greatestFiniteMagnitude, ...point.y):
                return .rightTop(width: frame.width, height: frame.height)
            case (...point.x, point.y..<CGFloat.greatestFiniteMagnitude):
                return .leftBottom(width: frame.width, height: frame.height)
            case (point.x..<CGFloat.greatestFiniteMagnitude, point.y..<CGFloat.greatestFiniteMagnitude):
                return .rightBottom(width: frame.width, height: frame.height)
            default:
                return .leftTop
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lastOrientation = UIDevice.current.orientation
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(panGesture)
        self.frame = CGRect(x: position.point.x, y: position.point.y, width: frame.width, height: frame.height)
        
        addSubview(smallVideoView)
        
        NSLayoutConstraint.activate([
            smallVideoView.topAnchor.constraint(equalTo: topAnchor),
            smallVideoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            smallVideoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            smallVideoView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if lastOrientation != UIDevice.current.orientation {
            lastOrientation = UIDevice.current.orientation
            moveToPossition()
        }
    }
    
    private func moveToPossition() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [unowned self] in
            frame.origin = position.point
        }
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer?) {
        SMUserInterface.manager.presentScreenMeetUI()
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer?) {
        guard let window = UIApplication.shared.windows.first,
              let translation = sender?.translation(in: window),
              let velocity = sender?.velocity(in: window) else { return }
        
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        
        if sender?.state == .ended {
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            let slideMultiplier = magnitude / 1500
            let slideFactor = 0.1 * slideMultiplier
            
            let x = frame.origin.x + (velocity.x * slideFactor)
            let y = frame.origin.y + (velocity.y * slideFactor)
            
            position = Position.closestPosition(for: CGRect(origin: CGPoint(x: x, y: y), size: frame.size))
            moveToPossition()
        } else {
            sender?.setTranslation(CGPoint.zero, in: window)
        }
    }
}

extension SMFloatingVideoView {
    
    func update(with name: String?, audioState: Bool, videoState: Bool, videoTrack: RTCVideoTrack?) {
        smallVideoView.update(with: name, audioState: audioState, videoState: videoState, videoTrack: videoTrack, isFloating: true)
    }
}
