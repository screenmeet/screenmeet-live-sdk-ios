//
//  SMLaserPointerChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 31.03.2021.
//

import Foundation

fileprivate struct LPData: Decodable {
    
    var coords: Coords?
    
    var click: Bool?
    
    var enabled: Bool?
    
    struct Coords: Decodable {
        
        var x: CGFloat?
        
        var y: CGFloat?
    }
}

class SMLaserPointerChannel: SMChannel {
    
    var name: SMChannelName = .laserPointer
    
    private var lpService = SMLaserPointerService()
    
    func processEvent(_ message: SMChannelMessage) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: message.data[1], options: .prettyPrinted) {
            do {
                let data = try JSONDecoder().decode(LPData.self, from: jsonData)
                
                if data.enabled == true {
                    lpService.startLaserPointerSession()
                } else if data.enabled == false {
                    lpService.stopLaserPointerSession()
                }
                
                if let coords = data.coords, let x = coords.x, let y = coords.y {
                    let point = CGPoint(x: x, y: y)
                    lpService.updateLaserPointerCoors(point)
                    
                    print("[LP] New point", point)
                }
                
                if data.click == true {
                    lpService.updateLaserPointerCoorsWithTap()
                }
            } catch {
                print("[LP] Error", error.localizedDescription)
            }
        }
    }
    
    func buildState(from initialPayload: [String : Any]) { }
    
    func stopLaserPointerSession() {
        lpService.stopLaserPointerSession()
    }
}
