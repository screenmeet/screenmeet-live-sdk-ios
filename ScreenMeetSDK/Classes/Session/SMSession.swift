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

/// ScreenMeet disconnection callback
public typealias SMDisconnectCompletion = (_ error: SMError?) -> Void

/// Protocol to handle session events
public protocol ScreenMeetDelegate: class {
    
    /// on Audio stream created
    func onLocalAudioCreated()
    
    /// on Local Video stream created
    /// - Parameter videoTrack: Can be used to preview local video. See `RTCVideoTrack`
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack)
    
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
}

class SMSession: NSObject {
    weak var delegate: ScreenMeetDelegate?
    
    private var connectCompletion: SMConnectCompletion? = nil
    private var session: Session!
    
    /// Connect to the room
    /// - Parameter code: The string code of the room
    /// - Parameter config: Initial session configuration. See `SMSessionConfig`
    func connect(_ code: String,
                 _ videoSourceDevice: AVCaptureDevice,
                 _ completion: @escaping SMConnectCompletion) {
        
            self.connectCompletion = completion
        
            SMHandshakeTransaction()
            .withCode(code)
            .withDelegate(delegate)
            .withReconnectHandler({ [weak self] in self?.reconnect() })
            .withChannelMessageHandler { [weak self] channelMessage in
                self?.processIncomingChannelMessage(channelMessage)
            }.run { [weak self] session, error in
                if let error = error {
                    self?.connectCompletion?(SMError(code: .httpError, message: "Could not connect to server. " + error.message))
                }
                else {
                    self?.session = session
                    self?.startWebRTC(session!.turn, videoSourceDevice)
                }
        }
    }
    
    /// Disconnect, cancel all tracks, cleanup data
    func disconnect(_ completion: @escaping SMDisconnectCompletion) {
        SMDisconnectTransaction().run(completion)
    }
    
    func toggleLocalVideo() {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        
        var state = channel.getVideoEnabled()
        state = !state
        channel.setVideoState(state)
        
        SMVideoStateTransaction().run(state) { [weak self] error in
            if let error = error {
                NSLog("Could not toggle local video: ", error.message)
                //Could not toggle state of local video, hit some onError in delegate
            }
            else {
                DispatchQueue.main.async {
                    if !state {
                        self?.delegate?.onLocalVideoStopped()
                    }
                    // state resumed will be delivered via onLocalVideoCreated later
                }
            }
        }
    }
    
    func toggleLocalAudio() {
        let channel = SMChannelsManager.shared.channel(for: .mediasoup) as! SMMediasoupChannel
        var state = channel.getAudioEnabled()
        state = !state
        channel.setAudioState(state)
        
        SMAudioStateTransaction().run(state) { [weak self] error in
            if let error = error {
                NSLog("Could not toggle lcoal video: " + error.message)
                //Could not toggle state of local video, hit some onError in delegate
            }
            else {
                DispatchQueue.main.async {
                    if !state {
                        self?.delegate?.onLocalAudioStopped()
                    }
                    // state resumed will be delivered via onLocalAudioCreated later
                }
                
            }
        }
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
    
    private func startWebRTC(_ turnUrl: String, _ videoSourceDevice: AVCaptureDevice!) {
        SMStartWebRTCTransaction(turnUrl, videoSourceDevice)
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
        SMReconnectTransaction().run { session, error in
            if let error = error { NSLog("SMError: " + error.message) }
            else {
                self.session = session
            }
        }
    }
    
    /// Channels messaging
    
    private func processIncomingChannelMessage(_ message: SMChannelMessage) {
        SMChannelsManager.shared.process(message)
    }
    
}

extension SMSession {
    
    func changeVideoSource(_ to: ScreenMeet.VideoSourceType, _ completionHandler: SMCaptureCompletion? = nil) {
        var newDevice: AVCaptureDevice! = nil
        switch to {
        case .backCamera:
            newDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        case .frontCamera:
            newDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
        default:
            newDevice = nil
        }
        self.changeVideoSourceDevice(newDevice, completionHandler)
    }
    
    func changeVideoSourceDevice(_ to: AVCaptureDevice!, _ completionHandler: SMCaptureCompletion? = nil) {
        if let msChannel = SMChannelsManager.shared.channel(for: .mediasoup) as? SMMediasoupChannel {
            msChannel.changeCapturer(to, completionHandler: completionHandler)
        } else {
            completionHandler?(SMError(code: .capturerInternalError, message: "No MediaSoup channel"))
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
