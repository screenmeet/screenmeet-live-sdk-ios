//
//  SMRemoteControlChannel.swift
//  Pods
//
//  Created by Ross on 09.09.2021.
//

import UIKit

class SMRemoteControlChannel: SMChannel {
    let service = SMRemoteControlService()
    
    var name: SMChannelName = .remoteControl
    
    func buildState(from initialPayload: [String : Any]) {
    }
    
    func processEvent(_ message: SMChannelMessage) {
        let data = message.data[1] as! [String: Any]
        
        if let event = parseEvent(data) {
            service.processEvent(event)
        }
    }
    
    func startRemoteControlSession(for id: String) throws {
       /* Do nothing. The service handles touch events if any, and does nothing if no events. No need to explicitly "start" it*/
    }
    
    func stopRemoteControlSession(for id: String) {
        /* Do nothing. The service handles touch events if any, and does nothing if no events. No need to explicitly "stop" it*/
    }
    
    private func parseEvent(_ data: [String: Any]) -> SMRemoteControlEvent? {
        if data["type"] as? String == "mouse" {
            return SMRemoteControlMouseEvent(data)
        }
        if data["type"] as? String == "keyboard" {
            return SMRemoteControlKeyboardEvent(data)
        }
        return nil
    }

}
