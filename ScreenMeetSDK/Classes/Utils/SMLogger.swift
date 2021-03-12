//
//  SMLogger.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 16.09.2020.
//

import Foundation

///ScreenMeet Logger
class SMLogger {
    
    static let log = SMLogger()
    
    private init() { }
    
    var level: Level = .error
    
    enum Level: Int, Comparable {
        /// Information that may be helpful, but isn’t essential, for troubleshooting errors
        case info = 0
        /// Verbose information that may be useful during development or while troubleshooting a specific problem
        case debug
        /// Designates error events that might still allow the application to continue running
        case error
        
        static func < (lhs: SMLogger.Level, rhs: SMLogger.Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    func info(_ string: String) {
        if level <= .info {
            printLog(message: setupLog(message: string, level: "info"))
        }
    }
    
    func debug(_ string: String) {
        if level <= .debug {
            printLog(message: setupLog(message: string, level: "debug"))
        }
    }
    
    func warning(_ string: String) {
        if level <= .debug {
            printLog(message: setupLog(message: string, level: "warning"))
        }
    }
    
    func error(_ string: String) {
        if level <= .error {
            printLog(message: setupLog(message: string, level: "error"))
        }
    }
}

extension SMLogger {
    
    private func printLog(message: String) {
        print(message)
    }
    
    
    func setupLog(message: String, level: String) -> String {
        return "\(logPrefix(level: level)) - \(message)"
    }
    
    
    func logPrefix(level: String) -> String {
        let thread = Thread.isMainThread ? "🔴 [UI]" : "🔵 [BG]"
        
        let warning: String
        switch level {
        case "warning":
            warning = " 🔸"
        case "error":
            warning = " 🔺"
        default:
            warning = ""
        }
        
        return "\(NSDate()) \(thread)\(warning) [\(level)]"
    }
    
    
    func normalized(string: String, length: Int, prefix: String, suffix: String, wordBreak: String = "...") -> String? {
        var signature = "\(prefix)\(string)\(suffix)"
        
        if length >= signature.count {
            signature = signature + String(Array(repeating: " ", count: length - signature.count))
        } else {
            let otherLength = prefix.count + suffix.count + wordBreak.count
            guard length > otherLength else { return nil }
            let startIndex = string.startIndex
            let endIndex = string.index(string.startIndex, offsetBy: length - otherLength - 1)
            signature = "\(prefix)\(string[startIndex...endIndex])\(wordBreak)\(suffix)"
        }
        
        return signature
    }
}
