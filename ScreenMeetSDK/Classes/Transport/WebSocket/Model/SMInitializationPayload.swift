//
//  SMInitializationPayload.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit
import SocketIO

enum SMInitializationPayloadSharedObjectOptionsSync: String, Decodable {
    case eager = "eager"
    case lazy = "lazy"
    case none = "none"
}

struct SMInitializationPayloadErrorDescription: Decodable {
    private enum CodingKeys : String, CodingKey {
        case code, description, errorType = "type"
    }
    
    var code: Int
    var description: String
    var errorType: String
}

struct SMInitializationPayloadSharedObjectOptions: Decodable {
    var id: String
    var sync: SMInitializationPayloadSharedObjectOptionsSync //lazy or eager subscription model
    var serializeWrites: Bool //writes should happen in sequence via a queue
    var persistant : Bool //values get stored in memory - if not they just emit messages
    var durable: Bool? //gets backed up to durable storage / eg, serializable
    var autosubscribe: Bool //should clients automatically subscribe
    var noGlobalHooks: Bool?
    var presence: Bool? //only "update" writes are available which can only set the value to be that of the source id
    var removeonpresence: Bool? //similar to presence, but only does the departure clean-up for things keyed with the client id
    var ACL: [String: Int]
}

struct SMInitializationPayload: Decodable {
    var success: Bool
    var identity: SMIdentityInfo?
    //var sharedData: [String: Decodable]
    var manifest: [SMInitializationPayloadSharedObjectOptions]?
    var error: SMInitializationPayloadErrorDescription?
}
