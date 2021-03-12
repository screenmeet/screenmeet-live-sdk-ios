//
//  ScreenMeet.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import Foundation
import UIKit
import WebRTC


// MARK: Main
/// Main class to work with ScreenMeet SDK
public class ScreenMeet: NSObject {
    
    private static let session = SMSession()

    /// ScreenMeet Configuration
    public static let config = ScreenMeetConfig()

    /// Session delegate. Should be set before calling connect()
    public static weak var delegate: ScreenMeetDelegate? {
        didSet {
            session.delegate = delegate
        }
    }
    
    /// Starts ScreenMeet session. No code specified, user will be asked to enter code value
    /// - Parameter code: Identify session created by agent
    /// - Parameter videoSourceDevice: New video source device to capture frames (see `AVCaptureDevice`)
    /// - Parameter completion: Session start callback with status `SMConnectCompletion`
    public static func connect(_ code: String,
                        _ videoSourceDevice: AVCaptureDevice! = nil,
                        _ completion: @escaping SMConnectCompletion) {
        session.connect(code, videoSourceDevice, completion)
    }
    
    /// Video Source types
    public enum VideoSourceType {
        /// Back camera as video source device
        case backCamera
        /// Front camera as video source device
        case frontCamera
        /// Screen capturing as video source device
        case screen
    }

    /// Starts ScreenMeet session. No code specified, user will be asked to enter code value
    /// - Parameter code: Identify session created by agent
    /// - Parameter videoSource: New video source that session should use. See `ScreenMeet.VideoSourceType`
    /// - Parameter completion: Session start callback with status `SMConnectCompletion`
    public static func connect(_ code: String,
                        _ videoSource: VideoSourceType,
                        _ completion: @escaping SMConnectCompletion) {
        var videoSourceDevice: AVCaptureDevice! = nil
        switch videoSource {
            case .backCamera:
                videoSourceDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
            case .frontCamera:
                videoSourceDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
            default:
                videoSourceDevice = nil
        }
        session.connect(code, videoSourceDevice, completion)
    }
    
    /// Close screenmeet session and hangup.
    /// - Parameter completion: Session start callback with status `SMConnectCompletion`
    public static func disconnect(_ completion: @escaping SMDisconnectCompletion) {
        session.disconnect(completion)
    }
    
    /// Is Audio stream active (is unmuted)
    public static func isAudioActive() -> Bool {
        return session.getAudioEnabled()
    }
    
    /// Is Video stream active (is unmuted)
    public static func isVideoActive() -> Bool {
        return session.getVideoEnabled()
    }
        
    /// Toggle mute|unmute state for video
    public static func toggleLocalVideo() {
        session.toggleLocalVideo()
    }
    
    /// Toggle mute|unmute state for audio
    public static func toggleLocalAudio() {
        session.toggleLocalAudio()
    }
    
    /// Change source of video stream
    /// - Parameter to: New video source that session should use. See `ScreenMeet.VideoSourceType`
    /// - Parameter completionHandler: Handle error during source switch
    public static func changeVideoSource(_ to: VideoSourceType, _ completionHandler: SMCaptureCompletion? = nil) {
        session.changeVideoSource(to, completionHandler)
    }
    
    /// Change source of video stream
    /// - Parameter to: New video source device to capture frames (see `AVCaptureDevice`)
    /// - Parameter completionHandler: Handle error during source switch
    public static func changeVideoSourceDevice(_ to: AVCaptureDevice!, _ completionHandler: SMCaptureCompletion? = nil) {
        session.changeVideoSourceDevice(to, completionHandler)
    }
    
    /// Returns current video source device.
    /// `nil` for screen capturing
    public static func getVideoSourceDevice() -> AVCaptureDevice! {
        return session.getVideoSourceDevice()
    }
    
    /// Returns list of call participants. See `SMParticipant`
    public static func getParticipants() -> [SMParticipant] {
        return session.getParticipants()
    }
    
    /// Returns connection state. This is basically the signalling socket state. See `SMConnectionState`
    public static func getConnectionState() -> SMConnectionState {
        return session.getConnectionState()
    }
    
}


/// ScreenMeet Configuration
public class ScreenMeetConfig {
    
    /// Organization key to access API
    open var organizationKey: String? = nil
    
    /// Initial connection endpoint/port
    open var endpoint: URL = URL(string: "https://edge.screenmeet.com")!
    
    /// Additional parameters to configure framework
    open var parameters: [String: Any] = [:]
    
    /// Represent the severity and importance of log messages ouput (`.info`, `.debug`, `.error`, see `LogLevel`)
    open var loggingLevel: LogLevel = .error {
        didSet {
            switch loggingLevel {
            case .info:
                SMLogger.log.level = .info
            case .debug:
                SMLogger.log.level = .debug
            case .error:
                SMLogger.log.level = .error
            }
        }
    }

    /// Represent the severity and importance of any particular log message.
    public enum LogLevel {
        /// Information that may be helpful, but isn’t essential, for troubleshooting errors
        case info
        /// Verbose information that may be useful during development or while troubleshooting a specific problem
        case debug
        /// Designates error events that might still allow the application to continue running
        case error
    }
    
    /// HTTP connection timeout. Provided in seconds. Default 30s.
    open var httpTimeout: TimeInterval = 30 {
        didSet {
            if httpTimeout < 0 {
                httpTimeout = 30
            }
        }
    }
    
    /// HTTP connection retry number. Default 5 retries.
    open var httpNumRetry: Int = 5 {
        didSet {
            if httpNumRetry < 0 {
                httpNumRetry = 5
            }
        }
    }
    
    /// Socket connection timeout. Provided in seconds. Default 20s.
    open var socketConnectionTimeout: TimeInterval = 20 {
        didSet {
            if socketConnectionTimeout < 0 {
                socketConnectionTimeout = 20
            }
        }
    }
    
    /// Socket connection retry number. Default 5 retries.
    open var socketConnectionNumRetries: Int = 5 {
        didSet {
            if socketConnectionNumRetries < 0 {
                socketConnectionNumRetries = 5
            }
        }
    }
    
    /// Socket reconnection retry number. Default unlimited retries. For unlimited set -1.
    open var socketReconnectNumRetries: Int = -1 {
        didSet {
            if socketReconnectNumRetries < -1 {
                socketReconnectNumRetries = -1
            }
        }
    }
    
    /// Socket reconnection delay. Provided in seconds. Default 0s.
    open var socketReconnectDelay: TimeInterval = 0 {
        didSet {
            if socketReconnectDelay < 0 {
                socketReconnectDelay = 0
            }
        }
    }
    
    /// WebRTC connection timeout. Provided in seconds. Default 60s.
    open var webRtcTimeout: TimeInterval = 60 {
        didSet {
            if webRtcTimeout < 0 {
                webRtcTimeout = 60
            }
        }
    }
    
    /// WebRTC connection retry number. Default 5 retries.
    open var webRtcNumRetries: Int = 5 {
        didSet {
            if webRtcNumRetries < 0 {
                webRtcNumRetries = 5
            }
        }
    }
}

/// Represents current connection state
public enum SMConnectionState: Int {
    
    /// Client is in initial connecting state
    case connecting = 0
    
    /// Client successfully connected (Connection is active)
    case connected = 1

    /// Client is disconnected or state before initial connection
    case disconnected = 2
}

enum SMIceConnectionState: String {
    case new = "new"
    case disconnected = "disconnected"
    case failed = "failed"
    case checking = "checking"
    case connected = "connected"
    case completed = "completed"
    case closed = "closed"
}
