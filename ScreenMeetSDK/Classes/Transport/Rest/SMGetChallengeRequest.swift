//
//  GetSettingsRequest.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import UIKit

struct SMGetChallengeRequest: SMRequest {
}

extension SMGetChallengeRequest: HTTPGetRequest {
    
    var baseUrl: String {
        return "https://myhelpscreen.com"
    }
    
    var urlQueryItems: [URLQueryItem]? {
        return nil
    }
    
    var additionalHeaders: [String: String]? {
        return nil
    }
    
    var relativePath: String {
        return "/api/v3/support"
    }
}
