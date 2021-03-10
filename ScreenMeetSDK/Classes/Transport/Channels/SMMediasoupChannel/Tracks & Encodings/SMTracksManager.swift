//
//  SMTrackBuilder.swift
//  ScreenMeet
//
//  Created by Ross on 22.02.2021.
//

import UIKit
import WebRTC

public typealias CapturereCompletion = (SMError?) -> Void

class SMTracksManager: NSObject {
    private var mediaStream: RTCMediaStream!
    private var videoSource: RTCVideoSource!
    private var videoTrack: RTCVideoTrack!
    
    private var videoCapturer: SMVideoCapturer!
    
    private var factory: RTCPeerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(), decoderFactory: RTCDefaultVideoDecoderFactory())
    
    func makeVideoTrack() -> RTCVideoTrack {
        if mediaStream == nil {
            self.mediaStream = self.factory.mediaStream(withStreamId: "0")
        }
                
        videoSource = factory.videoSource()
        videoSource.adaptOutputFormat(toWidth: 480, height: 640, fps: 30)
        
        videoTrack = factory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        self.mediaStream.addVideoTrack(videoTrack)
        videoTrack.isEnabled = true
        
        return videoTrack
    }
    
    func makeAudioTrack() -> RTCAudioTrack {
        let audioTrack: RTCAudioTrack = factory.audioTrack(withTrackId: "ARDAMSa0")
        audioTrack.isEnabled = true
        
        if mediaStream == nil {
            self.mediaStream = self.factory.mediaStream(withStreamId: "0")
        }
        
        self.mediaStream.addAudioTrack(audioTrack)
        var encodings: Array = Array<RTCRtpEncodingParameters>.init()
        let e = RTCRtpEncodingParameters.init()
        e.rid = "l"
        e.bitratePriority = 1.0
        e.maxBitrateBps = 48000
        e.maxFramerate = 30
        e.isActive = true
        e.minBitrateBps = 0
        e.numTemporalLayers = 0
        e.scaleResolutionDownBy = 1.0
        encodings.append(e)
        
        return audioTrack
    }
    
    /// Captureres
    
    func startCapturer(_ videoSourceDevice: AVCaptureDevice, _ completionHandler: CapturereCompletion? = nil) {
        if (videoCapturer != nil) {
            //TODO
            print("Video capturer already started")
            completionHandler?(nil)
            return
        }
        
        videoCapturer = VideoCapturerFactory.videoCapturer(videoSourceDevice, delegate: self)
        videoCapturer.startCapture() { [weak self] error in
            if #available(iOS 13.0, *) {
                let captureSessionConnections = self?.videoCapturer.getCaptureSession().connections
                captureSessionConnections?.first!.videoOrientation = .portrait
                NSLog("Capture sessions retrieved")
                completionHandler?(error)
            } else {
                completionHandler?(SMError(code: .capturerInternalError, message: "Unsupportes OS version"))
            }
        }
    }

    func stopCapturer(completionHandler: CapturereCompletion? = nil) {
        if (videoCapturer == nil) {
            //TODO
            print("Video capturer already stoped")
            completionHandler?(nil)
            return
        }
        
        videoCapturer.stopCapture(completionHandler)
        videoCapturer = nil
    }
    
    func cleanup() {
        self.mediaStream = nil
        self.videoTrack.isEnabled = false
        self.videoTrack = nil
        self.videoSource = nil
    }

    func changeCapturer(_ videoSourceDevice: AVCaptureDevice!, _ completionHandler: CapturereCompletion? = nil) {
        if (videoCapturer != nil) {
            videoCapturer.stopCapture({error in
                guard error == nil else {
                    completionHandler?(error)
                    return
                }
                let newCapturer = VideoCapturerFactory.videoCapturer(videoSourceDevice, delegate: self)
                newCapturer.startCapture({error in
                    guard error == nil else {
                        //restore capturing previous capturer
                        self.videoCapturer.startCapture(completionHandler)
                        completionHandler?(error)
                        return
                    }
                    newCapturer.startCapture(completionHandler)
                    self.videoCapturer = newCapturer
                })
            })
        } else {
            let newCapturer = VideoCapturerFactory.videoCapturer(videoSourceDevice, delegate: self)
            newCapturer.startCapture({error in
                guard error == nil else {
                    completionHandler?(error)
                    return
                }
                newCapturer.startCapture(nil)
                self.videoCapturer = newCapturer
            })
        }
    }
    
    func getVideoSourceDevice() -> AVCaptureDevice? {
        if let cameraCapturer = self.videoCapturer as? CameraVideoCapturer {
            return cameraCapturer.device
        }
        return nil
    }
}

extension SMTracksManager: RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        //UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.videoSource?.capturer(capturer, didCapture: frame)
    }
}
