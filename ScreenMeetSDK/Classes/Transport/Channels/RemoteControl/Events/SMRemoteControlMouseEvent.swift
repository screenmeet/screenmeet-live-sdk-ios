//
//  SMRemoteControlMouseEvent.swift
//  ScreenMeetSDK
//
//  Created by Ross on 10.09.2021.
//

import UIKit

public enum SMMouseActionType: String {
    case unknown = "unknown"
    case leftdown = "leftmousedown"
    case rightdown = "rightmousedown"
    case move = "mousemove"
    case leftup = "leftmouseup"
    case rightup = "rightmouseup"
}

public class SMRemoteControlMouseEvent: SMRemoteControlEvent {
    
    public private(set) var ts: Int64
    public private(set) var x: Double
    public private(set) var y: Double
    public private(set) var type: SMMouseActionType = .unknown
    
    override init?(_ socketData: [String: Any]) {
        
        if let mouseData = socketData["data"] as? [String:  Any] {
            if let ts = mouseData["ts"] as? Int64 { self.ts = ts} else {return nil}
            if let x = mouseData["x"] as? Double { self.x = x} else {return nil}
            if let y = mouseData["y"] as? Double { self.y = y} else {return nil}
            if let type = SMMouseActionType(rawValue: mouseData["ev"] as! String) { self.type = type } else { return nil }
        }
        else {
            return nil
        }
        
        super.init(socketData)
    }
    
}
