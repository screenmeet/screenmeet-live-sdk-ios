//
//  SMCallerStateChannel.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit
import SocketIO

class SMCallerStateChannel: SMChannel {
    /* Store callbacks here as they should be called as we get confirmation through pub*/
    private var audioStateChangeCompletion: SMChannelOperationCompletion? = nil
    private var videoStateChangeCompletion: SMChannelOperationCompletion? = nil
    
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
                        
                        /* call the previously stored callbacks if any*/
                        DispatchQueue.main.async { [self] in
                            audioStateChangeCompletion?(nil)
                            videoStateChangeCompletion?(nil)
                            
                            /* nil the callbacks just to be on the safe side to make sure they are called once*/
                            audioStateChangeCompletion = nil
                            videoStateChangeCompletion = nil
                        }
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
    
    func setVideoState(_ isEnabled: Bool, _ completion: SMChannelOperationCompletion? = nil) {
        if let sid = transport.webSocketClient.sid{
            videoStateChangeCompletion = completion
            
            myCallerState.videoEnabled = isEnabled
            let payload = [sid: myCallerState.socketRepresentation()]
            transport.webSocketClient.requestSet(for: name, data: payload)
        }
        else {
            completion?(SMError(code: .socketError, message: "Socket sid is not availabale. Socket may be closed"))
        }
    }
    
    func setAudioState(_ isEnabled: Bool, _ completion: SMChannelOperationCompletion? = nil) {
        if let sid = transport.webSocketClient.sid {
            audioStateChangeCompletion = completion
            
            myCallerState.audioEnabled = isEnabled
            let payload = [sid: myCallerState.socketRepresentation()]
            
            transport.webSocketClient.requestSet(for: name, data: payload)
        }
        else {
            completion?(SMError(code: .socketError, message: "Socket sid is not availabale. Socket may be closed"))
        }
    }
    
    func getCallerState(_ participantId: String) -> SMCallerState? {
        return participantsCallerStates[participantId]
    }
    
    private func isValidCallerState(_ dict:[String: Any]) -> Bool {
        if dict["videoenabled"] as? Int != nil && dict["audioenabled"] as? Int != nil {
            return true
        }
        
        return false
    }
}
