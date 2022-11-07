//
//  SMCallerStateChannel.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit
import SocketIO

class SMCallerStateChannel: SMChannel {
    private var participantsCallerStates = [String: SMCallerState]()
    private lazy var myCallerState: SMCallerState = {
        var defaultState = SMCallerState()
        return defaultState
    }()
    
    /// SMChannel protocol
    
    var name: SMChannelName = .callerState
    
    func processEvent(_ message: SMChannelMessage) {
        let data = message.data
        
        if message.actionType == .added {
            guard let callerStates = data[1] as? [String: Any] else { return }
            for (participantId, callerStateDict) in callerStates {
                
                if isValidCallerState(callerStateDict as! [String: Any]) {
                    /* some one else's callerstate*/
                    if participantId != transport.webSocketClient.sid {
                        let callerState = SMCallerState(callerStateDict as! [String: Any], participantsCallerStates[participantId])
                        participantsCallerStates[participantId] = callerState
                        
                        let channel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                        channel.notifyParticipantsMediaStateChanged(participantId, callerState)
                    }
                    else {
                        /* Our callerstate*/
                        myCallerState = SMCallerState(callerStateDict as! [String: Any], participantsCallerStates[participantId])
                    }
                }
                
            }
        }
        else if message.actionType == .removed {
            guard let participantsIds = data[1] as? [String] else { return }
            
            for id in participantsIds {
                participantsCallerStates[id] = nil
            }
        }
    }
    
    func buildState(from initialPayload: [String: Any]) {
        for (participantId, callerStateDict) in initialPayload {
            let callerState = (callerStateDict as! [String: Any])["value"] as! [String: Any]
            if let sid = transport.webSocketClient.sid {
                if participantId == sid {
                    myCallerState = SMCallerState(callerState , participantsCallerStates[participantId])
                }else {
                    let callerState = SMCallerState(callerState , participantsCallerStates[participantId])
                    participantsCallerStates[participantId] = callerState
                }
            }
        }
    }
    
    /// Get state
    
    func getVideoEnabled() -> Bool {
        return myCallerState.videoEnabled
    }
    
    func getAudioEnabled() -> Bool {
        return myCallerState.audioEnabled
    }
    
    /// Outbound
    
    func setVideoState(_ isEnabled: Bool,  _ sourceType: String? = nil, _ completion: SMChannelOperationCompletion? = nil) {
        if let sid = transport.webSocketClient.sid{
            
            myCallerState.sourceType = sourceType ?? "camera"
            if sourceType == "screen_share" {
                myCallerState.screenEnabled = isEnabled
                myCallerState.videoEnabled = false
            }
            else {
                myCallerState.videoEnabled = isEnabled
                myCallerState.screenEnabled = false
            }
            
            myCallerState.outputEnabled = myCallerState.screenEnabled || myCallerState.videoEnabled
            
            myCallerState.source["width"] = UIScreen.main.bounds.width
            myCallerState.source["height"] = UIScreen.main.bounds.height
            myCallerState.source["aspectRatio"] = UIScreen.main.bounds.width / UIScreen.main.bounds.height
            myCallerState.source["frameRate"] = 16
            myCallerState.source["resize-mode"] = "none"
            myCallerState.source["cursor"] = "always"
            myCallerState.source["logicalSurface"] = true
            myCallerState.source["displaySurface"] = "monitor"
            myCallerState.source["deviceId"] = "iPhoneScreen1"
            
            let payload = [sid: myCallerState.socketRepresentation()]
            transport.webSocketClient.requestSet(for: name, data: payload)
            completion?(nil)
        }
        else {
            completion?(SMError(code: .socketError, message: "Socket sid is not availabale. Socket may be closed"))
        }
    }
    
    func setAudioState(_ isEnabled: Bool, _ completion: SMChannelOperationCompletion? = nil) {
        if let sid = transport.webSocketClient.sid {
            
            myCallerState.audioEnabled = isEnabled
            let payload = [sid: myCallerState.socketRepresentation()]
            
            if isEnabled {
                NSLog("[MSAudio] Set audio caller state")
            }
            transport.webSocketClient.requestSet(for: name, data: payload)
            completion?(nil)
        }
        else {
            completion?(SMError(code: .socketError, message: "Socket sid is not availabale. Socket may be closed"))
        }
    }
    
    func setInitialCallerState() {
        if let sid = transport.webSocketClient.sid{
            let payload = [sid: myCallerState.socketRepresentation()]
            transport.webSocketClient.requestSet(for: name, data: payload)
        }
    }
    
    func getCallerState(_ participantId: String) -> SMCallerState? {
        return participantsCallerStates[participantId]
    }
    
    func resetCallerState() {
        myCallerState = SMCallerState()
        participantsCallerStates = [String: SMCallerState]()
    }
    
    private func isValidCallerState(_ dict:[String: Any]) -> Bool {
        if dict["videoenabled"] as? Int != nil && dict["audioenabled"] as? Int != nil {
            return true
        }
        
        return false
    }
}
