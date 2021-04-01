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
    
    weak var delegate: ScreenMeetDelegate?
    
    var isAudioEnabled: Bool {
        return ScreenMeet.getMediaState().isAudioActive
    }
    
    var isCameraEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .CAMERA
    }
    
    var isScreenShareEnabled: Bool {
        return ScreenMeet.getMediaState().isVideoActive && ScreenMeet.getMediaState().videoState == .SCREEN
    }
    
    var mainParticipantId: String?
    
    var localVideoTrack: RTCVideoTrack?
}

extension SMUserInterface: ScreenMeetDelegate {
    
    func onLocalAudioCreated() {
        NSLog("[ScreenMeet] Local user started audio")
        delegate?.onLocalAudioCreated()
    }
    
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack) {
        NSLog("[ScreenMeet] Local user started video")
        localVideoTrack = videoTrack
        delegate?.onLocalVideoCreated(videoTrack)
    }
    
    func onLocalVideoSourceChanged() {
        NSLog("[ScreenMeet] Video source for local video has changed")
        delegate?.onLocalVideoSourceChanged()
    }
    
    func onLocalVideoStopped() {
        NSLog("[ScreenMeet] Local user stopped video")
        delegate?.onLocalVideoStopped()
    }
    
    func onLocalAudioStopped() {
        NSLog("[ScreenMeet] Local user stopped audio")
        delegate?.onLocalAudioStopped()
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant joined: " + participant.name)
        delegate?.onParticipantJoined(participant)
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started video")
        delegate?.onParticipantVideoTrackCreated(participant)
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " started audio")
        delegate?.onParticipantAudioTrackCreated(participant)
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant left: " + participant.name)
        delegate?.onParticipantLeft(participant)
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.name + " has changed its media state (muted, resumed, etc) \(participant.avState)")
        delegate?.onParticipantMediaStateChanged(participant)
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant became active speaker: " + participant.name)
        delegate?.onActiveSpeakerChanged(participant)
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        NSLog("[ScreenMeet] Connection state: \(newState)")
        delegate?.onConnectionStateChanged(newState)        
    }
}
