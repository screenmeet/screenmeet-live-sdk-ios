//
//  SMPermissionChannel.swift
//  ScreenMeetSDK
//
//  Created by Ross on 05.09.2022.
//

import Foundation

enum SMPermissionStatus: String {
    case requested = "requested"
    case granted = "granted"
}

enum SMPermissionsChannelError: Error {
    case participantNotExists
}

class SMPermissionsChannel: SMChannel {
    var name: SMChannelName = .permissions
    
    private var activePermissions = [SMPermissionData]()
    private var requestorParticipants = [SMParticipant]()
    
    func processEvent(_ message: SMChannelMessage) {
        switch message.actionType {
        case .added:
            let messageDict = message.data[1] as! [String: Any]
            
            for (_, value) in messageDict {
                let permissionData = SMPermissionData(value as! [String: Any])
                processPermissionData(permissionData)
            }
        case .removed:
            guard let permissionRequestIds = message.data[1] as? [String] else { return }
            
            permissionRequestIds.forEach { requestId in
                cancelRequest(with: requestId)
            }
            
            var permissionToRemove = [SMPermissionData]()
            activePermissions.forEach { permission in
                if permissionRequestIds.contains(permission.requestId) {
                    permissionToRemove.append(permission)
                    
                    if let type = SMPermissionType(rawValue: permission.privilege) {
                        switch type {
                            case .laserpointer:
                                let laserPointerChannel = transport.channelsManager.channel(for: .laserPointer) as? SMLaserPointerChannel
                                laserPointerChannel?.stopLaserPointerSession(for: permission.requestorCid)
                            case .remotecontrol:
                                let remoteControlChannel = transport.channelsManager.channel(for: .remoteControl) as? SMRemoteControlChannel
                                remoteControlChannel?.stopAllRemoteControlSessions()
                        }
                    }
                }
            }
            
            /* Remove these permissions*/
            activePermissions.removeAll { activePermission in
                permissionToRemove.contains { p in p.requestId == activePermission.requestId  }
            }
        }
    }
    
    func buildState(from initialPayload: [String : Any]) {
        for (_, dict) in initialPayload {
            let dict = (dict as! [String: Any])
            let permissionDict = dict["value"] as! [String: Any]
            
            let permissionData = SMPermissionData(permissionDict)
            processPermissionData(permissionData)
        }
    }
    
    func activeFeatures() -> [SMFeature] {
        var features = [SMFeature]()
        for permission in activePermissions  {
            if let participant = ScreenMeet.getParticipants().first(where: { $0.id == permission.requestorCid }) {
                features.append(SMFeature(type: SMPermissionType(rawValue: permission.privilege)!, requestorParticipant: participant, requestId: permission.requestId))
            }
        }
        
        return features
    }
    
    func removeAllPermissions() {
        activePermissions.removeAll()
    }
    
    func revokeAccess(for permissionType: SMPermissionType, requestorId: String) {
        self.transport.webSocketClient.command(for: name, message: "revoke", data: ["privilege": permissionType.rawValue, "client_id": requestorId]) { data in }
    }
    
    private func processPermissionData(_ permissionData: SMPermissionData) {
        do {
            if permissionData.grantorCid == transport.webSocketClient.sid {
                
                /* Received permission request*/
                if permissionData.status == SMPermissionStatus.requested.rawValue {
                    try requestAccess(with: permissionData)
                }
                /* Permission granted*/
                else if permissionData.status == SMPermissionStatus.granted.rawValue {
                    
                    /* Most probably viewer was reconnected and sends the same permission again*/
                    if activePermissions.contains(where: { permission in
                        permission.requestId == permissionData.requestId
                    }) {
                        return
                    }
                    activePermissions.append(permissionData)
                    
                    switch SMPermissionType(rawValue: permissionData.privilege)! {
                        case .laserpointer:
                            let laserPointerChannel = transport.channelsManager.channel(for: .laserPointer) as? SMLaserPointerChannel
                            try laserPointerChannel?.startLaserPointerSession(for: permissionData.requestorCid)
                        case .remotecontrol:
                            let remoteControlChannel = transport.channelsManager.channel(for: .remoteControl) as? SMRemoteControlChannel
                            try remoteControlChannel?.startRemoteControlSession(for: permissionData.requestorCid)
                    }
                    
                    if let permissionType = SMPermissionType(rawValue: permissionData.privilege), let participant = ScreenMeet.getParticipants().first(where: { $0.id == permissionData.requestorCid }) {
                        let feature = SMFeature(type: permissionType, requestorParticipant: participant, requestId: permissionData.requestId)
                        ScreenMeet.session.delegate?.onFeatureStarted(feature: feature)
                    }
                }
            }
        }
        catch {
            NSLog("[SM Permissions channel].[ProcessPermissionData]. \(error.localizedDescription)")
        }
    }
    
    private func cancelRequest(with requestId: String) {
        ScreenMeet.session.delegate?.onFeatureRequestRejected(requestId: requestId)
    }
    
    private func requestAccess(with data: SMPermissionData) throws {
        guard let participant = ScreenMeet.getParticipants().first(where: { $0.id == data.requestorCid }) else {
            throw SMPermissionsChannelError.participantNotExists
        }
        
        if let permissionType = SMPermissionType(rawValue: data.privilege) {
            let feature = SMFeature(type: permissionType, requestorParticipant: participant, requestId: data.requestId)
            ScreenMeet.session.delegate?.onFeatureRequest(feature, { [self] granted in
                if granted {
                    transport.webSocketClient.command(for: name, message: "grant", data: ["privilege": data.privilege, "client_id": data.requestorCid], callback: { result in } )
                } else {
                    transport.webSocketClient.command(for: name, message: "deny", data: ["privilege": data.privilege, "client_id": data.requestorCid], callback: { result in })
                }
            })
        }
    }
}
