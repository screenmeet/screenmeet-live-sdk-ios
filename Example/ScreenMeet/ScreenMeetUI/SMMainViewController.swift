//
//  SMMainViewController.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 23.02.2021.
//

import UIKit
import ScreenMeetSDK
import WebRTC

class SMMainViewController: UIViewController {
    
    private var controlButtonsStackView: SMControlBar!
    
    private var centerVideoView: SMMainVideoView!
    
    private var cornerVideoView: SMSmallVideoView!
    
    private var remoteVideosView: SMRemoteVideosView = {
        let view = SMRemoteVideosView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    weak private var optionVC: SMOptionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SMUserInterface.manager.delegate = self
        
        view = UIView()
        view.backgroundColor = .black
        
        createCenterVideoView()
        
        createCornerVideoView()
        
        createControlButtonsStackView()
        
        view.addSubview(remoteVideosView)
        
        NSLayoutConstraint.activate([
            remoteVideosView.topAnchor.constraint(equalTo: cornerVideoView.bottomAnchor, constant: 0),
            remoteVideosView.bottomAnchor.constraint(equalTo: controlButtonsStackView.topAnchor, constant: -20),
            remoteVideosView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            remoteVideosView.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let isLocalVideoEnabled = SMUserInterface.manager.isVideoEnabled

        controlButtonsStackView.micStatus(isEnabled: SMUserInterface.manager.isAudioEnabled)
        controlButtonsStackView.cameraStatus(isEnabled: isLocalVideoEnabled)
        controlButtonsStackView.screenShareStatus(isEnabled: SMUserInterface.manager.isScreenShareEnabled)
        
        cornerVideoView.update(with: "Me", audioState: SMUserInterface.manager.isAudioEnabled, videoState: SMUserInterface.manager.isVideoEnabled, videoTrack: SMUserInterface.manager.localVideoTrack)
        
        if let participant = ScreenMeet.getParticipants().first {
            SMUserInterface.manager.mainParticipantId = participant.id
            centerVideoView.update(with: participant)
        }
    }
    
    private func createCenterVideoView() {
        centerVideoView = SMMainVideoView()
        centerVideoView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(centerVideoView)
        
        NSLayoutConstraint.activate([
            centerVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            centerVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            centerVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            centerVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func createCornerVideoView() {
        cornerVideoView = SMSmallVideoView()
        cornerVideoView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cornerVideoView)
        
        NSLayoutConstraint.activate([
            cornerVideoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            cornerVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            cornerVideoView.widthAnchor.constraint(equalToConstant: 80),
            cornerVideoView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func createControlButtonsStackView() {
        controlButtonsStackView = SMControlBar()
        controlButtonsStackView.setup()
        controlButtonsStackView.delegate = self
        view.addSubview(controlButtonsStackView)
        
        NSLayoutConstraint.activate([
            controlButtonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlButtonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            controlButtonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateContent() {
        DispatchQueue.main.async { [unowned self] in
            optionVC?.reloadContent()
            cornerVideoView.update(with: "Me", audioState: SMUserInterface.manager.isAudioEnabled, videoState: SMUserInterface.manager.isVideoEnabled, videoTrack: SMUserInterface.manager.localVideoTrack)
            remoteVideosView.reloadContent()
        }
    }
}

extension SMMainViewController: SMControlBarDelegate {
    
    func micButtonTapped() {
        ScreenMeet.toggleLocalAudio()
    }
    
    func cameraButtonTapped() {
        ScreenMeet.toggleLocalVideo()
    }
    
    func screenShareButtonTapped() {
        if SMUserInterface.manager.isScreenShareEnabled {
            ScreenMeet.changeVideoSource(.frontCamera, { [weak self] error in
                if error == nil {
                    DispatchQueue.main.async {
                        self?.controlButtonsStackView.screenShareStatus(isEnabled: false)
                        self?.controlButtonsStackView.cameraStatus(isEnabled: true)
                    }
                }
                print("Error: \(error.debugDescription)")
            })
        } else {
            ScreenMeet.changeVideoSource(.screen, { [weak self] error in
                if error == nil {
                    DispatchQueue.main.async {
                        self?.controlButtonsStackView.screenShareStatus(isEnabled: true)
                        self?.controlButtonsStackView.cameraStatus(isEnabled: false)
                    }
                }
                print("Error: \(error.debugDescription)")
            })
        }
    }
    
    func optionButtonTapped() {
        let vc = SMOptionViewController()
        optionVC = vc
        self.present(vc, animated: true)
    }
    
    func hangUpButtonTapped() {
        dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: Notification.Name("ScreenMeetSessionEnd"), object: nil)
        })
        ScreenMeet.disconnect { (error) in }
    }
}

extension SMMainViewController: ScreenMeetDelegate {
    
    func onLocalAudioCreated() {
        updateContent()
        controlButtonsStackView.micStatus(isEnabled: true)
    }
    
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack) {
        updateContent()
        videoTrack.add(cornerVideoView.rtcVideoView)
        controlButtonsStackView.cameraStatus(isEnabled: true)
    }
    
    func onLocalVideoStopped() {
        updateContent()
        controlButtonsStackView.cameraStatus(isEnabled: false)
    }
    
    func onLocalAudioStopped() {
        updateContent()
        controlButtonsStackView.micStatus(isEnabled: false)
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        updateContent()
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        centerVideoView.update(with: participant)
        updateContent()
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        updateContent()
        centerVideoView.update(with: participant)
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        updateContent()
        centerVideoView.update(with: participant)
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        updateContent()
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant) {
        updateContent()
        centerVideoView.update(with: participant)
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        updateContent()
    }
}

extension SMMainViewController {
    
    static func presentScreenMeetUI(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let rootVC = self.rootController() else { return }
            
            let vc = SMMainViewController()
            
            rootVC.present(vc, animated: true, completion: completion)
        }
    }
    
    private static func rootController<T: UIViewController>() -> T? {
        let presentedController = UIApplication.shared.windows.first?.rootViewController
        if let root = presentedController as? T {
            return root
        } else if let topController = (presentedController as? UINavigationController)?.topViewController as? T {
            return topController
        } else if let tabController = (presentedController as? UITabBarController)?.selectedViewController as? T {
            return tabController
        }
        
        return nil
    }
}
