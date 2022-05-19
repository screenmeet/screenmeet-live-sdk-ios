//
//  SMRemoteControlEvent.swift
//  ScreenMeetSDK
//
//  Created by Ross on 09.09.2021.
//

import UIKit

/// Generic class represnting remote control event (triggered by controlling participant)
public class SMRemoteControlEvent {
    /**
        id of the sender  of the event
    */
    public private(set) var from: String
    
    /**
        id of the receiver  of the event
    */
    public private(set) var to: String
    
    init?(_ socketData: [String: Any]) {
        if let from = socketData["from"] as? String { self.from = from} else {return nil}
        if let to = socketData["to"] as? String { self.to = to} else {return nil}
    }
}
