//
//  SMAudioStateTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 16.02.2021.
//

import UIKit

typealias SMAudioStateTransactionCompletion = (_ error: SMError?) -> Void

class SMAudioStateTransaction: SMTransaction {
    func run(_ state: Bool, _ completion: SMAudioStateTransactionCompletion? = nil) {
        
        let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        channel.setAudioState(state, completion)
    }
}
