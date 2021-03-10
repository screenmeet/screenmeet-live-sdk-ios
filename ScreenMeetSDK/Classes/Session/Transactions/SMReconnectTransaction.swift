//
//  SMReconnectTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit

typealias ReconnectCompletion = (Session?, SMError?) -> Void

class SMReconnectTransaction: SMTransaction {
    private var completion: ReconnectCompletion!
    
    func run(_ completion: ReconnectCompletion) {
        
    }
    
    private func performSocketHandshake(_ session: Session) {
        transport.webSocketClient.connect(session.servers.live.endpoint, session.id) {  error in
            if let error = error {
                self.completion(nil, error)
                return
            }
            else {
                self.transport.webSocketClient.childConnect { initialPayload, sharedData, error in
                    
                    var authorizedSession = session
                    authorizedSession.hostAuthToken = initialPayload?.identity?.credential?.authToken
                    
                    self.completion(session, nil)
                }
            }
        }
    }
}
