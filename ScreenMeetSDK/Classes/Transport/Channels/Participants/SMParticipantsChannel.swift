//
//  SMParticipantsChannel.swift
//  ScreenMeet
//
//  Created by Ross on 12.01.2021.
//

import UIKit

class SMParticipantsChannel {
    private var participants = [String: SMIdentityInfo]()
}

extension SMParticipantsChannel: SMChannel {
    
    var name: SMChannelName {
        return SMChannelName.participants
    }
    
    func buildState(from initialPayload: [String: Any]) {
        participants = [String: SMIdentityInfo]()
        
        for (participantId, identityInfoDict) in initialPayload {
            let identityInfo = (identityInfoDict as! [String: Any])["value"]
            parseParticipantsIdentityInfo(participantId, identityInfo as! [String: Any])
        }
    }
    
    func processEvent(_ message: SMChannelMessage) {
        let data = message.data
    
        if message.actionType == .added {
            guard let infoDict = data[1] as? [String: Any] else { return }
            for (participantId, identityInfoDict) in infoDict {
                parseParticipantsIdentityInfo(participantId, identityInfoDict as! [String : Any], true)
            }
        }
        else if message.actionType == .removed {
            guard let participantsIds = data[1] as? [String] else { return }
            
            for id in participantsIds {
                if let identity = participants[id] {
                    participants[id] = nil
                    
                    let channel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                    channel.removeParticipant(id, identity)
                }
            }
        }
    }
    
    func parseParticipantsIdentityInfo(_ participantId: String, _ identityInfo: [String: Any], _ isNewMessage: Bool = false) {
        SMSocketDataParser().parse(identityInfo) { [weak self] (identity: SMIdentityInfo?, error) in
            if let error = error {
                NSLog("error parsing participant's identity info: " + error.message)
            }
            else {
                if participantId == self?.transport.webSocketClient.sid {
                    //it's us, the participant id == our SID. Don't add to particpants
                }
                else {
                    self?.participants[participantId] = identity!
                    
                    if isNewMessage {
                        let channel = self?.transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                        channel.notifyParticipantJoined(participantId, identity!)
                    }
                    
                }
            }
        }
    }
    
    func getIdentity(_ participantId: String) -> SMIdentityInfo? {
        return participants[participantId]
    }
    
    func removeAllParticipants() {
        participants = [String: SMIdentityInfo]()
    }
    
    func getParticipants() -> [SMParticipant] {
        var allParticipants = [SMParticipant]()
        
        /* Combine callerstate(if available) and identoty ingo into one SMParticipant obejct*/
        
        let callerStatechannel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        
        let mediaSoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        for (id, identity) in participants {
            let callerState = callerStatechannel.getCallerState(id)
            var p = SMParticipant(id: id, identity: identity, callerState: callerState ?? SMCallerState())
            
            p = mediaSoupChannel.extendParticipantWithTracks(p)
            allParticipants.append(p)
        }
        
        return allParticipants
    }
}
