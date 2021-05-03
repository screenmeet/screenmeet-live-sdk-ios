//
//  GetSettingsResponse.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import Foundation

struct SMDiscoverySessionByPinResponse: SMResponse {
    var id: String
    var type: String
    var status: String
    var userDescription: String
    var expiresAt: String
    var OrganizationId: Int
}

extension SMDiscoverySessionByPinResponse: Deserializable {
    init?(data: Data) {
        
        guard let response = try? JSONDecoder().decode(SMDiscoverySessionByPinResponse.self, from: data) else { return nil }
        self = response
    }
}
