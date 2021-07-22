//
//  SMChannel.swift
//  ScreenMeet
//
//  Created by Ross on 12.01.2021.
//

import UIKit

enum SMChannelName: String {
    case mediasoup          = "mediasoup"
    case participants       = "participants"
    case callerState        = "callerstate"
    case rtc                = "rtc"
    
    case chat               = "chat"
    case connections        = "connections"
    case janus              = "janus" // seems to not exist any more in the mediasoup environment...
    
    case roomSettings       = "roomsettings"
    case state              = "state"
    case streamSettings     = "streamsettings"
    case system             = "system"
    case viewers            = "viewers"
    case laserPointer       = "lp"
    case permissionRequests = "permission_requests"
    case permissionGrants   = "permission_grants"
    
    case capabilities       = "capabilities"
}

typealias SMChannelOperationCompletion = (_ error: SMError?) -> Void

protocol SMChannel: class {
    var name: SMChannelName { get }
    func processEvent(_ message: SMChannelMessage)
    
    func buildState(from initialPayload: [String: Any])
}

extension SMChannel {
    var transport: SMTransport {
        return SMTransport.shared
    }
}

