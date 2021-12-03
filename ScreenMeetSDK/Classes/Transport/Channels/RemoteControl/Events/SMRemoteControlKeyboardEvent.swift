//
//  SMRemoteControlKeyboard.swift
//  ScreenMeetSDK
//
//  Created by Ross on 17.09.2021.
//

import UIKit

public enum SMKeyboardActionType: String {
    case unknown = "unknown"
    case keydown = "keydown"
    case keyup = "keyup"
}

public class SMRemoteControlKeyboardEvent: SMRemoteControlEvent {
    public private(set) var key: String
    public private(set) var acii: Int
    public private(set) var type: SMKeyboardActionType = .unknown
    
    override init?(_ socketData: [String: Any]) {
        
        if let keyData = socketData["data"] as? [String:  Any] {
            if let key = keyData["k"] as? String { self.key = key} else {return nil}
            if let acii = keyData["kc"] as? Int { self.acii = acii} else {return nil}
            if let type = SMKeyboardActionType(rawValue: keyData["ev"] as! String) { self.type = type } else { return nil }
        }
        else {
            return nil
        }
        
        super.init(socketData)
    }
}
