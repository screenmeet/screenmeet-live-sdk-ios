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
        var json: [String: Any] = ["code": code, /*"instance_id": "tk-win-1"*/ "server_tag": "beta"]
        if let oKey = ScreenMeet.config.organizationKey {
            json["organisationKey"] = oKey
        }
        
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
        return nil
    }
    
    var relativePath: String {
        return "v3/live/connect"
    }
}
