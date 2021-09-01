//
//  SMLogEvent.swift
//  ScreenMeetSDK
//
//  Created by Ross on 26.07.2021.
//

import UIKit
import SocketIO

struct SMLogEvent: SocketData {
    var type: String
    var message: String
    
    func socketRepresentation() throws -> SocketData {
        var data = [String: Any]()
        data["type"] = type
        data["message"] = message
        return data
    }
}
