//
//  SMNewTrackAvailableMessage.swift
//  ScreenMeet
//
//  Created by Ross on 22.01.2021.
//

import UIKit

struct SMNewTrackAvailableMessage: Codable {
    var producerCid: String
    var consumerParams: SMTrackConsumerParams
}

struct SMTrackConsumerParams: Codable {
    var id: String
    var kind: String
    var producerId: String
    var producerPaused: Bool
    var rtpParameters: SMTrackRtpParameters
    var type: String
}


