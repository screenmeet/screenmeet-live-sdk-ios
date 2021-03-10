//
//  SMCallerStateChannel.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit
import SocketIO

/// Represents participant state
public struct SMCallerState: SocketData {
    public var audioEnabled: Bool = false
    public var outputEnabled: Bool = false
    public var videoEnabled: Bool = false
    public var screenEnabled: Bool = false
    public var sourceType: String = "cam"
    public var talking: Bool = false
    
    init() {
        
    }
    
    init(_ socketData: [String: Any], _ currentState: SMCallerState?) {
        if let audioEnabled = socketData["audioenabled"] as? Bool { self.audioEnabled = audioEnabled }
        else { self.audioEnabled = currentState?.audioEnabled ?? false}
        
        if let outputEnabled = socketData["outputenabled"] as? Bool { self.outputEnabled = outputEnabled }
        else { self.outputEnabled = currentState?.outputEnabled ?? false}
        
        if let videoEnabled = socketData["videoenabled"] as? Bool { self.videoEnabled = videoEnabled }
        else { self.videoEnabled = currentState?.videoEnabled ?? false}
        
        if let screenEnabled = socketData["screenenabled"] as? Bool { self.screenEnabled = screenEnabled }
        else { self.screenEnabled = currentState?.screenEnabled ?? false}
        
        if let sourceType = socketData["sourceType"] as? String { self.sourceType = sourceType }
        else { self.sourceType = currentState?.sourceType ?? "cam"}
        
        if let talking = socketData["talking"] as? Bool { self.talking = talking }
        else { self.talking = currentState?.talking ?? false}
    }
    
    public func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["audioenabled"]  = audioEnabled
        data["outputenabled"] = outputEnabled
        data["videoenabled"] = videoEnabled
        data["screenenabled"] = screenEnabled
        data["sourceType"] = sourceType
        data["talking"] = talking
        return data
    }
}
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
            for (participantId, callerState) in callerStates {
                /* some one else's callerstate*/
                if participantId != transport.webSocketClient.sid {
                    let callerState = SMCallerState(callerState as! [String: Any], participantsCallerStates[participantId])
                    participantsCallerStates[participantId] = callerState
                    
                    let channel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                    channel.notifyParticipantsMediaStateChanged(participantId, callerState)
                }
                else {
                    /* Our callerstate*/
                    myCallerState = SMCallerState(callerState as! [String: Any], participantsCallerStates[participantId])
                    
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
}
