//
//  FakeCapturer.swift
//  ScreenMeetSDK
//
//  Created by Ross on 10.05.2022.
//

import UIKit
import WebRTC

class FakeCapturer: RTCVideoCapturer, SMVideoCapturer {
    let captureSession = AVCaptureSession()
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    func startCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        completionHandler?(nil)
    }

    public func stopCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        completionHandler?(nil)
    }

}
