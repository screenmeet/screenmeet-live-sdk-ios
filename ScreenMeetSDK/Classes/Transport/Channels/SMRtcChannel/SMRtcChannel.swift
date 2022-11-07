//
//  SMRtcChannel.swift
//  ScreenMeet
//
//  Created by Ross on 15.01.2021.
//

import UIKit

class SMRtcChannel: SMChannel {
    var name: SMChannelName = .participants
    
    func processEvent(_ message: SMChannelMessage) {
        let data = message.data
        guard let message = data[1] as? [String: Any] else { return }
        
        if let type = message["type"] as? String {
            let payload = message["data"] as! [String: Any]
            
            if type == "track-available" {
                SMSocketDataParser().parse(payload) { [weak self] (message: SMNewTrackAvailableMessage?, error) in
                    if let error = error {
                        ScreenMeet.delegate?.onError(SMError(code: .transactionInternalError, message: "Could not parse incoming \"track-available\" message in \"rtc\" channel.\nMessage: \n\(payload)"))

                        NSLog("error parsing consumer: " + error.message)
                    }
                    else {
                        let channel = self?.transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                        channel.consumeTrack(message!)
                    }
                }
            }
        }
        
        if let id = message["activeSpeakerId"] as? String {
            if id != transport.webSocketClient.sid {
                let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                mediasoupChannel.setNewActiveSpeakerIdToSend(id)
            }
        }
    }
    
    func buildState(from initialPayload: [String: Any]) {
        NSLog("RTC build initial state")
        
        if let activeSpeakerDict = initialPayload["activeSpeakerId"] as? [String: Any] {
            if let id = activeSpeakerDict["value"] as? String {
                if id != transport.webSocketClient.sid {
                    let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
                    mediasoupChannel.setNewActiveSpeakerIdToSend(id)
                }
            }
        }
    }
    
}
