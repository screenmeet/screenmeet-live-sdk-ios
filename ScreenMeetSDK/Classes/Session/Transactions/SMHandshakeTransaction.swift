//
//  HandshakeTransaction.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

typealias ChallengeAnswerHandler = (String) -> Void
typealias HandshakeCompletion = (Session?, SMError?) -> Void
typealias ChannelMessageHandler = (SMChannelMessage) -> Void

public class SMChallenge {
    private var resolutionhandler: ChallengeAnswerHandler? = nil
    private var svg: String = ""
    
    init(_ svg: String, _ handler: @escaping ChallengeAnswerHandler) {
        self.svg = svg
        self.resolutionhandler = handler
    }
    
    public func solve(_ answer: String) {
        resolutionhandler?(answer)
    }
    
    public func getSvg() -> String {
        return svg
    }
}

class SMHandshakeTransaction: SMTransaction {
    private var eventsToLog = [SMLogRoomCodeUsageTransaction]()
    
    private let SESSION_PIN_LENGTH = 6
    private let TOO_MANY_INCORRECT_ATTEMPTS_REF_CODE = 169400
    
    private var channelMessageHandler: ChannelMessageHandler!
    
    private var code: String!
    private var localUserName: String = "Anonymous"
    private var reconnectWaitTimeout: Int = 15
    
    func withCode(_ code: String) -> SMHandshakeTransaction {
        self.code = code
        
        return self
    }
    
    func withLocalUserName(_ localUserName: String) -> SMHandshakeTransaction {
        self.localUserName = localUserName
        
        return self
    }
    
    func withChannelMessageHandler(_ handler: @escaping ChannelMessageHandler) -> SMHandshakeTransaction {
        self.channelMessageHandler = handler
        
        return self
    }
    
    func withReconnectWait(_ timeout: Int) -> SMHandshakeTransaction {
        self.reconnectWaitTimeout = timeout
        
        return self
    }
        
    func run(_ completion: @escaping HandshakeCompletion) {
        
        guard let code = code else {
            completion(nil, SMError(code: .transactionInternalError, message: "No code/room id provided"))
            return
        }
        
        guard !code.isEmpty else {
            completion(nil, SMError(code: .transactionInternalError, message: "Empty code/room id provided"))
            return
        }
        
        
        let numberCharacters = NSCharacterSet.decimalDigits.inverted
        
        // A pin
        if code.length == SESSION_PIN_LENGTH && code.rangeOfCharacter(from: numberCharacters) == nil {
            transport.restClient.disoverySessionByPin(code) { [self] response, error, errorPayload in
                if let error = error {
                    if let payload = errorPayload, payload["refcode"] as? Int == TOO_MANY_INCORRECT_ATTEMPTS_REF_CODE {
                        self.getCaptcha(code, payload["description"] as? String, completion)
                    }
                    else {
                        if let payload = errorPayload, let description = payload["description"] as? String {
                            completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: description))
                        }
                        else {
                            completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: error.localizedDescription))
                        }
                    }
                }
                else {
                    eventsToLog.append(SMLogRoomCodeUsageTransaction().witUsedPin(true))
                    
                    self.discovery(response!.id, completion)
                }
            }
        }
        // room code
        else {
            eventsToLog.append(SMLogRoomCodeUsageTransaction().withUsedSessionCode(true))
            discovery(code, completion)
        }
    }
    
    private func discovery(_ code: String, _ completion: @escaping  HandshakeCompletion) {
        transport.restClient.disoveryServer(code) { [self] response, error in
            if let error = error {
                completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: error.localizedDescription))
            }
            else {
                self.liveConnect(code, response!.session, completion)
            }
        }
    }
    
    private func liveConnect(_ roomId: String,
                             _ session: Session,
                             _ completion: @escaping  HandshakeCompletion) {
        transport.restClient.connectServer(roomId, session.servers.live.endpoint) { response, error in
            if let error = error {
                completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: error.localizedDescription))
            }
            else {
                self.performSocketHandshake(session, completion)
            }
        }
    }
    
    private func performSocketHandshake(_ session: Session, _ completion: @escaping HandshakeCompletion) {
        transport.webSocketClient.setChannelMessageHandler(channelMessageHandler)
        
        transport.webSocketClient.connect(session.servers.live.endpoint, session.id, reconnectWaitTimeout) {  error in
            if let error = error {
                completion(nil, error)
                return
            }
            else {
                self.transport.webSocketClient.childConnect(self.localUserName) { initialPayload, sharedData, error in
                    if let error = error {
                        completion(nil, error)
                    }
                    else {
                        var authorizedSession = session
                        authorizedSession.hostAuthToken = initialPayload?.identity?.credential?.authToken
                        
                        /* Flush all the events*/
                        for event in self.eventsToLog {
                            event.run()
                        }
                        
                        SMChannelsManager.shared.buildInitialStates(sharedData!)
                        completion(authorizedSession, nil)
                    }
                    
                    self.eventsToLog.removeAll()
                }
            }
        }
    }
    
    private func getCaptcha(_ pin: String, _ message: String?, _ completion: @escaping HandshakeCompletion) {
        self.transport.restClient.getChallenge { [self] challengeResponse, error in
            if let error = error {
                completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: error.localizedDescription))
            }
            else {
                let challenge = SMChallenge(challengeResponse!.challengeDisplay) { captcha in
                    self.transport.restClient.resolveChallenge(pin, challengeResponse!.uuid, captcha) { response, error, errorPayload in
                        
                        eventsToLog.append( SMLogRoomCodeUsageTransaction().withUsedCapcha(true))
                        
                        if let error = error {
                            if error.code == 400 {
                                completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: "The capture you entered is incorrect"))
                            }
                            else {
                                completion(nil, SMError(code: .httpError(SMHTTPCode(rawValue: error.code) ?? .unknown), message: errorPayload?["description"] as? String ?? "Challenge could not be resolved"))
                            }
                        }
                        else {
                            self.discovery(response!.id, completion)
                        }
                    }
                }
                completion(nil, SMError(code: .tooManyCaptchaAttempmts,
                                              message: message ?? "Too many recent connect attempts",
                                              challenge: challenge))
            }
        }
    }
    
    
    deinit {
        NSLog("Transaction deallocated")
    }
}
