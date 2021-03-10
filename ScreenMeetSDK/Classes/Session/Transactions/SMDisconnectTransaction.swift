//
//  SMReconnectTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit

class SMDisconnectTransaction: SMTransaction {
    private var completion: SMDisconnectCompletion!
    
    func run(_ completion: @escaping SMDisconnectCompletion) {
        transport.webSocketClient.diconnect()
        
        let channel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        channel.disconnect(completion)
    }
}
