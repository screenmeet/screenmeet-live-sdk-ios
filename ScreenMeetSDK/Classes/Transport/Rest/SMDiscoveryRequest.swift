//
//  GetSettingsRequest.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import UIKit

struct SMDiscoveryRequest: SMRequest {
     let code: String
}

extension SMDiscoveryRequest: HTTPPostRequest {
    var dataForHttpBody: Data? {
        let json: [String: Any] = ["code": code, /*"instance_id": "tk-win-1"*/ "server_tag": "beta"]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: json)
        return bodyData
    }
    
    var baseUrl: String {
        return ScreenMeet.config.endpoint.absoluteString
    }
    
    var urlQueryItems: [URLQueryItem]? {
        return nil
    }
    
    var additionalHeaders: [String: String]? {
        return ["mobile-api-key" : ScreenMeet.config.organizationKey]
    }
    
    var relativePath: String {
        return "v3/live/connect"
    }
}
