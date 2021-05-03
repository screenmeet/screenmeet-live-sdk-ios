//
//  GetSettingsRequest.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import UIKit

struct SMResolveChallengeRequest: SMRequest {
    var pin: String
    var answerUuid: String
    var answerValue: String
}

extension SMResolveChallengeRequest: HTTPGetRequest {
    
    var baseUrl: String {
        return "https://myhelpscreen.com"
    }
    
    var urlQueryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "challenge", value: answerUuid),
                URLQueryItem(name: "answer", value: answerValue)]
    }
    
    var additionalHeaders: [String: String]? {
        return nil
    }
    
    var relativePath: String {
        return "/api/v3/support/" + pin + "/metadata"
    }
}
