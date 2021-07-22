//
//  SMCapabilitiesChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 31.03.2021.
//

import Foundation

class SMCapabilitiesChannel: SMChannel {
    
    var name: SMChannelName = .capabilities
    
    func processEvent(_ message: SMChannelMessage) { }
    
    func buildState(from initialPayload: [String : Any]) {
        let width = Int(UIScreen.main.bounds.width)
        let height = Int(UIScreen.main.bounds.height)
        transport.webSocketClient.requestSet(for: name, data: [transport.webSocketClient.sid: ["laserpointer": true, "sourceresolution": "{\(width)}x{\(height)}"]])
    }
}
