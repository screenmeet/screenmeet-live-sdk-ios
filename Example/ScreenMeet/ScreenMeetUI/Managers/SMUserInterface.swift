//
//  SMUserInterface.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 10.03.2021.
//

import Foundation
import WebRTC
import ScreenMeetSDK

class SMUserInterface {
    
    private init() { }
    
    static let manager = SMUserInterface()
    
    private var floatingView: SMFloatingVideoView = {
        let view = SMFloatingVideoView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        return view
    }()
    
    private var smMainVC: SMMainViewController = {
        let vc = SMMainViewController()
        return vc
    }()
    
    var isAudioEnabled: Bool {
        return ScreenMeet.getMediaState().isAudioActive
    }
    
    var isScreenShareByImageTransfernOn: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().isScreenShareByImageTransfernOn
    }
    
    var isCameraEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .CAMERA
    }
    
    var isScreenShareEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .SCREEN && !ScreenMeet.getMediaState().isScreenShareByImageTransfernOn
    }
    
    var currentReqeustId: String!
    var requestAlertController = UIAlertController()
    
    var mainParticipant: SMParticipant?
    
    var localVideoTrack: RTCVideoTrack?
    
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    func updateContent() {
        floatingView.update(with: nil,
                            audioState: isAudioEnabled,
                            videoState: isCameraEnabled,
                            videoTrack: mainParticipant?.videoTrack ?? localVideoTrack)
        
        smMainVC.updateContent(with: mainParticipant)
    }
}

extension SMUserInterface: ScreenMeetDelegate {
    
    var rootViewController: UIViewController? {
        return smMainVC.navigationController
    }
    
    func onLocalAudioCreated() {
        NSLog("[ScreenMeet] Local user started audio")
        updateContent()
    }
    
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack) {
        NSLog("[ScreenMeet] Local user started video")
        localVideoTrack = videoTrack
        updateContent()
    }
    
    func onLocalVideoSourceChanged() {
        NSLog("[ScreenMeet] Video source for local video has changed")
        updateContent()
    }
    
    func onLocalVideoStopped() {
        NSLog("[ScreenMeet] Local user stopped video")
        
        updateContent()
    }
    
    func onLocalAudioStopped() {
        NSLog("[ScreenMeet] Local user stopped audio")
        updateContent()
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant joined: " + participant.name)
        
        updateContent()
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started video")
        
        if mainParticipant?.id == participant.id {
            mainParticipant = participant
        }
        if mainParticipant == nil {
            mainParticipant = participant
        }

        updateContent()
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started audio")
        updateContent()
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant left: " + participant.name)
        
        if mainParticipant?.id == participant.id {
            mainParticipant = nil
        }
        updateContent()
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " has changed its media state (muted, resumed, etc) \(participant.avState). VideoTrack==\(participant.videoTrack == nil ? "nil": participant.videoTrack?.trackId ?? "Track Id 0001")")
        
        if mainParticipant?.id == participant.id {
            mainParticipant = participant
        }

        updateContent()
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant became active speaker: " + participant.name)
        mainParticipant = participant
        
        updateContent()
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        var shouldPreventScreenSleep = false
        
        NSLog("[ScreenMeet] Connection state: \(newState)")
        switch newState {
        case .connecting:
            print("waiting for connecting to call ...")
        case .connected:
            smMainVC.updateMessages()
            shouldPreventScreenSleep = true
            print("joined the call")
        case .reconnecting:
            shouldPreventScreenSleep = true
            print("trying to restore connection to call ...")
        case .waitingEntrancePermission:
            shouldPreventScreenSleep = true
            print("waiting for the host to let me in (knock feature) ...")
        case .disconnected(.callNotStarted):
            print("Call disconnected. Call is not started")
            dismissCallScreen()
        case .disconnected(.callEndedByServer):
            localVideoTrack = nil
            mainParticipant = nil
            dismissCallScreen()
            print("Call disconnected. Call is ended by server")
        case .disconnected(.leftCall):
            print("Call disconnected. Client left call")
            localVideoTrack = nil
            mainParticipant = nil
            dismissCallScreen()
        case .disconnected(.networkError):
            print("Call disconnected. Network error")
        case .disconnected(.knockWaitTimeExpired):
            print("Waited for the entrance for too long. Hanging up")
        case .disconnected(.reconnectWaitTimeExpired):
            print("Waited for reconnect for too long. Hanging up")
        case .disconnected(.hostRefuedToLetIn):
            print("Host refused to let in the room")
            mainParticipant = nil
        }
        
        UIApplication.shared.isIdleTimerDisabled = shouldPreventScreenSleep
        updateContent()
    }
    
    func dismissCallScreen() {
        smMainVC.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: Notification.Name("ScreenMeetSessionEnd"), object: nil)
        })
    }
    
    func onError(_ error: SMError) {
        DispatchQueue.main.async { [self] in
            if let mainVC = rootController()?.presentedViewController {
                if mainVC.presentedViewController == requestAlertController {
                    requestAlertController.dismiss(animated: false, completion: nil)
                }
            }
        
            let errorAlertController = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", message: "", preferredStyle: .alert)
            
          
            let okAction = UIAlertAction(title: "OK", style: .default) { (_) -> Void in
                
            }
            
            errorAlertController.addAction(okAction)
            
            
            if let mainVC = rootController()?.presentedViewController {
                mainVC.present(errorAlertController, animated: true, completion: nil)
            } else {
                rootController()?.present(errorAlertController, animated: true, completion: nil)
            }
            
            let margin:CGFloat = 8.0
            let rect = CGRect(x: margin, y: margin, width: 260, height: 450)

            let customView = UITextView(frame: rect)
            customView.backgroundColor = UIColor.clear
            customView.isEditable = false
            customView.font = UIFont(name: "HelveticaNeue-Light", size: 13)

            customView.text = error.message
            errorAlertController.view.addSubview(customView)
        }
        NSLog("[ScreenMeet] Error: \(error.message)")
    }
    
    func onRemoteControlEvent(_ event: SMRemoteControlEvent) {
        if let keyboardEvent = event as? SMRemoteControlKeyboardEvent {
            //NSLog("Keyboard event: \(keyboardEvent.acii); \(keyboardEvent.key))")
        }
        else if let mouseEvent = event as? SMRemoteControlMouseEvent {
            //NSLog("Mouse event: (\(mouseEvent.x); \(mouseEvent.y))")
        }
    }
    
    /// Features

    func onFeatureRequest(_ feature: SMFeature, _ decisionHandler: @escaping (Bool) -> Void) {
        NSLog("[ScreenMeet] Request entitlement: \(feature.type.rawValue), from participant: \(feature.requestorParticipant.name)")
        presentRequestAlert(for: feature.type, participant: feature.requestorParticipant, feature.requestId, completion: decisionHandler)
        updateContent()
    }
    
    func onFeatureRequestRejected(requestId: String) {
        NSLog("[ScreenMeet] Feature request rejected, requestId: \(requestId)")
        requestAlertController.dismiss(animated: true, completion: nil)
        updateContent()
    }
    
    func onFeatureStopped(feature: SMFeature) {
        if feature.type == .remotecontrol {
            if !ScreenMeet.activeFeatures().contains(where: { feature in
                feature.type == .remotecontrol
            }) {
                smMainVC.updateRemoteControlState(false)
            }
        }
        
        NSLog("[ScreenMeet] Feature stopped: \(feature.type.rawValue), participant: \(feature.requestorParticipant.name)")
    }
    
    func onFeatureStarted(feature: SMFeature) {
        if feature.type == .remotecontrol {
            smMainVC.updateRemoteControlState(true)
        }
        
        NSLog("[ScreenMeet] Feature started: \(feature.type.rawValue), participant: \(feature.requestorParticipant.name)")
    }
    
}

