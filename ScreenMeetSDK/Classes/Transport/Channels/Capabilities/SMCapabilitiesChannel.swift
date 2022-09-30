//
//  SMCapabilitiesChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 31.03.2021.
//

import Foundation

class SMCapabilitiesChannel: SMChannel {
    
    var name: SMChannelName = .capabilities
    
    func processEvent(_ message: SMChannelMessage) {
        
    }
    
    func buildState(from initialPayload: [String : Any]) {
        transport.webSocketClient.requestSet(for: name, data: [transport.webSocketClient.sid: ["remotecontrol": true, "laserpointer": true, "multistreaming": false]])
    }
}
