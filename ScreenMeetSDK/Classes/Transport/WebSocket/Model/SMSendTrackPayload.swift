//
//  SMSendTrackPayload.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit
import SocketIO

struct SMSendTrackPayload: Codable, SocketData {
    var transportId: String
    var appData: [String: String]?
    var kind: String
    var rtpParameters: SMTrackRtpParameters?
    var paused: Bool
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["transportId"] = transportId
        data["kind"] = kind
        data["paused"] = paused
        
        if let appData = appData {
            data["appData"] = appData.socketRepresentation()
        }
        
        if let rtpParameters = rtpParameters {
            data["rtpParameters"] = rtpParameters.socketRepresentation()
        }
        
        return data
    }
}

struct SMTrackRtpParameters: Codable, SocketData {
    var codecs: [SMSendTrackCodec]
    var encodings: [SMSendTrackRtpEncoding]
    var headerExtensions: [SMSendTrackHeaderExtension]
    var mid: String
    var rtcp: SMSendTrackRtcp
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(SMTrackRtpParameters.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        var codecsArray = [SocketData]()
        for c in codecs { codecsArray.append(c.socketRepresentation()) }
        data["codecs"] = codecsArray
        
        var encodingsArray = [SocketData]()
        for e in encodings { encodingsArray.append(e.socketRepresentation()) }
        data["encodings"] = encodingsArray
        
        var headerExtensionsArray = [SocketData]()
        for h in headerExtensions { headerExtensionsArray.append(h.socketRepresentation()) }
        data["headerExtensions"] = headerExtensionsArray
        
        data["mid"] = mid
        data["rtcp"] = rtcp.socketRepresentation()
        
        return data
    }
}

struct SMSendTrackCodec: Codable, SocketData {
    var channels: Int?
    var clockRate: Int
    var mimeType: String
    var parameters: [String: Int]
    var payloadType: Int
    var rtcpFeedback: [SMRTPCapabilitityCodecRTCPFeedback]
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        if let channels = channels {
            data["channels"] = channels
        }
        
        data["clockRate"] = clockRate
        data["mimeType"] = mimeType
        data["parameters"] = parameters
        data["payloadType"] = payloadType
        
        var array = [SocketData]()
        
        for r in rtcpFeedback {
            array.append(r.socketRepresentation())
        }
        data["rtcpFeedback"] = array
        return data
    }
}

struct SMSendTrackHeaderExtension: Codable, SocketData {
    var encrypt: Bool
    var id: Int
    var parameters: [String: String]
    var uri: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["encrypt"] = encrypt
        data["id"] = id
        data["parameters"] = parameters
        data["uri"] = uri
        
        return data
    }
}

struct SMSendTrackRtpEncoding: Codable, SocketData {
    var ssrc: Int?
    var active: Bool?
    var dtx: Bool?
    var maxBitrate: Int64?
    var networkPriority: Int?
    var rid: String?
    
    var scalabilityMode: String?
    var scaleResolutionDownBy: Double?
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        if let ssrc = ssrc {
            data["ssrc"] = ssrc
        }
        
        if let active = active {
            data["active"] = active
        }
        
        if let dtx = dtx {
            data["dtx"] = dtx
        }
        
        if let maxBitrate = maxBitrate {
            data["maxBitrate"] = maxBitrate
        }
        
        if let networkPriority = networkPriority {
            data["networkPriority"] = networkPriority
        }
        
        if let rid = rid {
            data["rid"] = rid
        }
        
        if let scalabilityMode = scalabilityMode {
            data["scalabilityMode"] = scalabilityMode
        }
        
        if let scaleResolutionDownBy = scaleResolutionDownBy {
            data["scaleResolutionDownBy"] = scaleResolutionDownBy
        }
        
        return data
    }
}

struct SMSendTrackRtcp: Codable, SocketData {
    var mux: Bool?
    var cname: String
    var reducedSize: Bool?
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["mux"] = mux
        
        data["cname"] = cname
        
        data["reducedSize"] = reducedSize
        return data
    }
}