extension SMUserInterface {
    
    private func rootController<T: UIViewController>() -> T? {
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
    
    func presentScreenMeetUI(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [unowned self] in
            guard let rootVC = self.rootController() else { return }
            
            if rootVC.presentedViewController == nil {
                rootVC.definesPresentationContext = true
                let navigationViewController = UINavigationController(rootViewController: self.smMainVC)
                rootVC.present(navigationViewController, animated: true, completion: completion)
            }
            
        }
    }
    
    func presentFloatingUI() {
        DispatchQueue.main.async { [unowned self] in
            guard let window = UIApplication.shared.windows.first else { return }
            window.addSubview(floatingView)
        }
    }
    
    func hideFloatingUI() {
        DispatchQueue.main.async { [unowned self] in
            floatingView.removeFromSuperview()
        }
    }
    
    func presentRequestAlert(for permissionType: SMPermissionType, participant: SMParticipant, _ requestId: String, completion: @escaping (Bool) -> Void) {
        var title: String
        var message: String
        
        currentReqeustId = requestId
        switch permissionType {
            case .laserpointer:
                title = "\"\(participant.name)\" Would you like to start laser pointer?"
                message = "It's needed to help you navigate"
            
            case .remotecontrol:
                title = "\"\(participant.name)\" Would you like to be remote controlled?"
                message = "It he will allow making touches and keyboard event by remote participant on your device"
        }
        
        if let mainVC = rootController()?.presentedViewController {
            if mainVC.presentedViewController == requestAlertController {
                requestAlertController.dismiss(animated: false, completion: nil)
            }
        }
    
        requestAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let denyAction = UIAlertAction(title: "Don't Allow", style: .default) { (_) -> Void in
            completion(false)
        }
        let grantAction = UIAlertAction(title: "OK", style: .default) { (_) -> Void in
            completion(true)
        }
        
        requestAlertController.addAction(denyAction)
        requestAlertController.addAction(grantAction)
        
        if let mainVC = rootController()?.presentedViewController {
            mainVC.present(requestAlertController, animated: true, completion: nil)
        } else {
            rootController()?.present(requestAlertController, animated: true, completion: nil)
        }
    }
}
