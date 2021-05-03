//
//  SMError.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

/// Represents ScreenMeet error codes
public enum SMErrorCode: Int {
    
    /// HTTP connection error
    case httpError = 100001

    /// Socket connection error
    case socketError = 100002

    /// Unaccessible server
    case notReachableError = 100003
    
    /// Transaction error
    case transactionInternalError = 100004
    
    /// Video capturer error
    case capturerInternalError = 100005
    
    /// Media track error
    case mediaTrackError = 100006
}

/// Represents ScreenMeet error
public struct SMError {
    
    /// Error code
    public var code: SMErrorCode
    
    /// Error description
    public var message: String
    
    /// Challenge
    public var challenge: SMChallenge? = nil
}
