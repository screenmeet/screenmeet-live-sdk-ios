//
//  SMReconnectTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit

class SMDisconnectTransaction: SMTransaction {
    
    func run() {
        
        let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        mediasoupChannel.disconnect {
            self.transport.webSocketClient.disconnect(.leftCall)
        }
        
        SMResetChannelsStateTransaction().run()
    }
}

