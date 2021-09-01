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
        case clientType = "type", version, model = "model", os, name;
    }
    
    var clientType: SMIdentityInfoClientAppType = .native
    var version: String?
    var name: String?
    var model: String?
    var os: String?
    
    public func socketRepresentation() -> SocketData {
        var data: [String: Any] = ["type": clientType.rawValue]
        
        if let version = version {
            data["version"] = version
        }
        
        if let model = model {
            data["model"] = model
        }
        
        if let os = os {
            data["os"] = os
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
        
        var version = ""
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String, let releaseVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version = releaseVersion + "(\(buildNumber))"
        }
        
        self.clientApp = SMIdentityInfoClientApp(clientType: .native,
                                                 version: version,
                                                 name: "iOS-SDK-live",
                                                 model: modelName,
                                                 os: UIDevice.current.systemVersion)
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
    
    private let modelName: String = {
           var systemInfo = utsname()
           uname(&systemInfo)
           let machineMirror = Mirror(reflecting: systemInfo.machine)
           let identifier = machineMirror.children.reduce("") { identifier, element in
               guard let value = element.value as? Int8, value != 0 else { return identifier }
               return identifier + String(UnicodeScalar(UInt8(value)))
           }

           func mapToDevice(identifier: String) -> String {
               #if os(iOS)
               switch identifier {
               case "iPod5,1":                                 return "iPod touch (5th generation)"
               case "iPod7,1":                                 return "iPod touch (6th generation)"
               case "iPod9,1":                                 return "iPod touch (7th generation)"
               case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
               case "iPhone4,1":                               return "iPhone 4s"
               case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
               case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
               case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
               case "iPhone7,2":                               return "iPhone 6"
               case "iPhone7,1":                               return "iPhone 6 Plus"
               case "iPhone8,1":                               return "iPhone 6s"
               case "iPhone8,2":                               return "iPhone 6s Plus"
               case "iPhone8,4":                               return "iPhone SE"
               case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
               case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
               case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
               case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
               case "iPhone10,3", "iPhone10,6":                return "iPhone X"
               case "iPhone11,2":                              return "iPhone XS"
               case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
               case "iPhone11,8":                              return "iPhone XR"
               case "iPhone12,1":                              return "iPhone 11"
               case "iPhone12,3":                              return "iPhone 11 Pro"
               case "iPhone12,5":                              return "iPhone 11 Pro Max"
               case "iPhone12,8":                              return "iPhone SE (2nd generation)"
               case "iPhone13,1":                              return "iPhone 12 mini"
               case "iPhone13,2":                              return "iPhone 12"
               case "iPhone13,3":                              return "iPhone 12 Pro"
               case "iPhone13,4":                              return "iPhone 12 Pro Max"
               case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
               case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
               case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
               case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
               case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
               case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
               case "iPad11,6", "iPad11,7":                    return "iPad (8th generation)"
               case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
               case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
               case "iPad11,3", "iPad11,4":                    return "iPad Air (3rd generation)"
               case "iPad13,1", "iPad13,2":                    return "iPad Air (4th generation)"
               case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
               case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
               case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
               case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
               case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
               case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
               case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
               case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch) (1st generation)"
               case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
               case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch) (1st generation)"
               case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
               case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
               case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
               case "AppleTV5,3":                              return "Apple TV"
               case "AppleTV6,2":                              return "Apple TV 4K"
               case "AudioAccessory1,1":                       return "HomePod"
               case "AudioAccessory5,1":                       return "HomePod mini"
               case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
               default:                                        return identifier
               }
               #elseif os(tvOS)
               switch identifier {
               case "AppleTV5,3": return "Apple TV 4"
               case "AppleTV6,2": return "Apple TV 4K"
               case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
               default: return identifier
               }
               #endif
           }

           return mapToDevice(identifier: identifier)
       }()
}
