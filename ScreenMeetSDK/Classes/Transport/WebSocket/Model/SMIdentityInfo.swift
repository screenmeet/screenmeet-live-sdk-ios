//
//  SMIdentityInfo.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import Foundation
import SocketIO
import UIKit

enum SMIdentityInfoType: String, Codable {
    case SERVER = "SERVER"
    case AGENT = "AGENT"
    case GUEST = "GUEST"
    case HOST = "HOST"
}

/// Participant role
public enum SMIdentityInfoRole: Int, Codable {
    /// Server
    case SERVER = 2000
    
    /// Host
    case HOST = 1000
    
    /// Supervisor
    case SUPERVISOR = 500
    
    /// Agent
    case AGENT = 300
    
    /// Guest
    case GUEST = 100
    
    /// None (unknown)
    case NONE = 0
}

class SMIdentityInfoAuthCredential: Codable, SocketData {
    var reconnectToken: String?
    var authToken: String?
    
    public func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        
        if let reconnectToken = reconnectToken {
            data["reconnect_token"] = reconnectToken
        }
        
        if let authToken = authToken {
            data["auth_token"] = authToken
        }
        
        return data
    }
}

struct SMIdentityInfoUser: Codable, SocketData {
    //var id: Int
    public var name: String
    //var email: String
    
    public func socketRepresentation() -> SocketData {
        let data: [String: Any] = ["name" : name/*, "id": id, "email": email*/]
        return data
    }
}

enum SMServerType: String, Codable {
    case RECORDER = "RECORDER"
    case REPLICA = "REPLICA"
    case MASTER = "MASTER"
}

struct SMIdentityInfoServerInfo: Codable, SocketData {
    var id: String
    var serverType: SMServerType
    var instanceId: String
    var provider: String
    
    public func socketRepresentation() -> SocketData {
        let data: [String: Any] = ["id": id,
                                   "type": serverType.rawValue,
                                   "instance_id": instanceId,
                                   "provider": provider]
        
        return data
    }
}

enum SMIdentityInfoClientAppType: String, Codable {
    case browser = "browser"
    case native = "native"
}

struct SMIdentityInfoConnectionInfo: Codable {
    var id: String
    var ip: String
    var secure: Bool
    var connectedAt: Int64
}

struct SMIdentityInfoClientApp: Codable, SocketData {
    private enum CodingKeys : String, CodingKey {
        case clientType = "type", version, userAgent = "useragent", name;
    }
    
    var clientType: SMIdentityInfoClientAppType = .browser
    var version: String?
    var userAgent: String?
    var name: String?
    //var browser: [String: Any]?
    
    public func socketRepresentation() -> SocketData {
        var data: [String: Any] = ["type": clientType.rawValue]
        
        if let version = version {
            data["version"] = version
        }
        
        if let userAgent = userAgent {
            data["useragent"] = userAgent
        }
        
        if let name = name {
            data["name"] = name
        }
        
        /*if let browser = browser {
            data["browser"] = browser
        }*/
        
        return data
        
    }
}

/// Represents participant details
class SMIdentityInfo: Codable, SocketData {
    
    private enum CodingKeys : String, CodingKey {
        case id, deviceId = "device_id", deviceKey = "device_key", entityId, connectionInfo = "connection_info", identityType = "type", authenticated, role, credential, user, server, clientApp = "client_app"
    }
    
    public var id: String?
    public var deviceId: String?
    public var deviceKey: String?
    public var entityId: String?
    public var connectionInfo: SMIdentityInfoConnectionInfo!
    public var identityType: SMIdentityInfoType?
    public var authenticated: Bool?
    public var role: SMIdentityInfoRole?
           var credential: SMIdentityInfoAuthCredential?
    public var user: SMIdentityInfoUser?
    public var server: SMIdentityInfoServerInfo?
    public var clientApp: SMIdentityInfoClientApp?
    
    init() {
        self.deviceId = UIDevice.current.identifierForVendor!.uuidString
        self.identityType = .GUEST
        //self.role = .AGENT
        //self.credential = SMIdentityInfoAuthCredential()
        self.user = SMIdentityInfoUser(name: "Anonymous")
        self.clientApp = SMIdentityInfoClientApp(clientType: .native,
                                                 version: "1.0.0",
                                                 userAgent: "",
                                                 name: "v5-test-client")
    }
    
    public func socketRepresentation() -> SocketData {
        var data: [String: Any] = ["device_id": deviceId as Any,
                                   //"type": identityType!.rawValue
                                   //"role": role.rawValue,
                                   //"credential": credential.socketRepresentation(),
                                  ]
        
        if let id = id {
            data["id"] = id
        }
        
        if let deviceKey = deviceKey {
            data["device_key"] = deviceKey
        }
        
        if let entityId = entityId {
            data["entityId"] = entityId
        }
        
        if let connectionInfo = connectionInfo {
            data["connection_info"] = connectionInfo
        }
        
        if let authenticated = authenticated {
            data["authenticated"] = authenticated
        }
        
        if let server = server {
            data["server"] = server.socketRepresentation()
        }
        
        if let clientApp = clientApp {
            data["client_app"] = clientApp.socketRepresentation()
        }
        
        if let credential = credential {
            data["credential"] = credential.socketRepresentation()
        }
        
        if let user = user {
            data["user"] = user.socketRepresentation()
        }
        
        return data
        
    }
    
}
