//
//  SMTransportOptions.swift
//  ScreenMeet
//
//  Created by Ross on 15.01.2021.
//

import UIKit
import SocketIO

struct SMTransportOptions: Codable {
    var success: Bool
    var result: SMTransportOptionsResult
}

struct SMTransportOptionsResult: Codable {
    var inbound: SMTransportOptionsInOutbound
    var outbound: SMTransportOptionsInOutbound
    var routerRtpCapabilities: SMRTPCapabilities
}

struct SMTransportOptionsInOutbound: Codable {
    var id: String
    var appData: SMTransportOptionsInboundAppData
    var dtlsParameters: SMTransportOptionsDtlsParameters
    var iceCandidates: [SMTransportOptionsIceCandidate]
    var iceParameters: SMTransportOptionsIceParameters
    var iceServers: [SMTransportOptionsICEServer]
    var iceTransportPolicy: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["id"] = id
        data["appData"] = appData.socketRepresentation()
        data["dtlsParameters"] = dtlsParameters.socketRepresentation()
        var iceCandidatesArray = [SocketData]()
        for c in iceCandidates {
            iceCandidatesArray.append(c.socketRepresentation())
        }
        data["iceCandidates"] = iceCandidatesArray
        data["iceParameters"] = iceParameters.socketRepresentation()
        
        var iceServersArray = [SocketData]()
        for s in iceServers {
            iceServersArray.append(s.socketRepresentation())
        }
        data["iceServers"] = iceServersArray
        data["iceTransportPolicy"] = iceTransportPolicy
        return data
    }
}

struct SMTransportOptionsInboundAppData: Codable, SocketData {
    var cid: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["cid"] = cid
        return data
    }
}

struct SMTransportOptionsDtlsParameters: Codable, SocketData {
    var fingerprints: [SMDtlsParametersFingerPrint]
    var role: String
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(SMTransportOptionsDtlsParameters.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
    
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["role"] = role
        var array = [SocketData]()
        
        for f in fingerprints {
            array.append(f.socketRepresentation())
        }
        data["fingerprints"] = array
        return data
    }
}

struct SMDtlsParametersFingerPrint: Codable, SocketData {
    var algorithm: String
    var value: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["algorithm"] = algorithm
        data["value"] = value
        return data
    }
}

struct SMTransportOptionsIceCandidate: Codable, SocketData {
    private enum CodingKeys : String, CodingKey {
        case foundation, ip, port, priority, canidadateProtocol = "protocol", tcpType, canidadateType = "type"
    }
    
    var foundation: String
    var ip: String
    var port: Int
    var priority: Int
    var canidadateProtocol: String
    var tcpType: String?
    var canidadateType: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["foundation"] = foundation
        data["ip"] = ip
        data["priority"] = priority
        data["port"] = port
        data["protocol"] = canidadateProtocol
        if let tcpType = tcpType {
            data["tcpType"] = tcpType
        }
        data["type"] = canidadateType
        return data
    }
}

struct SMTransportOptionsIceParameters: Codable, SocketData {
    var iceLite: Bool
    var password: String
    var usernameFragment: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["iceLite"] = iceLite
        data["password"] = password
        data["usernameFragment"] = usernameFragment
        return data
    }
}

struct SMTransportOptionsICEServer: Codable, SocketData {
    var credential: String
    var urls: String
    var username: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["credential"] = credential
        data["urls"] = urls
        data["username"] = username
        return data
    }
}

class SMRTPCapabilities: Codable, SocketData {
    var codecs: [SMRTPCapabilitityCodec]
    var headerExtensions: [SMRTPCapabilityHeaderExtension]
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        var arrayOfCodecs = [SocketData]()
        
        for c in codecs {
            arrayOfCodecs.append(c.socketRepresentation())
        }
        data["codecs"] = arrayOfCodecs
        
        var arrayOfHeaderExtensions = [SocketData]()
        
        for e in headerExtensions {
            arrayOfHeaderExtensions.append(e.socketRepresentation())
        }
        data["headerExtensions"] = arrayOfHeaderExtensions

        return data
    }
}

struct SMRTPCapabilitityCodecRTCPFeedback: Codable, SocketData {
    
    private enum CodingKeys : String, CodingKey {
        case codecType = "type", parameter
    }
    
    var codecType: String
    var parameter: String
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["type"] = codecType
        data["parameter"] = parameter
        return data
    }
    
}

struct SMRTPCapabilitityCodecParameters: Codable, SocketData {
    var apt: Int?
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        if let apt = apt {
            data["apt"] = apt
        }
        return data
    }
}

struct SMRTPCapabilitityCodec: Codable, SocketData {
    var kind: String?
    var mimeType: String
    var clockRate: Int
    var preferredPayloadType: Int?
    var channels: Int?
    var parameters: SMRTPCapabilitityCodecParameters
    var rtcpFeedback: [SMRTPCapabilitityCodecRTCPFeedback]
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        if let kind = kind {
            data["kind"] = kind
        }
       
        data["mimeType"] = mimeType
        data["clockRate"] = clockRate
        
        if let preferredPayloadType = preferredPayloadType {
            data["preferredPayloadType"] = preferredPayloadType
        }
        
        if let channels = channels {
            data["channels"] = channels
        }
        data["parameters"] = parameters.socketRepresentation()
        var array = [SocketData]()
        
        for r in rtcpFeedback {
            array.append(r.socketRepresentation())
        }
        data["rtcpFeedback"] = array
        
        return data
    }
}

struct SMRTPCapabilityHeaderExtension: Codable, SocketData {
    var kind: String?
    var uri: String
    var direction: String?
    var preferredId: Int?
    var preferredEncrypt: Bool?
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        if let kind = kind {
            data["kind"] = kind
        }
        
        data["uri"] = uri
        
        if let direction = direction {
            data["direction"] = direction
        }
        
        if let preferredId = preferredId {
            data["preferredId"] = preferredId
        }
        
        if let preferredEncrypt = preferredEncrypt {
            data["preferredEncrypt"] = preferredEncrypt
        }
        
        return data
    }
    
}

struct SMRtpEncoding: Codable, SocketData {
    var ssrc: Int
    var dtx: Bool
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["ssrc"] = ssrc
        data["dtx"] = dtx
        return data
    }
}
