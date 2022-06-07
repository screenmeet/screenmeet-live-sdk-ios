//
//  ScreenVideoCapturer.swift
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

import Foundation
import WebRTC
import ReplayKit

class FakeCapturer: RTCVideoCapturer, SMVideoCapturer {
        
    let captureSession = AVCaptureSession()
    
    override init(delegate: RTCVideoCapturerDelegate) {
        super.init(delegate: delegate)
    }
    
    func startCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
            completionHandler?(nil)
        })
    }
    
    public func sendImage(_ image: UIImage) {
        RTCDispatcher.dispatchAsync(on: .typeMain, block: { [self] in
            let rotation = RTCVideoRotation._0 // Default rotation
            let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: image.cgImage!.newPixelBufferFromCGImage())
            let timeStampNs: Int64 = Int64(Date().timeIntervalSince1970 * 1000000000)
            let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer, rotation: rotation, timeStampNs: timeStampNs)
            self.delegate?.capturer(self, didCapture: videoFrame)
        })
    }
    
    public func stopCapture(_ completionHandler: SMCapturerOperationCompletion? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession, block: {
            completionHandler?(nil)
        })
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
}

extension CGImage {
    
    func newPixelBufferFromCGImage() -> CVPixelBuffer {
        let options = [kCVPixelBufferCGImageCompatibilityKey: NSNumber(booleanLiteral: true),
                       kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(booleanLiteral: true)]
        
        var pxbuffer : CVPixelBuffer! = nil
        _ = CVPixelBufferCreate(kCFAllocatorDefault,
                                self.width,
                                self.height,
                                kCVPixelFormatType_32ARGB,
                                options as CFDictionary, &pxbuffer)
        
        CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer)

        let aaaa  = 4 * self.width
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata,
                                width: self.width,
                                height: self.height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context!.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pxbuffer
    }
}



