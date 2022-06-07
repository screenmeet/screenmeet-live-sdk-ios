//
//  VideoCapturerFactory.swift
//  ScreenMeet
//
//  Created by Ivan Makhnyk on 24.02.2021.
//

import Foundation
import WebRTC
import ReplayKit

protocol SMVideoCapturer: RTCVideoCapturer {
    func startCapture(_ completionHandler: SMCapturerOperationCompletion?)
    func stopCapture(_ completionHandler: SMCapturerOperationCompletion?)
    func getCaptureSession() -> AVCaptureSession
}

class VideoCapturerFactory {
    
    static func videoCapturer(_ videoSourceDevice: AVCaptureDevice! = nil, delegate: RTCVideoCapturerDelegate) -> SMVideoCapturer {
        if videoSourceDevice == nil {
            return ScreenVideoCapturer(delegate: delegate)
        }
        let cameraCapturer = CameraVideoCapturer(delegate: delegate)
        cameraCapturer.device = videoSourceDevice
        return cameraCapturer
    }
    
    static func fakeCapturer(delegate: RTCVideoCapturerDelegate) -> SMVideoCapturer {
        let capturer = FakeCapturer(delegate: delegate)
        return capturer
    }
    
}
