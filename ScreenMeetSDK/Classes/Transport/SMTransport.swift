//
//  SMTransport.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

struct SMTransport {
    let restClient = SMRestClient()
    let webSocketClient = SMWebSocketClient()
    let channelsManager = SMChannelsManager.shared
    
    static let shared = SMTransport()
    private init() { }
}
