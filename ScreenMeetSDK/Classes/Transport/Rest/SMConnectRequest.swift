//
//  GetSettingsRequest.swift
//  EquifyCRM
//
//  Created by Apple on 7/6/18.
//  Copyright © 2018 Maliwan. All rights reserved.
//

import UIKit

struct SMConnectRequest: SMRequest {
    let roomId: String
    let serverUrl: String
}

extension SMConnectRequest: HTTPPostRequest {
    var dataForHttpBody: Data? {
        let json: [String: Any] = ["roomId": roomId, "server_tag": "beta" /*"instance_id": "tk-win-1"*/]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: json)
        return bodyData
    }
    
    var baseUrl: String {
        return serverUrl
    }
    
    var urlQueryItems: [URLQueryItem]? {
        return nil
    }
    
    var additionalHeaders: [String: String]? {
        return nil
    }
    
    var relativePath: String {
        return "connect"
    }
}
