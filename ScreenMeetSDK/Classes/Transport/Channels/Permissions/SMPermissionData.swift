//
//  SMPermissionData.swift
//  ScreenMeetSDK
//
//  Created by Ross on 05.09.2022.
//

import SocketIO

public struct SMFeature {
    public let type: SMPermissionType
    public let requestorParticipant: SMParticipant
    public let requestId: String
}

class SMPermissionData: SocketData {
    
    var deviceGrantId: String!
    var global: Bool!
    var grantorCid: String!
    var onDupe: Bool!
    var privilege: String!
    var requestId: String!
    var requestorCid: String!
    var status: String!
    var timeCreated: CLong!
    var uniqueGrantor: String!
    var uniqueRequestor: String!
    
    init(_ socketData: [String:  Any]) {
        if let deviceGrantId = socketData["device_grant_id"]  as? String { self.deviceGrantId = deviceGrantId }
        if let global = socketData["global"]  as? Bool { self.global = global }
        if let grantorCid = socketData["grantor_cid"]  as? String { self.grantorCid = grantorCid }
        if let onDupe = socketData["ondupe"]  as? Bool { self.onDupe = onDupe }
        if let privilege = socketData["privilege"]  as? String { self.privilege = privilege }
        if let requestId = socketData["request_id"]  as? String { self.requestId = requestId }
        if let requestorCid = socketData["requestor_cid"]  as? String { self.requestorCid = requestorCid }
        if let status = socketData["status"]  as? String { self.status = status }
        if let timeCreated = socketData["timeCreated"]  as? CLong { self.timeCreated = timeCreated }
        if let uniqueGrantor = socketData["unique_grantor_id"]  as? String { self.uniqueGrantor = uniqueGrantor }
        if let uniqueRequestor = socketData["unique_rquestor"]  as? String { self.uniqueRequestor = uniqueRequestor }
    }
    public func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["device_grant_id"] = deviceGrantId
        data["grantor_cid"] = grantorCid
        data["ondupe"] = onDupe
        data["privilege"] = privilege
        data["request_id"] = requestId
        data["requestor_cid"] = requestorCid
        data["status"] = status
        data["time_created"] = timeCreated
        data["unique_grantor"] = uniqueGrantor
        data["unique_requestor"] = uniqueRequestor
        return data
    }

}
