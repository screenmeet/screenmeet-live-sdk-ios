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

    /// Participant sate. Mute/Unmute, Camera or screen shared etc. See `SMCallerState`
    public var callerState: SMCallerState
    
    /// Participan's video track. Can be null if video is blocked by participant or not yet created  See `RTCVideoTrack`
    public var videoTrack: RTCVideoTrack?
    
    /// Participan's audio track. Can be null if aduio is blocked by participant or not yet created  See `RTCVideoTrack`
    public var aduioTrack: RTCAudioTrack?
}
