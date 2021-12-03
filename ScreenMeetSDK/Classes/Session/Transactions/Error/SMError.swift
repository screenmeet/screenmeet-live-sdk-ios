//
//  SMError.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

/// Represents ScreenMeet error codes
public enum SMErrorCode: Equatable {
    public static func == (l: SMErrorCode, r: SMErrorCode) -> Bool {
        switch (l, r) {
        case (.socketError, .socketError):
            return true
        case (.notReachableError, .notReachableError):
            return true
        case (.transactionInternalError, .transactionInternalError):
            return true
        case (.capturerInternalError, .capturerInternalError):
            return true
        case (.mediaTrackError, .mediaTrackError):
            return true
        case (.knockEntryPermissionRequiredError, .knockEntryPermissionRequiredError):
            return true
        case (.knockWaitTimeForEntryExpiredError, .knockWaitTimeForEntryExpiredError):
            return true
        case let (.httpError(v0), .httpError(v1)):
            return v0 == v1
        default:
            return false
        }
    }
    
    /// HTTP connection error
    case httpError(_ httpCode: SMHTTPCode)

    /// Socket connection error
    case socketError

    /// Unaccessible server
    case notReachableError
    
    /// Transaction error
    case transactionInternalError
    
    /// Video capturer error
    case capturerInternalError
    
    /// Media track error
    case mediaTrackError
    
    /// Knock feature is on and permission from host to let the user in is required
    case knockEntryPermissionRequiredError
    
    /// Knock feature is on and waiting time for entrance expired
    case knockWaitTimeForEntryExpiredError
    
    /// Connection dropped by server
    case droppedByServer
    
    /// Too many faield acptchas have been entered
    case tooManyCaptchaAttempmts
}

public enum SMHTTPCode: Int {
    case notFound = 404
    case unknown = -1
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
