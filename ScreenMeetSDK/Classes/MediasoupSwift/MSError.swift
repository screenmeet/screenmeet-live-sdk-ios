//
//  MSError.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit

enum MSErrorType {
    case device
    case transport
    case peerConnection
    case producer
    case consumer
    case capturer
    case sdpTransformFormatError
   
}

struct MSError {
    var type: MSErrorType
    var message: String
}
