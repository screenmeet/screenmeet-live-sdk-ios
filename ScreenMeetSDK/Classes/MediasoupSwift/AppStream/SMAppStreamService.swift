//
//  SMAppStreamService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 22.01.2021.
//

import Foundation
import WebKit
import ReplayKit

enum SMAppStreamServiceError: Error {
    case startCaptureFailed
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
}

class SMAppStreamService {
    
    private var frameProcessor = SMFrameProcessor()
    
    private let screenRecorder = RPScreenRecorder.shared()
    
    func startStream(completion: @escaping (Result<CVPixelBuffer, SMAppStreamServiceError>) -> Void) {
        guard !screenRecorder.isRecording else { return }
        
        screenRecorder.startCapture(handler: { [weak self] (sampleBuffer, sampleBufferType, error) in
            guard sampleBufferType == .video else { return }
            guard error == nil else { return }
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            self?.frameProcessor.processFrame(pixelBuffer: pixelBuffer) { (pixelBuffer) in
                completion(.success(pixelBuffer))
            }
        }, completionHandler: { (error) in
            if error != nil {
                completion(.failure(.startCaptureFailed))
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
}
