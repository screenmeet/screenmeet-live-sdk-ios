//
//  SMHandshakeOptions.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit
import SocketIO

struct SMHandshakeOptions: SocketData {
    var overrideDupe: Bool?
    var reconnect: Bool
    
    func socketRepresentation() -> SocketData {
        var data: [String: Any] = ["reconnect": reconnect]
        
        if let overrideDupe = overrideDupe {
            data["overrideDupe"] = overrideDupe
        }
        
        return data
    }
}
