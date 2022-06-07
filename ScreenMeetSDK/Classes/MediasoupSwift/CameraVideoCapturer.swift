//
//  CameraVideoCapturer.swift
//  ScreenMeet
//
//  Created by Ivan Makhnyk on 24.02.2021.
//

import Foundation
import WebRTC


class CameraVideoCapturer: RTCCameraVideoCapturer /*MSCameraVideoCapturer*/, SMVideoCapturer {
    let kNanosecondsPerSecond = 1000000000

    var device: AVCaptureDevice! = nil
 
    override init(delegate: RTCVideoCapturerDelegate) {
        super.init(delegate: delegate)
    }
    
    func startCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
            self.startCapture(with: self.device!, format: self.device!.activeFormat, fps: 30) { (error: Error?) in
                if error == nil {
                    completionHandler?(nil)
                }
                else {
                    completionHandler?(SMError(code: .capturerInternalError, message: error!.localizedDescription))
                }
            }
        })
    }
    
    func stopCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
                self.stopCapture(completionHandler: {
                let inputs = self.captureSession.inputs.map { $0.copy() }
                inputs.forEach({input in self.captureSession.removeInput(input as! AVCaptureInput)})
                self.captureSession.stopRunning()
                self.device = nil
                completionHandler?(nil)
                NSLog("camera capturer stopped")
            })
        })
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
}

extension CameraVideoCapturer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
            !CMSampleBufferDataIsReady(sampleBuffer)) {
          return;
        }

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if (pixelBuffer == nil) {
            return;
        }
        
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer!)
        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
            Float64(kNanosecondsPerSecond)
        
        
        let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                       rotation: ._0, // later it should be dynamic, base on device's orientation
                                       timeStampNs: Int64(timeStampNs))
        self.delegate?.capturer(self, didCapture: videoFrame)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let droppedReason = CMGetAttachment(sampleBuffer,
                                            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
                                            attachmentModeOut: nil)
        
        let nsDroppedReason = droppedReason as? NSString
        let swiftDroppedReason = nsDroppedReason as String?
        
        if let swiftDroppedReason = swiftDroppedReason {
            NSLog("Dropped sample buffer. Reason: " + swiftDroppedReason)
        }
        else {
            NSLog("Dropped sample buffer. Reason: unknown")
        }
    }
}
