//
//  SMLaserPointerChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 31.03.2021.
//

import Foundation

class SMLaserPointerChannel: SMChannel {
    
    var name: SMChannelName = .laserPointer
    
    private var lpService = SMLaserPointerService()
    
    private var requestorIds = [String]()
    
    func processEvent(_ message: SMChannelMessage) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message.data[1], options: .prettyPrinted)
            let laserPointerModel = try JSONDecoder().decode(SMLaserPointerModel.self, from: jsonData)
            
            if let coords = laserPointerModel.data.coords {
                let position = CGPoint(x: coords.x, y: coords.y)
                
                lpService.updateLaserPointer(position: position, for: laserPointerModel.from)
            } else if laserPointerModel.data.click == true {
                lpService.updateLaserPointerTap(for: laserPointerModel.from)
            }
        } catch {
            NSLog("[SM] LaserPointer Channel Error", error.localizedDescription)
        }
    }
    
    func buildState(from initialPayload: [String : Any]) {
        NSLog("[SM] LaserPointerChannel \(#function) is not supported")
    }
    
    func startLaserPointerSession(for id: String) throws {
        try lpService.startLaserPointerSession(for: id)
        requestorIds.append(id)
    }
    
    func stopLaserPointerSession(for id: String) {
        lpService.stopLaserPointerSession(for: id)
        requestorIds.removeAll(where: { $0 == id })
    }
    
    func stopAllLaserPointerSessions() {
        lpService.stopAllLaserPointerSessions()
        
        for requestorId in requestorIds {
            (SMChannelsManager.shared.channel(for: .entitlements) as? SMEntitlementsChannel)?.revokeAccess(for: .laserpointer, requestorId: requestorId)
        }
        
        requestorIds.removeAll()
    }
}
