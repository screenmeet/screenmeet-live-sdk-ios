//
//  SMEntitlementsChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 30.06.2021.
//

import Foundation
import SocketIO

class SMEntitlementsChannel: SMChannel {
    
    var name: SMChannelName = .entitlements
    
    private var entitlements = [SMEntitlement]()
    
    func processEvent(_ message: SMChannelMessage) {
        switch message.actionType {
        case .added:
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.data[1], options: .prettyPrinted)
                let entitlementsObject = try JSONDecoder().decode(SMEntitlementsWrapper.self, from: jsonData)
                
                // Track only our entitlements
                let entitlements = entitlementsObject.entitlements.filter { $0.grantorId == transport.webSocketClient.sid }
                
                self.entitlements.append(contentsOf: entitlements)
                
                for entitlement in entitlements {
                    switch entitlement.type {
                    case .laserpointer:
                        let laserPointerChannel = transport.channelsManager.channel(for: .laserPointer) as? SMLaserPointerChannel
                        try laserPointerChannel?.startLaserPointerSession(for: entitlement.requestorId)
                    case .remotecontrol:
                        let remoteControlChannel = transport.channelsManager.channel(for: .remoteControl) as? SMRemoteControlChannel
                        try remoteControlChannel?.startRemoteControlSession(for: entitlement.requestorId)
                    }
                    
                    if let participant = ScreenMeet.getParticipants().first(where: { $0.id == entitlement.requestorId }) {
                        let feature = SMFeature(type: entitlement.type, requestorParticipant: participant)
                        ScreenMeet.delegate?.onFeatureStarted(feature: feature)
                    }
                }
            } catch {
                NSLog("[SM] Entitlements Channel Error: \(error.localizedDescription)")
            }
        case .removed:
            guard let requestorsId = message.data[1] as? [String] else { return }
            
            let entitlements = self.entitlements.filter { requestorsId.contains($0.requestorId) }
            
            for entitlement in entitlements {
                switch entitlement.type {
                case .laserpointer:
                    let laserPointerChannel = transport.channelsManager.channel(for: .laserPointer) as? SMLaserPointerChannel
                    laserPointerChannel?.stopLaserPointerSession(for: entitlement.requestorId)
                
                case .remotecontrol:
                    let remoteControlChannel = transport.channelsManager.channel(for: .remoteControl) as? SMRemoteControlChannel
                    remoteControlChannel?.stopAllRemoteControlSessions()
                }
                
                if let participant = ScreenMeet.getParticipants().first(where: { $0.id == entitlement.requestorId }) {
                    let feature = SMFeature(type: entitlement.type, requestorParticipant: participant)
                    ScreenMeet.delegate?.onFeatureStopped(feature: feature)
                }
            }
            
            self.entitlements.removeAll(where: { requestorsId.contains($0.requestorId) })
        }
    }
    
    func buildState(from initialPayload: [String : Any]) {
        NSLog("[SM] EntitlementsChannel \(#function) is not supported")
        self.entitlements.removeAll()
    }
    
    func activeFeatures() -> [SMFeature] {
        var features = [SMFeature]()
        for entitlement in entitlements {
            if let participant = ScreenMeet.getParticipants().first(where: { $0.id == entitlement.requestorId }) {
                features.append(SMFeature(type: entitlement.type, requestorParticipant: participant))
            }
        }
        
        return features
    }
    
    func grantAccess(for entitlementType: SMEntitlementType, requestorId: String) {
        self.transport.webSocketClient.command(for: name, message: "grant", data: ["privilege": entitlementType.rawValue, "client_id": requestorId]) { data in
        }
    }
    
    func denyAccess(for entitlementType: SMEntitlementType, requestorId: String) {
        self.transport.webSocketClient.command(for: name, message: "deny", data: ["privilege": entitlementType.rawValue, "client_id": requestorId]) { data in }
    }
    
    func revokeAccess(for entitlementType: SMEntitlementType, requestorId: String) {
        self.transport.webSocketClient.command(for: name, message: "revoke", data: ["privilege": entitlementType.rawValue, "client_id": requestorId]) { data in }
    }
}
