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
    
    var isCameraEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .CAMERA
    }
    
    var isScreenShareEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .SCREEN
    }
    
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
        mainParticipant = participant
        
        updateContent()
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started video")
        mainParticipant = participant
        updateContent()
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started audio")
        mainParticipant = participant
        updateContent()
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant left: " + participant.name)
        mainParticipant = ScreenMeet.getParticipants().first
        updateContent()
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " has changed its media state (muted, resumed, etc) \(participant.avState). VideoTrack==\(participant.videoTrack == nil ? "nil": participant.videoTrack?.trackId ?? "Track Id 0001")")
        mainParticipant = participant
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
            smMainVC.disconnect()
        case .disconnected(.callEndedByServer):
            print("Call disconnected. Call is ended by server")
            smMainVC.disconnect()
        case .disconnected(.leftCall):
            print("Call disconnected. Client left call")
        case .disconnected(.networkError):
            print("Call disconnected. Network error")
            smMainVC.disconnect()
        case .disconnected(.knockWaitTimeExpired):
            print("Waited for the entrance for too long. Hanging up")
            smMainVC.disconnect()
        case .disconnected(.reconnectWaitTimeExpired):
            print("Waited for reconnect for too long. Hanging up")
            smMainVC.disconnect()
        case .disconnected(.hostRefuedToLetIn):
            print("Host refused to let in the room")
            smMainVC.disconnect()
        }
        
        UIApplication.shared.isIdleTimerDisabled = shouldPreventScreenSleep
        updateContent()
    }
    
    func onError(_ error: SMError) {
        NSLog("[ScreenMeet] Error: \(error.message)")
        
        updateContent()
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
        presentRequestAlert(for: feature.type, participant: feature.requestorParticipant, completion: decisionHandler)
        updateContent()
    }
    
    func onFeatureRequestRejected(feature: SMFeature) {
        NSLog("[ScreenMeet] Feature rejected: \(feature.type.rawValue), from participant: \(feature.requestorParticipant.name)")
        requestAlertController.dismiss(animated: true, completion: nil)
        updateContent()
    }
    
    func onFeatureStopped(feature: SMFeature) {
        if feature.type == .remotecontrol {
            smMainVC.updateRemoteControlState(false)
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
    
    func presentRequestAlert(for entitlement: SMEntitlementType, participant: SMParticipant, completion: @escaping (Bool) -> Void) {
        var title: String
        var message: String
        
        switch entitlement {
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
