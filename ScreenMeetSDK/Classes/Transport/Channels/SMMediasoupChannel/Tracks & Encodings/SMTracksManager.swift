//
//  SMTrackBuilder.swift
//  ScreenMeet
//
//  Created by Ross on 22.02.2021.
//

import UIKit
import WebRTC

class SMTracksManager: NSObject {
    var videoSourceDevice: AVCaptureDevice?
    
    private var mediaStream: RTCMediaStream!
    private var videoSource: RTCVideoSource!
    private var videoTrack: RTCVideoTrack!
    private var audioTrack: RTCAudioTrack!
    
    private var videoCapturer: SMVideoCapturer!
    
    private var factory: RTCPeerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(), decoderFactory: RTCDefaultVideoDecoderFactory())
    
    func makeVideoTrack() -> RTCVideoTrack {
        if mediaStream == nil {
            self.mediaStream = self.factory.mediaStream(withStreamId: "0")
        }
                
        videoSource = factory.videoSource()
        
        videoTrack = factory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        self.mediaStream.addVideoTrack(videoTrack)        
        return videoTrack
    }
    
    func makeAudioTrack() -> RTCAudioTrack {
        audioTrack = factory.audioTrack(withTrackId: "ARDAMSa0")
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
    
    func startCapturer(_ videoSourceDevice: AVCaptureDevice?, _ completionHandler: SMCapturerOperationCompletion? = nil) {
        if (videoCapturer != nil) {
            //TODO
            print("Video capturer already started")
            completionHandler?(nil)
            return
        }
        
        if videoSourceDevice == nil {
            /* screen capture video source*/
            videoSource.adaptOutputFormat(toWidth: Int32(Int(UIScreen.main.bounds.size.width)), height: Int32(UIScreen.main.bounds.size.height), fps: 30)
        }
        else {
            let trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(videoSourceDevice!.activeFormat.formatDescription, usePixelAspectRatio: true, useCleanAperture: true)
            videoSource.adaptOutputFormat(toWidth: Int32(trackDimensions.width),
                                          height: Int32(trackDimensions.height),
                                          fps: 30)
        }
        
        videoCapturer = VideoCapturerFactory.videoCapturer(videoSourceDevice, delegate: self)
        videoCapturer.delegate = nil
        videoCapturer.startCapture() { [weak self] error in
            if #available(iOS 13.0, *) {
                let captureSessionConnections = self?.videoCapturer.getCaptureSession().connections
                captureSessionConnections?.first?.videoOrientation = .portrait
                
                completionHandler?(nil)
                self?.videoCapturer.delegate = self
                
            } else {
                completionHandler?(SMError(code: .capturerInternalError, message: "Unsupportes OS version"))
            }
        }
    }

    func stopCapturer(completionHandler: SMCapturerOperationCompletion? = nil) {
        if (videoCapturer == nil) {
            //TODO
            print("Video capturer already stoped")
            completionHandler?(nil)
            return
        }
        
        videoCapturer.stopCapture(completionHandler)
        videoCapturer = nil
    }
    
    func cleanupVideo() {
        if (self.videoCapturer != nil) {
            self.videoCapturer.stopCapture { error in
                
            }
        }
       
        self.videoCapturer = nil
        self.mediaStream = nil
        self.videoTrack = nil
        self.videoSource = nil
    }
    
    func cleanupAudio() {
        if (self.audioTrack != nil) {
            self.audioTrack.isEnabled = false
            self.audioTrack = nil
        }
    }

    func changeCapturer(_ videoSourceDevice: AVCaptureDevice!, _ completionHandler: SMCapturerOperationCompletion? = nil) {
        if (videoCapturer != nil) {
            videoCapturer.delegate = nil
            videoCapturer.stopCapture({ [self] error in
                guard error == nil else {
                    completionHandler?(error)
                    return
                }
                
                if videoSourceDevice == nil {
                    /* screen capture video source*/
                    videoSource.adaptOutputFormat(toWidth: Int32(Int(UIScreen.main.bounds.size.width)), height: Int32(UIScreen.main.bounds.size.height), fps: 30)
                }
                else {
                    let trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(videoSourceDevice!.activeFormat.formatDescription, usePixelAspectRatio: true, useCleanAperture: true)
                    self.videoSource.adaptOutputFormat(toWidth: Int32(trackDimensions.height),
                                                       height: Int32(trackDimensions.width),
                                                       fps: 30)
                }
                
                let newCapturer = VideoCapturerFactory.videoCapturer(videoSourceDevice, delegate: self)
                newCapturer.delegate = nil
                newCapturer.startCapture({error in
                    guard error == nil else {
                        //restore capturing previous capturer
                        self.videoCapturer.startCapture(completionHandler)
                        completionHandler?(error)
                        return
                    }
                    if #available(iOS 13.0, *) {
                        let captureSessionConnections = newCapturer.getCaptureSession().connections
                        captureSessionConnections.first?.videoOrientation = .portrait
                    }
                    
                    newCapturer.delegate = self
                    
                    completionHandler?(error)
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
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.videoSource?.capturer(capturer, didCapture: frame)
    }
}
