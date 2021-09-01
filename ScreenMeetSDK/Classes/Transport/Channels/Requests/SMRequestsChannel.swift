//
//  SMRequestsChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 30.06.2021.
//

import Foundation

enum SMRequestsChannelError: Error {
    case participantNotExists
}

class SMRequestsChannel: SMChannel {
    
    var name: SMChannelName = .requests
    
    func processEvent(_ message: SMChannelMessage) {
        switch message.actionType {
        case .added:
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.data[1], options: .prettyPrinted)
                let requestDataWrapper = try JSONDecoder().decode(SMRequestModelWrapper.self, from: jsonData)
                
                // Request only our entitlements
                let requests = requestDataWrapper.requests.filter { $0.grantorId == transport.webSocketClient.sid }
                
                for request in requests {
                    try requestAccess(with: request)
                }
            } catch {
                NSLog("[SM] Requests Channel Error: \(error.localizedDescription)")
            }
        case .removed:
            let entitlementTypes = (message.data[1] as? [String])?.compactMap { SMEntitlementType(rawValue: $0) } ?? []
            
            for entitlementType in entitlementTypes {
                ScreenMeet.session.delegate?.onRequestRejected(entitlement: entitlementType)
            }
        }
    }
    
    func buildState(from initialPayload: [String : Any]) {
        NSLog("[SM] RequestsChannel \(#function) is not supported")
    }
    
    private func requestAccess(with request: SMRequestModel) throws {
        guard let participant = ScreenMeet.getParticipants().first(where: { $0.id == request.requestorId }) else {
            throw SMRequestsChannelError.participantNotExists
        }
        
        ScreenMeet.session.delegate?.onRequest(entitlement: request.entitlementType, participant: participant, decisionHandler: { granted in
            let entitlementsChannel = SMChannelsManager.shared.channel(for: .entitlements) as? SMEntitlementsChannel
            if granted {
                entitlementsChannel?.grantAccess(for: request.entitlementType, requestorId: request.requestorId)
            } else {
                entitlementsChannel?.denyAccess(for: request.entitlementType, requestorId: request.requestorId)
            }
        })
    }
}
