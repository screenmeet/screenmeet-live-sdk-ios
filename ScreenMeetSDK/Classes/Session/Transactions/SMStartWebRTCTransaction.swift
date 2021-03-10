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
    private var turnUrl: String
    private var videoSourceDevice: AVCaptureDevice! = nil
    
    init(_ turnUrl: String, _ videoSourceDevice: AVCaptureDevice!) {
        self.turnUrl = turnUrl
        self.videoSourceDevice = videoSourceDevice
    }
    
    func run(_ completion: @escaping StartWebRTCTransactionCompletion) {
        let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        let turnConfig = SMTurnConfiguration(turnHostName: turnUrl)
            
        mediasoupChannel.startTransportAndChannels(turnConfig, videoSourceDevice, completion)
    }
}

