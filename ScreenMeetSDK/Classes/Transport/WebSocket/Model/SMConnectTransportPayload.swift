//
//  SMConnectTransportPayload.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit
import SocketIO
struct SMConnectTransportPayload: Codable, SocketData {
    private enum CodingKeys : String, CodingKey {
        case transportId, transportType = "type", dtlsParameters
    }
    
    var transportId: String
    var transportType: String
    var dtlsParameters: SMTransportOptionsDtlsParameters
    
    
    func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["transportId"] = transportId
        data["type"] = transportType
        data["dtlsParameters"] = dtlsParameters.socketRepresentation()
        return data
    }

}
