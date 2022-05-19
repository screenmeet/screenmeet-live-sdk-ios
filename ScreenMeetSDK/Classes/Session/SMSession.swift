//
//  SMSession.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit
import WebRTC

/// ScreenMeet initial connection callback
public typealias SMConnectCompletion = (_ error: SMError?) -> Void

/// Protocol to handle chat events during the session
public protocol ScreenMeetChatDelegate: AnyObject {
    
    /// Received new  text  message in the chat.
    /// - Parameter message: Text message. See `SMTextMessage`
    func onTextMessageReceived(_ message: SMTextMessage)
    
    /// Error ocured when trying to sen the outbound message into chat.
    /// - Parameter message: Text message. See `SMTextMessage`
    func onMessageSendFailed(_ error: SMError)
}

/// Protocol to handle session events
public protocol ScreenMeetDelegate: AnyObject {
    
    /// on Audio stream created
    func onLocalAudioCreated()
    
    /// on Local Video stream created
    /// - Parameter videoTrack: Can be used to preview local video. See `RTCVideoTrack`
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack)
    
    /// Called when videosource for local video has changed (fro example from back camera to front camera, or fomr any camera to screen)
    func onLocalVideoSourceChanged()
    
    /// on Local Video stream stoped
    func onLocalVideoStopped()
    
    /// on Local Audio stream stoped
    func onLocalAudioStopped()
    
    // Participants
    
    /// On participant joins call.
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onParticipantJoined(_ participant: SMParticipant)
    
    /// On receiving video stream from participant.
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onParticipantVideoTrackCreated(_ participant: SMParticipant)
    
    /// On receiving audio stream from participant.
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onParticipantAudioTrackCreated(_ participant: SMParticipant)
    
    /// On participant left call.
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onParticipantLeft(_ participant: SMParticipant)
    
    /// When participant state was changed. For example participant muted, paused, resumed video, etc
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onParticipantMediaStateChanged(_ participant: SMParticipant)
    
    /// When active speaker changed.
    /// - Parameter participant: Participant details. See `SMParticipant`
    func onActiveSpeakerChanged(_ participant: SMParticipant)
    
    /// On connection state change
    /// - Parameter new session state: `SMState`
    func onConnectionStateChanged(_ newState: SMConnectionState)
    
    /// On error occurred
    /// - Parameter error `SMError`
    func onError(_ error: SMError)
    
    /// Occurs when request for entitlement
    ///
    /// - Parameters:
    ///  - feature: Feature being requested. Containes details about type of the feature and participant who requested it
    ///  - decisionHandler: The callback called after request is accepted or denied
    ///  - granted: The retrieved decision for request.
    func onFeatureRequest(_ feature: SMFeature, _ decisionHandler: @escaping (_ granted: Bool) -> Void)
    
    /// Occurs when previous request is rejected
    ///
    /// - Parameters:
    ///  - feature: Feature request that has been rejested. Containes details about type of the feature and participant who requested it
    func onFeatureRequestRejected(feature: SMFeature)
    
    /// Occurs when request for entitlement
    ///
    /// - Parameters:
    ///  - feture: Feature that has been stopped
    func onFeatureStopped(feature: SMFeature)
    
    /// Occurs when certain feature (you approved) starts its activity (remtoe control,  laser pointer)
    ///
    /// - Parameters:
    ///  - feature: Feature that has stated
    func onFeatureStarted(feature: SMFeature)
    
    /// Occures during remote control session. Can be a mouse or a keybaord event
    ///
    /// - Parameters:
    ///  - event: Remote control event
    func onRemoteControlEvent(_ event: SMRemoteControlEvent)
    
    /// Root view controller. It is used for remote control (Remote peer being able to perform touches on your view controller). It should be the root(bottom most superview) view of the entire window
    var rootViewController: UIViewController? { get }
    
}

class SMSession: NSObject {
    /// Seession delegate. Used for the events related to video/audio session
    weak var delegate: ScreenMeetDelegate?
    
    /// Chat seession delegate. Used forl the events related to chat
    weak var chatDelegate: ScreenMeetChatDelegate?
    
    private var connectCompletion: SMConnectCompletion? = nil
    private var session: Session!
    
