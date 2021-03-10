//
//  GetSettingsResponse.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import Foundation

struct SMConnectResponse: SMResponse {
    var success: Bool
}

extension SMConnectResponse: Deserializable {
    init?(data: Data) {
        
        guard let response = try? JSONDecoder().decode(SMConnectResponse.self, from: data) else { return nil }
        self = response
    }
}
