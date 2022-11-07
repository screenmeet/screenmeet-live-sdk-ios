//
//  SMAppStreamService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 22.01.2021.
//

import Foundation
import WebKit
import ReplayKit
import WebRTC

enum SMAppStreamServiceError: Error {
    case startCaptureFailed(error: Error)
    case stopCaptureFailed
}

public protocol SMAppStreamServiceProtocol {
    
    /// Set confidential view
    /// - Parameter view: Confidential view
    func setConfidential<T>(view: T) where T : UIView
    
    /// Unset confidential view
    /// - Parameter view: Confidential view
    func unsetConfidential<T>(view: T) where T : UIView
    
    /// Set confidential view
    /// - Parameter view: Confidential view
    func setConfidential<T>(webView: T) where T : WKWebView
    
    /// Unset confidential view
    /// - Parameter view: Confidential view
    func unsetConfidential<T>(webView: T) where T : WKWebView
    
    func setConfidential(rect: CGRect)
    
    func unsetConfidential(rect: CGRect)
}

class SMAppStreamService: NSObject {
    
    private var frameProcessor = SMFrameProcessor()
    
    let screenRecorder = RPScreenRecorder.shared()
    
    func startStream(_ startHandler: SMCapturerOperationCompletion?, completion: @escaping (Result<CVPixelBuffer, SMAppStreamServiceError>) -> Void) {
        guard !screenRecorder.isRecording else { return }
        screenRecorder.delegate = self
        if #available(iOS 16.0, *) {
         
        } else {
            RTCAudioSession.sharedInstance().lockForConfiguration()
                do {
                    try RTCAudioSession.sharedInstance().setCategory(AVAudioSession.Category.record.rawValue)
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                } catch let error {
                    debugPrint("Error changeing AVAudioSession category: \(error)")
                }
            RTCAudioSession.sharedInstance().unlockForConfiguration()
        }
       
        screenRecorder.startCapture(handler: { [weak self] (sampleBuffer, sampleBufferType, error) in
            guard sampleBufferType == .video else { return }
            guard error == nil else {
                return
            }
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            self?.frameProcessor.processFrame(pixelBuffer: pixelBuffer) { (pixelBuffer) in
                completion(.success(pixelBuffer))
            }
        }, completionHandler: { (error) in
            
            if #available(iOS 16.0, *) {
             
            }
            else {
                RTCAudioSession.sharedInstance().lockForConfiguration()
                    do {
                        try RTCAudioSession.sharedInstance().setCategory(AVAudioSession.Category.multiRoute.rawValue)
                    } catch let error {
                        debugPrint("Error changeing AVAudioSession category: \(error)")
                    }
                RTCAudioSession.sharedInstance().unlockForConfiguration()
            }
            
            if error != nil {
                completion(.failure(.startCaptureFailed(error: error!)))
            }
            else {
                startHandler?(nil)
            }
        })
    }
    
    func stopStream(completion: @escaping (Result<Void, SMAppStreamServiceError>) -> Void) {
        guard screenRecorder.isRecording else { return }
        
        screenRecorder.stopCapture { (error) in
            if error != nil {
                completion(.failure(.stopCaptureFailed))
            } else {
                completion(.success(()))
            }
        }
    }
}

extension SMAppStreamService: SMAppStreamServiceProtocol {
    
    func setConfidential<T>(view: T) where T : UIView {
        frameProcessor.confidentialViews.removeAll(where: { $0.isEmpty })
        guard !frameProcessor.confidentialViews.contains(where: { $0 == view }) else { return }
        
        frameProcessor.confidentialViews.append(SMConfidentialView(view))
    }
    
    func unsetConfidential<T>(view: T) where T : UIView {
        frameProcessor.confidentialViews.removeAll(where: { $0 == view || $0.isEmpty })
    }
    
    func setConfidential<T>(webView: T) where T : WKWebView {
        frameProcessor.confidentialWebViews.removeAll(where: { $0.isEmpty })
        guard !frameProcessor.confidentialWebViews.contains(where: { $0 == webView }) else { return }
        
        frameProcessor.confidentialWebViews.append(SMConfidentialWebView(webView))
    }
    
    func unsetConfidential<T>(webView: T) where T : WKWebView {
        frameProcessor.confidentialWebViews.removeAll(where: { $0 == webView || $0.isEmpty })
    }
    
    func setConfidential(rect: CGRect) {
        frameProcessor.confidentialRects.removeAll(where: { $0.isEmpty })
        guard !frameProcessor.confidentialRects.contains(where: { $0 == rect }) else { return }
        
        frameProcessor.confidentialRects.append(SMConfidentialRect(rect))
    }
    
    func unsetConfidential(rect: CGRect) {
        frameProcessor.confidentialRects.removeAll(where: { $0 == rect || $0.isEmpty })
    }
}

extension SMAppStreamService: RPScreenRecorderDelegate {
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        NSLog("Error: " + error!.localizedDescription)
    }
    
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
    }
    
}