    /// Connect to the room
    /// - Parameter code: The string code of the room
    /// - Parameter localUserName: The name of your local user. It will be visible to all attendees
    /// - Parameter completion: Completion of the connection attempt. See `SMConnectCompletion`
    func connect(_ code: String,
                 _ localUserName: String,
                 _ completion: @escaping SMConnectCompletion) {
        
            self.connectCompletion = completion
        
            SMHandshakeTransaction()
            .withCode(code)
            .withLocalUserName(localUserName)
            .withChannelMessageHandler { [weak self] channelMessage in
                self?.processIncomingChannelMessage(channelMessage)
            }.run { [weak self] session, error in
                if let error = error {
                    self?.connectCompletion?(error)
                }
                else {
                    self?.session = session
                    self?.startWebRTC(session!.turn)
                }
        }
    }
    
    /// Disconnect, cancel all tracks, cleanup data
    func disconnect() {
        SMDisconnectTransaction().run()
    }
    
    private func setVideoSourceDevice(videoDevice: AVCaptureDevice!) {
        if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
            msChannel.setVideoSourceDevice(videoDevice)
        }
    }
    
    private func createImageTransferHandler() -> SMImageHandler {
        let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        return msChannel.createImageTransferHandler()
    }
    
    func getVideoEnabled() -> Bool {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        return channel.getVideoEnabled()
    }
    
    func getAudioEnabled() -> Bool {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        return channel.getAudioEnabled()
    }
    
    func getConnectionState() -> SMConnectionState {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        return channel.transport.webSocketClient.getConnectionState()
    }
    
    func getIceConnectionState() -> SMIceConnectionState {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        return channel.getIceConnectionState()
    }
    
    func getAppStreamService() -> SMAppStreamServiceProtocol {
        ScreenVideoCapturer.appStreamService
    }
    
    private func startWebRTC(_ turnUrl: String) {
        SMStartWebRTCTransaction(turnUrl)
            .run { [weak self] error in
            if let error = error {
                NSLog("WebRTC start failed: " + error.message)
            }
            else {
                self?.connectCompletion?(nil)
                NSLog("WebRTC started")
            }
        }
    }
    
    private func reconnect() {
        
    }
    
    /// Chat
    
    /// Returns all the messages from the chat of the ongoing session.
    func getChatMessages() -> [SMTextMessage] {
        if let chatChannel = SMChannelsManager.shared.channel(for: .chat) as? SMChatChannel {
            return chatChannel.getMessages()
        }
        
        return [SMTextMessage]()
    }
    
    /// Send the message into the chat of ongoing session.
    func sendTextMessage(_ text: String) {
        if let chatChannel = SMChannelsManager.shared.channel(for: .chat) as? SMChatChannel {
            chatChannel.sendTextMessage(text)
        }
    }
    
    /// Channels messaging

    private func processIncomingChannelMessage(_ message: SMChannelMessage) {
        SMChannelsManager.shared.process(message)
    }
    
    ///Features
    
    func activeFeatures() -> [SMFeature] {
        let channel = SMChannelsManager.shared.channel(for: .entitlements) as! SMEntitlementsChannel
        return channel.activeFeatures()
    }
    
    public func stopFeature(_ feature: SMFeature) {
        let channel = SMChannelsManager.shared.channel(for: .entitlements) as! SMEntitlementsChannel
        return channel.revokeAccess(for: feature.type, requestorId: feature.requestorParticipant.id)
    }
    
}

extension SMSession {

   func getAVState() -> SMParticipantMediaState {
        var cState = SMCallerState()
        cState.audioEnabled = getAudioEnabled()
        cState.videoEnabled = getVideoEnabled()
        cState.screenEnabled = getVideoEnabled() && getVideoSourceDevice() == nil
        return SMParticipantMediaState(callerState: cState)
    }
    
