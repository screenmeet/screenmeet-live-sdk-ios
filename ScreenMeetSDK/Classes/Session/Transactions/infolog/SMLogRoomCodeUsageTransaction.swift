//
//  SMLogRoomCodeUsageTransaction.swift
//  ScreenMeetSDK
//
//  Created by Ross on 27.07.2021.
//

import UIKit

class SMLogRoomCodeUsageTransaction: SMTransaction {
    private var usedPin: Bool = false
    private var usedCapcha: Bool = false
    private var usedSessionCode: Bool = false
    
    func witUsedPin(_ usedPin: Bool) -> SMLogRoomCodeUsageTransaction {
        self.usedPin = usedPin
        
        return self
    }
    
    func withUsedCapcha(_ usedCapcha: Bool) -> SMLogRoomCodeUsageTransaction {
        self.usedCapcha = usedCapcha
        
        return self
    }
    
    func withUsedSessionCode(_ usedSessionCode: Bool) -> SMLogRoomCodeUsageTransaction {
        self.usedSessionCode = usedSessionCode
        
        return self
    }
    
    func run() {
        if usedPin {
            let event = SMLogEvent(type: "used-pin", message: "Used pin to connect to session")
            transport.webSocketClient.logInfo(event)
        }
        
        if usedCapcha {
            let event = SMLogEvent(type: "used-cpacha", message: "Used capcha while connecting to session")
            transport.webSocketClient.logInfo(event)
        }
        
        if usedSessionCode {
            let event = SMLogEvent(type: "used-session-code", message: "Used session code to to session")
            transport.webSocketClient.logInfo(event)
        }
    }
}
