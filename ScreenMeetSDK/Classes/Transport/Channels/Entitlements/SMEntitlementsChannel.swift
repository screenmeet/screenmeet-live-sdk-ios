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
    
    private var entitlements = [SMEntitlementModel]()
    
    func processEvent(_ message: SMChannelMessage) {
        switch message.actionType {
        case .added:
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.data[1], options: .prettyPrinted)
                let entitlementsWrapper = try JSONDecoder().decode(SMEntitlementModelWrapper.self, from: jsonData)
                
                // Track only our entitlements
                let entitlements = entitlementsWrapper.entitlements.filter { $0.grantorId == transport.webSocketClient.sid }
                
                self.entitlements.append(contentsOf: entitlements)
                
                for entitlement in entitlements {
                    switch entitlement.type {
                    case .laserpointer:
                        let laserPointerChannel = SMChannelsManager.shared.channel(for: .laserPointer) as? SMLaserPointerChannel
                        try laserPointerChannel?.startLaserPointerSession(for: entitlement.requestorId)
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
                    let laserPointerChannel = SMChannelsManager.shared.channel(for: .laserPointer) as? SMLaserPointerChannel
                    laserPointerChannel?.stopLaserPointerSession(for: entitlement.requestorId)
                }
            }
            
            self.entitlements.removeAll(where: { requestorsId.contains($0.requestorId) })
        }
    }
    
    func buildState(from initialPayload: [String : Any]) {
        NSLog("[SM] EntitlementsChannel \(#function) is not supported")
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