    func startVideoSharing(_ cameraDevice: AVCaptureDevice) {
        let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel

        if (getAVState().isVideoActive) {
            /* if the video is running and it's not camera or the devices are different, just switch the source*/
            if (getAVState().videoState != .CAMERA || getVideoSourceDevice()?.uniqueID != cameraDevice.uniqueID) {
                setVideoSourceDevice(videoDevice: cameraDevice)
                msChannel.changeCapturer(cameraDevice) { [weak self] error in
                    if (error == nil) {
                        DispatchQueue.main.async {
                            self?.delegate?.onLocalVideoSourceChanged()
                        }
                    }
                }
            }
            else {
                NSLog("[ScreenMeet]", "Camrea video with the exact same device has been started already")
            }
        }
        else {
            setVideoSourceDevice(videoDevice: cameraDevice)
            msChannel.setVideoState(true) { [weak self] error, videoTrack in
                if let error = error {
                    self?.delegate?.onError(error)
                }
                else {
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalVideoCreated(videoTrack!)
                    }
                }
            }
        }
    }
    
    func startScreenSharing() {
        let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        let audioVideoState = getAVState()
        
        /*If the video is running and it's not a screen, just change the source*/
        if (audioVideoState.isVideoActive && audioVideoState.videoState != .SCREEN) {
            msChannel.changeCapturer(nil) { [weak self] error in
                if let error = error {
                    self?.delegate?.onError(error)
                }
                else  {
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalVideoSourceChanged()
                    }
                }
            }
        }
        /*The video is stopped - create video track*/
        else if (!audioVideoState.isVideoActive) {
            setVideoSourceDevice(videoDevice: nil)
            msChannel.setVideoState(true) { [weak self] error, videoTrack in
                if let error = error {
                    self?.delegate?.onError(error)
                }
                else {
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalVideoCreated(videoTrack!)
                    }
                }
            }
        }
    }
    
    func startScreenSharingImageTransfer(_ completion: @escaping ((SMImageHandler?) -> Void)) {
        let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        let audioVideoState = getAVState()
        
        /*If the video is running and it's not a screen, stop source*/
        if (audioVideoState.isVideoActive && audioVideoState.videoState != .SCREEN) {
            msChannel.stopCapturer() { [weak self] error in
                if let error = error {
                    self?.delegate?.onError(error)
                    completion(nil)
                }
                else  {
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalVideoSourceChanged()
                    }
                    completion(msChannel.createImageTransferHandler())
                }
            }
        }
        /*The video is stopped - create video track*/
        else if (!audioVideoState.isVideoActive) {
            let imageHandler = msChannel.createImageTransferHandler()
            msChannel.setVideoState(true) { [weak self] error, videoTrack in
                if let error = error {
                    completion(nil)
                    self?.delegate?.onError(error)
                }
                else {
                    completion(imageHandler)
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalVideoCreated(videoTrack!)
                    }
                }
            }
        }
    }

    func stopVideoSharing() {
        if (getAVState().isVideoActive) {
            if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
                msChannel.setVideoState(false) { [weak self] error, videoTrack in
                    if let error = error {
                        self?.delegate?.onError(error)
                    }
                    else {
                        DispatchQueue.main.async {
                            (SMChannelsManager.shared.channel(for: .laserPointer) as? SMLaserPointerChannel)?.stopAllLaserPointerSessions()
                            (SMChannelsManager.shared.channel(for: .remoteControl) as? SMRemoteControlChannel)?.stopAllRemoteControlSessions()
                            self?.delegate?.onLocalVideoStopped()
                        }
                    }
                }
            }
        }
        else {
            delegate?.onError(SMError(code: .mediaTrackError, message:"Video has been stopped already"))
        }
    }
    
    func stopAudioSharing() {
        if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
            msChannel.setAudioState(false) { [weak self] error in
                if let error = error {
                    self?.delegate?.onError(error)
                }
                else {
                    DispatchQueue.main.async {
                        self?.delegate?.onLocalAudioStopped()
                    }
                }
            }
        }
    }
    
    func startAudioSharing() {
        if (getAVState().isAudioActive) {
            delegate?.onError(SMError(code: .mediaTrackError, message: "Audio is being shared already"))
        }
        else {
            if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
                msChannel.setAudioState(true) { [weak self] error in
                    if let error = error {
                        self?.delegate?.onError(error)
                    }
                    else {
                        DispatchQueue.main.async {
                            self?.delegate?.onLocalAudioCreated()
                        }
                    }
                }
            }
        }
    }

    func getVideoSourceDevice() -> AVCaptureDevice! {
        if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
            return msChannel.getVideoSourceDevice()
        } else {
            return nil
        }
    }
    
    func getParticipants() -> [SMParticipant] {
        if let participantsChannel = SMChannelsManager.shared.channel(for: .participants) as? SMParticipantsChannel {
            return participantsChannel.getParticipants()
        } else {
            return [SMParticipant]()
        }
    }

}
