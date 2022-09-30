//
//  SMStartWebRTCTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit
import WebRTC
typealias StartWebRTCTransactionCompletion = (SMError?) -> Void

class SMStartWebRTCTransaction: SMTransaction {
    private var videoSourceDevice: AVCaptureDevice! = nil
    
    override init() {
    }
    
    func run(_ completion: @escaping StartWebRTCTransactionCompletion) {
        let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        let turnConfig = SMTurnConfiguration()
            
        mediasoupChannel.startTransportAndChannels(turnConfig, completion)
    }
}

