//
//  GetSettingsResponse.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import Foundation

struct SMGetChallengeResponse: SMResponse {
    var uuid: String
    var challengeDisplay: String
    var createdAt: String
}

extension SMGetChallengeResponse: Deserializable {
    init?(data: Data) {
        
        guard let response = try? JSONDecoder().decode(SMGetChallengeResponse.self, from: data) else { return nil }
        self = response
    }
}
