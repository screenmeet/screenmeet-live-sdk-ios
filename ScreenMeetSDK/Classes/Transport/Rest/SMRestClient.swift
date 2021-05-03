//
//  DDEquifyAPI.swift
//  EquifyCRM
//
//  Created by Apple on 6/25/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import UIKit

class SMRestClient: NSObject {
    private lazy var service: SMRequestService? = {
        let requestService = SMRequestHTTPService()
        return requestService
    }()
    
    public func disoverySessionByPin(_ pin: String,
                                completion: @escaping (SMDiscoverySessionByPinResponse?, TransportError?, ErrorPayload?) -> Void) {
        let discoveryRequest = SMDiscoverySessionByPinRequest(pin: pin)
        
        service?.send(request: discoveryRequest) {
            (response: SMDiscoverySessionByPinResponse?, error: TransportError?, errorPayload: ErrorPayload?) in
            
            if let response = response {
                completion(response, nil, nil)
            } else {
                completion(nil, error, errorPayload)
            }
        }
    }
    
    public func getChallenge(completion: @escaping (SMGetChallengeResponse?, TransportError?) -> Void) {
        let getChallengeRequest = SMGetChallengeRequest()
        
        service?.send(request: getChallengeRequest) {
            (response: SMGetChallengeResponse?, error: TransportError?, errorPayload: ErrorPayload?) in
            
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func resolveChallenge(_ pin: String,
                                 _ answerUuid: String,
                                 _ answerValue: String,
                                 _ completion: @escaping (SMDiscoverySessionByPinResponse?, TransportError?, ErrorPayload?) -> Void) {
        let resolveChallengeRequest = SMResolveChallengeRequest(pin: pin,
                                                                answerUuid: answerUuid,
                                                                answerValue: answerValue)
        
        service?.send(request: resolveChallengeRequest) {
            (response: SMDiscoverySessionByPinResponse?, error: TransportError?, errorPayload: ErrorPayload?) in
            
            if let response = response {
                completion(response, nil, nil)
            } else {
                completion(nil, error, errorPayload)
            }
        }
    }
    
    public func disoveryServer(_ code: String,
                               completion: @escaping (SMDiscoveryResponse?, TransportError?) -> Void) {
        let discoveryRequest = SMDiscoveryRequest(code: code)
        
        service?.send(request: discoveryRequest) {
            (response: SMDiscoveryResponse?, error: TransportError?, errorPayload: ErrorPayload?) in
            
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func connectServer(_ roomId: String,
                              _ serverUrl: String,
                              completion: @escaping (SMConnectResponse?, TransportError?) -> Void) {
        let connectRequest = SMConnectRequest(roomId: roomId, serverUrl: serverUrl)
        
        service?.send(request: connectRequest) {
            (response: SMConnectResponse?, error: TransportError?, errorPayload: ErrorPayload?) in
            
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
}
