//
//  GetSettingsResponse.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import Foundation

struct SMDiscoveryResponse: SMResponse {
    var session: Session!
}

struct Session: Decodable {
    var id: String
    var label: String
    var servers: SMDiscoveryServers
    
    var hostAuthToken: String?
    
    var turn: String
}

struct SMDiscoveryServers: Decodable {
    var live: SMDiscoveryLiveServer
}

struct SMDiscoveryLiveServer: Decodable {
    var id: Int
    var serverInstanceId: String
    var endpoint: String
    var region: String
}

extension SMDiscoveryResponse: Deserializable {
    init?(data: Data) {
        guard let session = try? JSONDecoder().decode(Session.self, from: data) else { return nil }
        self.session = session
    }
}
