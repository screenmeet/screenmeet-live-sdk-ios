//
//  SMParticipant.swift
//  ScreenMeet
//
//  Created by Ross on 12.01.2021.
//

import UIKit
import WebRTC

/// Represents video call participant
public struct SMParticipant {
    
    /// UID of participant
    public var id: String

   var identity: SMIdentityInfo
    
    /// Participant name
    public var name: String {
        identity.user?.name ?? "noname"
    }

    /// Participant role HOST | GUEST
    public var role: SMIdentityInfoRole {
        identity.role ?? .NONE
    }

    /// Participant last connection time
    public var connectedAt: Int64 {
        identity.connectionInfo.connectedAt
    }

    var callerState: SMCallerState
    
    /// Participant sate. Mute/Unmute, Camera or screen shared etc. See `SMParticipantState`
    public var avState: SMParticipantMediaState {
        SMParticipantMediaState(callerState: self.callerState)
    }
    
    /// Returns Is participant talking now
    public var isTalking: Bool {
        callerState.talking
    }

    /// Participan's video track. Can be null if video is blocked by participant or not yet created  See `RTCVideoTrack`
    public var videoTrack: RTCVideoTrack?
    
    /// Participan's audio track. Can be null if aduio is blocked by participant or not yet created  See `RTCVideoTrack`
    public var aduioTrack: RTCAudioTrack?
}

/// Represents Audio and Video states of participant
public struct SMParticipantMediaState {

    var callerState: SMCallerState

    /// Video state
    public var videoState: VideoState {
        if (callerState.screenEnabled) {
            return .SCREEN
        }
        if (callerState.screenAnnotationEnabled) {
            return .ANNOTATION
        }
        if (callerState.videoEnabled) {
            return .CAMERA
        }
        return .NONE
    }
    
    /// Is Video stream active
    public var isVideoActive: Bool {
        videoState != .NONE
    }
    
    /// Is Image transfer enabled
    public var isScreenShareByImageTransfernOn: Bool {
        callerState.imageTransferEnabled
    }

    /// Audio state
    public var audioState: AudioState {
        return callerState.audioEnabled ? .MICROPHONE : .NONE
    }

    /// Is Audio stream active
    public var isAudioActive: Bool {
        audioState != .NONE
    }

    /// Video state
    public enum VideoState {
        
        /// Camera is shared
        case CAMERA

        /// Screen content is shared
        case SCREEN
        
        /// Screen annotation content is shared
        case ANNOTATION
        
        /// Video stream is not shared
        case NONE
    }

    /// Audio state
    public enum AudioState {
        
        /// Microphone audio is shared
        case MICROPHONE
        
        /// Audio stream is not shared
        case NONE
    }

}

