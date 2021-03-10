//
//  SMError.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit

public enum ErrorCode: Int {
    case httpError = 100001
    case socketError = 100002
    case notReachableError = 100003
    case transactionInternalError = 100004
    case capturerInternalError = 100005
}

public struct SMError {
    public var code: ErrorCode
    public var message: String
}
