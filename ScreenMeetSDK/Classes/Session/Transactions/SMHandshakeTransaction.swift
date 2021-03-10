//
//  HandshakeTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

typealias HandshakeCompletion = (Session?, SMError?) -> Void
typealias ReconnectHandler = () -> Void
typealias ChannelMessageHandler = (SMChannelMessage) -> Void

class SMHandshakeTransaction: SMTransaction {
    private var delegate: SMDelegate?
    private var completion: HandshakeCompletion!
    private var reconnectHandler: ReconnectHandler!
    private var channelMessageHandler: ChannelMessageHandler!
    
    private var code: String!
    
    func withCode(_ code: String) -> SMHandshakeTransaction {
        self.code = code
        
        return self
    }
    
    func withDelegate(_ delegate: SMDelegate?) -> SMHandshakeTransaction {
        self.delegate = delegate
        return self
    }
    
    func withChannelMessageHandler(_ handler: @escaping ChannelMessageHandler) -> SMHandshakeTransaction {
        self.channelMessageHandler = handler
        
        return self
    }
    
    func withReconnectHandler(_ handler: @escaping ReconnectHandler) -> SMHandshakeTransaction {
        self.reconnectHandler = handler
        
        return self
    }
        
    func run(_ completion: @escaping HandshakeCompletion) {
        self.completion = completion
        
        guard let code = code else {
            self.completion(nil, SMError(code: .transactionInternalError, message: "No code/room id provided"))
            return
        }
        
        transport.restClient.disoveryServer(code) { response, error in
            if let error = error {
                self.completion(nil, SMError(code: .httpError, message: error.localizedDescription))
            }
            else {
                self.liveConnect(code, response!.session)
            }
        }
    }
    
    private func liveConnect(_ roomId: String,
                                      _ session: Session) {
        transport.restClient.connectServer(roomId, session.servers.live.endpoint) { response, error in
            if let error = error {
                self.completion(nil, SMError(code: .httpError, message: error.localizedDescription))
            }
            else {
                self.performSocketHandshake(session)
            }
        }
    }
    
    private func performSocketHandshake(_ session: Session) {
        transport.webSocketClient.setDelegate(delegate)
        
        transport.webSocketClient.setReconnectHandler(reconnectHandler)
        transport.webSocketClient.setChannelMessageHandler(channelMessageHandler)
        
        /* Assign teh delegate tp mediasoup channel so it can communicate back events*/
        let mediasoupChannel = transport.channelsManager.channel(for: .mediasoup) as! SMMediasoupChannel
        mediasoupChannel.setDelegate(delegate)
        
        transport.webSocketClient.connect(session.servers.live.endpoint, session.id) {  error in
            if let error = error {
                self.completion(nil, error)
                return
            }
            else {
                
                self.transport.webSocketClient.childConnect { initialPayload, sharedData, error in
                    if let error = error {
                        self.completion(nil, error)
                    }
                    else {
                        var authorizedSession = session
                        authorizedSession.hostAuthToken = initialPayload?.identity?.credential?.authToken
                        
                        SMChannelsManager.shared.buildInitialStates(sharedData!)
                        self.completion(authorizedSession, nil)
                    }
                }
            }
        }
    }
    
    
    deinit {
        NSLog("Transaction deallocated")
    }
}
