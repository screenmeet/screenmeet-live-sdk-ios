//
//  SMRemoteControlKeyboard.swift
//  ScreenMeetSDK
//
//  Created by Ross on 17.09.2021.
//

import UIKit

/// Keyboard remote control event  type
public enum SMKeyboardActionType: String {
    case unknown = "unknown"
    case keydown = "keydown"
    case keyup = "keyup"
}

/// Keyboard remote control event (triggered by controlling participant)
public class SMRemoteControlKeyboardEvent: SMRemoteControlEvent {
    
    /**
        String keyboard key that has been pressed
    */
    public private(set) var key: String
    
    /**
        ASCII code ot the key that has been pressed
    */
    public private(set) var acii: Int
    
    /**
        Type of  the event. See `SMRemoteControlKeyboardEvent`
    */
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
