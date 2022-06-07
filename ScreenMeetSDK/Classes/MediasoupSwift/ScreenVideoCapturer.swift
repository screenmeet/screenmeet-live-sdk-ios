//
//  ScreenVideoCapturer.swift
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

import Foundation
import WebRTC
import ReplayKit

class ScreenVideoCapturer: RTCVideoCapturer, SMVideoCapturer, AVCaptureVideoDataOutputSampleBufferDelegate {
        
    var frameQueue = DispatchQueue(label: "com.screenmeet.webrtc.screencapturer.video")
    let captureSession = AVCaptureSession()
    static let appStreamService = SMAppStreamService()
    
    override init(delegate: RTCVideoCapturerDelegate) {
        super.init(delegate: delegate)
    }
    
    func startCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        self.startCaptureScreen(completionHandler)
    }

    public func startCaptureScreen(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
            self.reconfigureCaptureSessionInput()
            self.captureSession.startRunning()
            
            ScreenVideoCapturer.appStreamService.startStream(completionHandler) { (result) in
                switch result {
                case .success(let pixelBuffer):
                    let rotation = RTCVideoRotation._0 // Default rotation
                    let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                    let timeStampNs: Int64 = Int64(Date().timeIntervalSince1970 * 1000000000)
                    let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer, rotation: rotation, timeStampNs: timeStampNs)
                    self.delegate?.capturer(self, didCapture: videoFrame)
                case .failure(let error):
                    switch error {
                        case .startCaptureFailed(let captureError):
                            completionHandler?(SMError(code: .capturerInternalError, message: captureError.localizedDescription))
                        case .stopCaptureFailed:
                            NSLog("Stop capture error ocurreced when starting capturing")
                    }
                }
            }
        })
    }
    
    public func setupCaptureSession(captureSession: AVCaptureSession) {
        let videoDataOutput = self.setupVideoDataOutput();
        if (!captureSession.canAddOutput(videoDataOutput)) {
            print("WARNING: Video data output unsupported.");
            //return false
        }
        captureSession.addOutput(videoDataOutput)
    }
    
    public func setupVideoDataOutput() -> AVCaptureVideoDataOutput {
        let videoDataOutput = AVCaptureVideoDataOutput()

        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: self.frameQueue)
        return videoDataOutput
    }
    
    public func reconfigureCaptureSessionInput() {
        self.captureSession.beginConfiguration()
        captureSession.usesApplicationAudioSession = false
        self.captureSession.commitConfiguration()
    }
    
    public func stopCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        ScreenVideoCapturer.appStreamService.stopStream { (result) in
            switch result {
            case .success:
                RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
                    let inputs = self.captureSession.inputs.map { $0.copy() }
                    inputs.forEach({input in self.captureSession.removeInput(input as! AVCaptureInput)})
                    self.captureSession.stopRunning()
                    self.delegate = nil
                    completionHandler?(nil)
                })
            case .failure(let error):
                completionHandler?(SMError(code: .capturerInternalError, message: error.localizedDescription))
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
}


