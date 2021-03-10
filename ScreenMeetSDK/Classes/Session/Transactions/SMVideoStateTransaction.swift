//
//  SMVideoStateTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 16.02.2021.
//

import UIKit

typealias SMVideoStateTransactionCompletion = (_ error: SMError?) -> Void

class SMVideoStateTransaction: SMTransaction {
    func run(_ state: Bool, _ completion: SMVideoStateTransactionCompletion? = nil) {
        
        let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        channel.setVideoState(state, completion)
    }
}
