//
//  SMTurnConfiguration.swift
//  ScreenMeet
//
//  Created by Ross on 15.01.2021.
//

import UIKit
import SocketIO

struct SMTurnConfiguration: SocketData {
    var turnHostName: String
    
    func socketRepresentation() -> SocketData {
        var data: [String: Any] = [String: Any]()
        data["turnhostname"] = turnHostName
        return data
    }
}
