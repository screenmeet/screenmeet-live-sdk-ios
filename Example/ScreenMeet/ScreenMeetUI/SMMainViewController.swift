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
    
    private var chatVisible = false
    private var chatWidth: CGFloat = 240.0
    private var chatTrailingConstraint: NSLayoutConstraint!
    private var thread: Thread? = nil
    private var isRunning = false
    private var imageHandler: SMImageHandler? = nil
    
    private var chatMessagesView: SMChatMessagesView = {
        let chatMessagesView = SMChatMessagesView()
        chatMessagesView.translatesAutoresizingMaskIntoConstraints = false
        return chatMessagesView
    }()
    
    private var chatBubbleView: SMChatBubbleView = {
        let chatBubbleView = SMChatBubbleView()
        chatBubbleView.translatesAutoresizingMaskIntoConstraints = false
        return chatBubbleView
    }()
    
    private var startImageTransferButton: UIButton = {
        let startImageTransferButton = UIButton()
        startImageTransferButton.isEnabled = true
        startImageTransferButton.backgroundColor = UIColor(red: 122 / 255, green: 122 / 255, blue: 122 / 255, alpha: 1)
        startImageTransferButton.setImage(UIImage(named: "icon-image-transfer"), for: .normal)
        startImageTransferButton.contentVerticalAlignment = .fill
        startImageTransferButton.contentHorizontalAlignment = .fill
        startImageTransferButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 10)
        startImageTransferButton.layer.masksToBounds = true
        startImageTransferButton.layer.cornerRadius = 25
        startImageTransferButton.addTarget(self, action:  #selector(startImageTransferButtonTapped), for: .touchUpInside)
        startImageTransferButton.translatesAutoresizingMaskIntoConstraints = false
        return startImageTransferButton
    }()
    
    private var testRemoteControlButton: UIButton = {
        let testRemoteControlButton = UIButton()
        testRemoteControlButton.isEnabled = true
        testRemoteControlButton.setBackgroundImage(UIImage(named: "icon-remote-control"), for: .normal)
        testRemoteControlButton.addTarget(self, action:  #selector(demoRemoteControlButtonTapped), for: .touchUpInside)
        testRemoteControlButton.translatesAutoresizingMaskIntoConstraints = false
        return testRemoteControlButton
    }()
    
    private var remoteControlStatusView: UIView = {
        let remoteControlStatusView = UIView()
        remoteControlStatusView.backgroundColor = .red
        remoteControlStatusView.layer.cornerRadius = 5
        remoteControlStatusView.layer.masksToBounds = true
        remoteControlStatusView.translatesAutoresizingMaskIntoConstraints = false
        return remoteControlStatusView
    }()
    
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
    
    private var enableFloatingViewButton: SMControlButton = {
        let button = SMControlButton()
        let color = UIColor(red: 212 / 255, green: 212 / 255, blue: 213 / 255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "rectangle.inset.topleft.fill"), for: .normal, color: color)
        button.addTarget(self, action: #selector(enableFloatingViewButtonTapped), for: .touchUpInside)
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
        
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    weak private var optionVC: SMOptionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView()
        view.backgroundColor = .black
        
        layoutCenterVideoView()
        layoutLocalSmallVideoView()
        layoutControlButtonsStackView()
        layoutRemoteVideosView()
        layoutRotateCameraButton()
        layoutEnableFloatingViewButton()
        layoutReconnectingView()
        
        layoutChatBubble()
        layoutRemoteControlButton()
        layoutImageTransferButton()
        layoutChatMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateContent(with: SMUserInterface.manager.mainParticipant)
        SMUserInterface.manager.hideFloatingUI()
        navigationController?.navigationBar.isHidden = true
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
    
    private func layoutRemoteControlButton() {
        view.addSubview(testRemoteControlButton)
        view.addSubview(remoteControlStatusView)
                
        NSLayoutConstraint.activate([
            testRemoteControlButton.bottomAnchor.constraint(equalTo: chatBubbleView.topAnchor, constant: -18),
            testRemoteControlButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            testRemoteControlButton.heightAnchor.constraint(equalToConstant: 44),
            testRemoteControlButton.widthAnchor.constraint(equalToConstant: 44),
            
            remoteControlStatusView.topAnchor.constraint(equalTo: testRemoteControlButton.bottomAnchor, constant: -10),
            remoteControlStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            remoteControlStatusView.heightAnchor.constraint(equalToConstant: 10),
            remoteControlStatusView.widthAnchor.constraint(equalToConstant: 10)
        ])
    }
    
    private func layoutImageTransferButton() {
        view.addSubview(startImageTransferButton)
        view.addSubview(startImageTransferButton)
                
        NSLayoutConstraint.activate([
            startImageTransferButton.bottomAnchor.constraint(equalTo: controlButtonsStackView.topAnchor, constant: -18),
            startImageTransferButton.centerXAnchor.constraint(equalTo: controlButtonsStackView.centerXAnchor),
            startImageTransferButton.heightAnchor.constraint(equalToConstant: 50),
            startImageTransferButton.widthAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func layoutChatBubble() {
        chatBubbleView.delegate = self
        view.addSubview(chatBubbleView)
        
        NSLayoutConstraint.activate([
            chatBubbleView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -160),
            chatBubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            chatBubbleView.heightAnchor.constraint(equalToConstant: 50),
            chatBubbleView.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func layoutChatMessages() {
        chatMessagesView.delegate = self
        view.addSubview(chatMessagesView)
        
        chatTrailingConstraint = chatMessagesView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: chatWidth)
        
        let guide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            chatMessagesView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            chatTrailingConstraint,
            guide.bottomAnchor.constraint(equalToSystemSpacingBelow: chatMessagesView.bottomAnchor, multiplier: 1.0),
            chatMessagesView.widthAnchor.constraint(equalToConstant: chatWidth)
        ])
    }
    
    private func layoutRotateCameraButton() {
        view.addSubview(rotateCameraButton)
        
        NSLayoutConstraint.activate([
            rotateCameraButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            rotateCameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70),
            rotateCameraButton.widthAnchor.constraint(equalToConstant: 50),
            rotateCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func layoutEnableFloatingViewButton() {
        view.addSubview(enableFloatingViewButton)
        
        NSLayoutConstraint.activate([
            enableFloatingViewButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            enableFloatingViewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            enableFloatingViewButton.widthAnchor.constraint(equalToConstant: 50),
            enableFloatingViewButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func layoutReconnectingView() {
        view.addSubview(reconnectingView)
        
        NSLayoutConstraint.activate([
            reconnectingView.centerXAnchor.constraint(equalTo: centerVideoView.centerXAnchor, constant: 0),
            reconnectingView.centerYAnchor.constraint(equalTo: centerVideoView.centerYAnchor, constant: 0),
            reconnectingView.widthAnchor.constraint(equalToConstant: 50),
            reconnectingView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        reconnectingView.alpha = 0.8
        reconnectingView.isHidden = true
    }
    
    @objc private func rotateCameraButtonTapped() {
        cameraPosition = cameraPosition == .front ? .back : .front
        
        guard let device = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: .video,
                                                           position: cameraPosition).devices.first else { return }
        
        ScreenMeet.shareCamera(device)
        updateContent(with: SMUserInterface.manager.mainParticipant)
    }
    
    @objc private func startImageTransferButtonTapped() {
        
        if SMUserInterface.manager.isScreenShareByImageTransfernOn {
            isRunning = false
            imageHandler = nil
            ScreenMeet.stopVideoSharing()
        } else {
            ScreenMeet.shareScreenWithImageTransfer({ handler in
                self.isRunning = false
                
                self.imageHandler = handler
                self.thread = Thread(target: self, selector: #selector(self.send), object: nil)
                self.isRunning = true
                self.thread!.start()
            })
            
        }
    }
    
    @objc private func demoRemoteControlButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let viewController = storyboard.instantiateViewController(withIdentifier: "SMDemoRemoteControlTabbarViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func enableFloatingViewButtonTapped() {
        dismiss(animated: true, completion: {
            if ScreenMeet.getConnectionState() == .connected {
                SMUserInterface.manager.presentFloatingUI()
            }
        })
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
    
    private func toggleChatView() {
        if chatVisible {
            hideChat()
        }
        else {
            showChat()
        }
    }
    
    private func hideChat() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.chatTrailingConstraint.constant = (self?.chatWidth ?? 0.0)
            self?.view.layoutIfNeeded()
        } completion: { [weak self] completed in
            self?.chatMessagesView.dismissKeyboard()
        }

        
        chatVisible = false
    }
    
    private func showChat() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.chatTrailingConstraint.constant = 0.0
            self?.view.layoutIfNeeded()
        }
        
        chatVisible = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.chatMessagesView.scrollToBottom()
            self?.chatMessagesView.adjustScroll()
        }
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
                        self?.updateContent(with: SMUserInterface.manager.mainParticipant)
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
        guard !SMUserInterface.manager.isSimulator else { return }
        isRunning = false
        
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
                        self?.updateContent(with: SMUserInterface.manager.mainParticipant)
                    }
                }
            })
        } else if videoStatus != .authorized {
            presentAccessAlert(title: "Camera Access Required", message: "You can enable camera access in the iOS Settings app")
        } else {
            toggleVideo()
        }
    }
    
    func maskWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func screenShareButtonTapped() {
        guard !SMUserInterface.manager.isSimulator else { return }
        
        if SMUserInterface.manager.isScreenShareEnabled {
            isRunning = false
            ScreenMeet.stopVideoSharing()
        } else {
            ScreenMeet.shareScreen()
            updateContent(with: SMUserInterface.manager.mainParticipant)
        }
    }
         
    func random() -> CGFloat {
            return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
    
    @objc func send() {
        while isRunning {
            //let blueImage = maskWithColor(color: UIColor(red: random(), green: random(), blue: random(), alpha: 1.0))
            let blueImage = UIImage(named: "icon-test")!
            imageHandler?.transferImage(blueImage)
            usleep(500000)
        }
        
    }
    
    func optionButtonTapped() {
        let vc = SMOptionViewController()
        optionVC = vc
        self.present(vc, animated: true)
    }
    
    func hangUpButtonTapped() {
        disconnect()
    }
}

extension SMMainViewController {
    func updateMessages() {
        chatMessagesView.updateMessages()
    }
    
    func updateRemoteControlState(_ isEnabled: Bool) {
        testRemoteControlButton.isEnabled = isEnabled
        remoteControlStatusView.backgroundColor = isEnabled ? .green : .red
    }
    
    func updateContent(with participant: SMParticipant?) {
        optionVC?.reloadContent()
        
        if let participant = participant {
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
        if SMUserInterface.manager.isSimulator || AVCaptureDevice.authorizationStatus(for: .video) == .denied || AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
            videoStatus = .unavailable
            rotateCameraButton.isHidden = true
        } else if SMUserInterface.manager.isCameraEnabled {
            videoStatus = .enabled
            rotateCameraButton.isHidden = false
        } else {
            videoStatus = .disabled
            rotateCameraButton.isHidden = true
        }
        
        let screenShareStatus: SMControlBar.ButtonStatus
        if SMUserInterface.manager.isSimulator {
            screenShareStatus = .unavailable
        } else if SMUserInterface.manager.isScreenShareEnabled {
            screenShareStatus = .enabled
        } else {
            screenShareStatus = .disabled
        }
        
        if (SMUserInterface.manager.isScreenShareByImageTransfernOn) {
            startImageTransferButton.backgroundColor =  UIColor(red: 53 / 255, green: 169 / 255, blue: 235 / 255, alpha: 1)
        }
        else {
            startImageTransferButton.backgroundColor = UIColor(red: 122 / 255, green: 122 / 255, blue: 122 / 255, alpha: 1)
        }
        
        controlButtonsStackView.micStatus(audioStatus)
        controlButtonsStackView.cameraStatus(videoStatus)
        controlButtonsStackView.screenShareStatus(screenShareStatus)
        controlButtonsStackView.optionButtonBadgeCount(ScreenMeet.getParticipants().count + 1)
        
        reconnectingView.isHidden = !(ScreenMeet.getConnectionState() == .reconnecting)
        view.isUserInteractionEnabled = !(ScreenMeet.getConnectionState() == .reconnecting)
    }
    
    func disconnect() {
        dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: Notification.Name("ScreenMeetSessionEnd"), object: nil)
        })
        ScreenMeet.disconnect()
    }
}

extension SMMainViewController: SMChatBubbleProtocol {
    func onClicked() {
        isRunning = false
        
        updateContent(with: SMUserInterface.manager.mainParticipant)
        toggleChatView()
    }
}

extension SMMainViewController: SMChatMessagesProtocol {
    func shouldRevealOrClose(_ translation: CGFloat) {
        if translation > chatWidth / 3.0 {
            hideChat()
        }
        else {
            showChat()
        }
    }
    
    func shouldMove(_ translation: CGFloat) {
        let newTrailing = 0.0 + translation
        
        if newTrailing > 0 {
            chatTrailingConstraint.constant = newTrailing
        }
        
    }
    
}
