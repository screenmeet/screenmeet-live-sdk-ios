//
//  SMEncodingsBuilder.swift
//  ScreenMeet
//
//  Created by Ross on 22.02.2021.
//

import UIKit
import WebRTC

class SMEncodingsBuilder: NSObject {
    func defaultSimulcastEncodings() -> [RTCRtpEncodingParameters] {
        var encodings: Array = Array<RTCRtpEncodingParameters>.init()
        
        let encoding1 = RTCRtpEncodingParameters()
        encoding1.isActive = true
        encoding1.rid = "l"
        encoding1.maxBitrateBps = 128000
        encoding1.minBitrateBps = 0
        encoding1.numTemporalLayers = 1
        encoding1.scaleResolutionDownBy = 4
        encoding1.bitratePriority = 1.0
        encoding1.networkPriority = .medium
        encodings.append(encoding1)
        
        let encoding2 = RTCRtpEncodingParameters()
        encoding2.isActive = true
        encoding2.rid = "m"
        encoding2.maxBitrateBps = 1000000
        encoding2.minBitrateBps = 0
        encoding2.numTemporalLayers = 1
        encoding2.scaleResolutionDownBy = 2
        encoding2.bitratePriority = 1.0
        encoding2.networkPriority = .low
        encodings.append(encoding2)
        
        let encoding3 = RTCRtpEncodingParameters()
        encoding3.isActive = true
        encoding3.rid = "h"
        encoding3.maxBitrateBps = 3000000
        encoding3.minBitrateBps = 0
        encoding3.numTemporalLayers = 1
        encoding3.scaleResolutionDownBy = 1
        encoding3.bitratePriority = 1.0
        encoding3.networkPriority = .low
        encodings.append(encoding3)
        
        return encodings
    }
}
