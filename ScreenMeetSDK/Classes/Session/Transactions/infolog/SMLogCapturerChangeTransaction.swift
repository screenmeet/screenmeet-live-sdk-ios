//
//  SMLogInfoTransaction.swift
//  ScreenMeetSDK
//
//  Created by Ross on 26.07.2021.
//

import UIKit
import AVFoundation

class SMLogCapturerChangeTransaction: SMTransaction {

    private var device: AVCaptureDevice? = nil
    
    func witDevice(_ device: AVCaptureDevice?) -> SMLogCapturerChangeTransaction {
        self.device = device
        
        return self
    }
    
    func run() {
        if let device = device {
            let event = SMLogEvent(type: "change-capturer", message: "Capturer changed to " + device.localizedName)
            //transport.webSocketClient.logInfo(event)
        }
        else {
            let event = SMLogEvent(type: "change-capturer", message: "Capturer changed to default one")
            //transport.webSocketClient.logInfo(event)
        }
    }
    
}
