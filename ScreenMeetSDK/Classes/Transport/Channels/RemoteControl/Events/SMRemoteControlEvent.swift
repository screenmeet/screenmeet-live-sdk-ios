//
//  SMRemoteControlEvent.swift
//  ScreenMeetSDK
//
//  Created by Ross on 09.09.2021.
//

import UIKit

public class SMRemoteControlEvent {
    var from: String
    var to: String
    
    init?(_ socketData: [String: Any]) {
        if let from = socketData["from"] as? String { self.from = from} else {return nil}
        if let to = socketData["to"] as? String { self.to = to} else {return nil}
    }
}
