//
//  SMIceCandidate.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit

struct SMIceCandidate: Encodable {
    
    var candidate: String
    
    var sdpMLineIndex: Int32
    
    var sdpMid: String
}
