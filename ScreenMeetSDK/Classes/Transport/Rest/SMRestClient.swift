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
    
    public func disoveryServer(_ code: String,
                               completion: @escaping (SMDiscoveryResponse?, TransportError?) -> Void) {
        let discoveryRequest = SMDiscoveryRequest(code: code)
        
        service?.send(request: discoveryRequest) {
            (response: SMDiscoveryResponse?, error: TransportError?) in
            
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
            (response: SMConnectResponse?, error: TransportError?) in
            
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
}
