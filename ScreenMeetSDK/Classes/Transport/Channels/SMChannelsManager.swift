//
//  SMChannelsManager.swift
//  ScreenMeet
//
//  Created by Ross on 12.01.2021.
//

import UIKit

class SMChannelsManager: NSObject {
    private var channels = [SMChannelName: SMChannel]()
    
    func channel(for name: SMChannelName) -> SMChannel? {
        if let channel = channels[name] {
            return channel
        }
        
        var channel: SMChannel!
        
        switch name {
        case .participants:
            channel = SMParticipantsChannel()
        case .rtc:
            channel = SMRtcChannel()
        case .mediasoup:
            channel = SMMediasoupChannel()
        case .callerState:
            channel = SMCallerStateChannel()
        case .capabilities:
            channel = SMCapabilitiesChannel()
        case .laserPointer:
            channel = SMLaserPointerChannel()
        default:
            channel = nil
        }
        
        channels[name] = channel
        return channel
    }
    
    func process(_ channelMessage: SMChannelMessage) {
        let targetChannel = channel(for: channelMessage.channelName)
        targetChannel?.processEvent(channelMessage)
    }
    
    func buildInitialStates(_ sharedData: [String: Any]) {        
        for (channelNameString, channelInitialState) in sharedData {
            let initialState = channelInitialState as! [String:Any]
            
            if channelNameString == "callerstate" {
                NSLog("callerstate")
            }
            let data = initialState["data"]  as! [String : Any]
            if let channelName =  SMChannelName(rawValue: channelNameString) {
                let theChannel = channel(for: channelName)
                theChannel?.buildState(from: data)
            }
        }
    }
    
    static let shared = SMChannelsManager()
    private override init() { }

}
