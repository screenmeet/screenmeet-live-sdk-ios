//
//  SMMainViewController.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 23.02.2021.
//

import UIKit
import ScreenMeetSDK
import WebRTC
import AVFoundation

class SMMainViewController: UIViewController {
    
    private var controlButtonsStackView: SMControlBar = {
        let stackView = SMControlBar()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var centerVideoView: SMMainVideoView = {
        let view = SMMainVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var localSmallVideoView: SMSmallVideoView = {
        let view = SMSmallVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var remoteVideosView: SMRemoteVideosView = {
        let view = SMRemoteVideosView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var rotateCameraButton: SMControlButton = {
        let button = SMControlButton()
        let color = UIColor(red: 212 / 255, green: 212 / 255, blue: 213 / 255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal, color: color)
        button.addTarget(self, action: #selector(rotateCameraButtonTapped), for: .touchUpInside)
        button.backgroundColor = .clear
        button.layer.borderWidth = 2
        button.layer.borderColor = color.cgColor
        button.layer.cornerRadius = 25
        return button
    }()
    
    private var reconnectingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            activityIndicator.heightAnchor.constraint(equalToConstant: 30),
            activityIndicator.widthAnchor.constraint(equalToConstant: 30),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
        
        view.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    weak private var optionVC: SMOptionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SMUserInterface.manager.delegate = self
        
        view = UIView()
        view.backgroundColor = .black
        
        layoutCenterVideoView()
        layoutLocalSmallVideoView()
        layoutControlButtonsStackView()
        layoutRemoteVideosView()
        layoutRotateCameraButton()
        layoutReconnectingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateContent(with: ScreenMeet.getParticipants().first)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.post(name: Notification.Name("ScreenMeetUIDidAppear"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.post(name: Notification.Name("ScreenMeetUIWillDisappear"), object: nil)
    }
    
    private func layoutCenterVideoView() {
        view.addSubview(centerVideoView)
        
        NSLayoutConstraint.activate([
            centerVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            centerVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            centerVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            centerVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func layoutLocalSmallVideoView() {
        view.addSubview(localSmallVideoView)
        
        NSLayoutConstraint.activate([
            localSmallVideoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            localSmallVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            localSmallVideoView.widthAnchor.constraint(equalToConstant: 80),
            localSmallVideoView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func layoutRemoteVideosView() {
        view.addSubview(remoteVideosView)
        
        NSLayoutConstraint.activate([
            remoteVideosView.topAnchor.constraint(equalTo: localSmallVideoView.bottomAnchor, constant: 0),
            remoteVideosView.bottomAnchor.constraint(equalTo: controlButtonsStackView.topAnchor, constant: -20),
            remoteVideosView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            remoteVideosView.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func layoutControlButtonsStackView() {
        controlButtonsStackView.delegate = self
        view.addSubview(controlButtonsStackView)
        
        NSLayoutConstraint.activate([
            controlButtonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlButtonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            controlButtonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func layoutRotateCameraButton() {
        view.addSubview(rotateCameraButton)
        
        NSLayoutConstraint.activate([
            rotateCameraButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            rotateCameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            rotateCameraButton.widthAnchor.constraint(equalToConstant: 50),
            rotateCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func layoutReconnectingView() {
        centerVideoView.addSubview(reconnectingView)
        
        NSLayoutConstraint.activate([
            reconnectingView.centerXAnchor.constraint(equalTo: centerVideoView.centerXAnchor, constant: 0),
            reconnectingView.centerYAnchor.constraint(equalTo: centerVideoView.centerYAnchor, constant: 0),
            reconnectingView.widthAnchor.constraint(equalToConstant: 50),
            reconnectingView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        reconnectingView.alpha = 0.8
        reconnectingView.isHidden = true
    }
    
    private func updateContent(with participant: SMParticipant? = nil) {
        DispatchQueue.main.async { [unowned self] in
            optionVC?.reloadContent()
            
            if let participant = participant ?? ScreenMeet.getParticipants().first {
                SMUserInterface.manager.mainParticipantId = participant.id
                centerVideoView.update(with: participant)
                localSmallVideoView.isHidden = false
            } else {
                centerVideoView.update(with: "Me", audioState: SMUserInterface.manager.isAudioEnabled, videoState: SMUserInterface.manager.isCameraEnabled, videoTrack: SMUserInterface.manager.localVideoTrack)
                localSmallVideoView.isHidden = true
            }
            
            localSmallVideoView.update(with: "Me", audioState: SMUserInterface.manager.isAudioEnabled, videoState: SMUserInterface.manager.isCameraEnabled, videoTrack: SMUserInterface.manager.localVideoTrack)
            
            remoteVideosView.reloadContent()
            
            let audioStatus: SMControlBar.ButtonStatus
            if AVCaptureDevice.authorizationStatus(for: .audio) == .denied || AVCaptureDevice.authorizationStatus(for: .audio) == .restricted {
                audioStatus = .unavailable
            } else if SMUserInterface.manager.isAudioEnabled {
                audioStatus = .enabled
            } else {
                audioStatus = .disabled
            }
            
            let videoStatus: SMControlBar.ButtonStatus
            if AVCaptureDevice.authorizationStatus(for: .video) == .denied || AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                videoStatus = .unavailable
                rotateCameraButton.isHidden = true
            } else if SMUserInterface.manager.isCameraEnabled {
                videoStatus = .enabled
                rotateCameraButton.isHidden = false
            } else {
                videoStatus = .disabled
                rotateCameraButton.isHidden = true
            }
            
            controlButtonsStackView.micStatus(audioStatus)
            controlButtonsStackView.cameraStatus(videoStatus)
            controlButtonsStackView.screenShareStatus(SMUserInterface.manager.isScreenShareEnabled ? .enabled : .disabled)
            controlButtonsStackView.optionButtonBadgeCount(ScreenMeet.getParticipants().count + 1)
            
            reconnectingView.isHidden = !(ScreenMeet.getConnectionState() == .reconnecting)
            view.isUserInteractionEnabled = !(ScreenMeet.getConnectionState() == .reconnecting)
        }
    }
    
    @objc private func rotateCameraButtonTapped() {
        cameraPosition = cameraPosition == .front ? .back : .front
        
        guard let device = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: .video,
                                                           position: cameraPosition).devices.first else { return }
        
        ScreenMeet.shareCamera(device)
        updateContent()
    }
    
    private func presentAccessAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

extension SMMainViewController: SMControlBarDelegate {
    
    func micButtonTapped() {
        func toggleAudio() {
            if SMUserInterface.manager.isAudioEnabled {
                ScreenMeet.stopAudioSharing()
            }
            else {
                ScreenMeet.shareMicrophone()
            }
        }
        
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { [weak self] (isGranted) in
                DispatchQueue.main.async {
                    if isGranted {
                        toggleAudio()
                    } else {
                        self?.updateContent()
                    }
                }
            })
        } else if audioStatus != .authorized {
            presentAccessAlert(title: "Microphone Access Required", message: "You can enable microphone access in the iOS Settings app")
        } else {
            toggleAudio()
        }
    }
    
    func cameraButtonTapped() {
        func toggleVideo() {
            if SMUserInterface.manager.isCameraEnabled {
                ScreenMeet.stopVideoSharing()
            } else {
                guard let device = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                                   mediaType: .video,
                                                                   position: cameraPosition).devices.first else { return }
                
                ScreenMeet.shareCamera(device)
            }
        }
        
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if videoStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (isGranted) in
                DispatchQueue.main.async {
                    if isGranted {
                        toggleVideo()
                    } else {
                        self?.updateContent()
                    }
                }
            })
        } else if videoStatus != .authorized {
            presentAccessAlert(title: "Camera Access Required", message: "You can enable camera access in the iOS Settings app")
        } else {
            toggleVideo()
        }
    }
    
    func screenShareButtonTapped() {
        if SMUserInterface.manager.isScreenShareEnabled {
            ScreenMeet.stopVideoSharing()
        } else {
            ScreenMeet.shareScreen()
            updateContent()
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
        ScreenMeet.disconnect()
    }
}

extension SMMainViewController: ScreenMeetDelegate {
    
    func onLocalAudioCreated() {
        updateContent()
    }
    
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack) {
        updateContent()
    }
    
    func onLocalVideoSourceChanged() {
        updateContent()
    }
    
    func onLocalVideoStopped() {
        updateContent()
    }
    
    func onLocalAudioStopped() {
        updateContent()
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        updateContent()
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        updateContent(with: participant)
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        updateContent(with: participant)
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        updateContent(with: participant)
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        updateContent()
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant) {
        updateContent(with: participant)
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        switch newState {
        case .connecting:
            print("waiting for connecting to call ...")
        case .connected:
            print("joined the call")
        case .reconnecting:
            print("trying to restore connection to call ...")
        case .disconnected(.callNotStarted):
            print("Call disconnected. Call is not started")
            hangUpButtonTapped()
        case .disconnected(.callEnded):
            print("Call disconnected. Call is finished")
            hangUpButtonTapped()
        case .disconnected(.leftCall):
            print("Call disconnected. Client left call")
            hangUpButtonTapped()
        case .disconnected(.networkError):
            print("Call disconnected. Network error")
            hangUpButtonTapped()
        }
        updateContent()
    }
    
    func onError(_ error: SMError) {
        
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
