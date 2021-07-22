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
    
    static let session = SMSession()

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
    /// - Parameter localUserName: The name of your local user. It will be visible to all attendees
    /// - Parameter completion: Session start callback with status `SMConnectCompletion`
    public static func connect(_ code: String,
                               _ localUserName: String,
                               _ completion: @escaping SMConnectCompletion) {
        session.connect(code, localUserName, completion)
    }
    
    /// Close screenmeet session and hangup.
    public static func disconnect() {
        session.disconnect()
    }
    
    /// Get caller audio/video states
    public static func getMediaState() -> SMParticipantMediaState {
        return session.getAVState()
    }

    /// Start camera sharing
    /// - Parameter cameraDevice: Device to capture frames (see `AVCaptureDevice`). Default is front camera.
    public static func shareCamera(_ cameraDevice: AVCaptureDevice!) {
        if let device = cameraDevice {
            session.startVideoSharing(device)
        } else {
            session.startVideoSharing(AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first!)
        }
    }

    /// Start screen sharing
    public static func shareScreen() {
        session.startScreenSharing()
    }

    /// Stop video sharing
    public static func stopVideoSharing() {
        session.stopVideoSharing()
    }
    
    /// Start audio sharing
    public static func shareMicrophone() {
        session.startAudioSharing()
    }
    
    /// Stop audio sharing
    public static func stopAudioSharing() {
        session.stopAudioSharing()
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
    
    /// Returns SMAppStreamServiceProtocol. See `SMAppStreamServiceProtocol`
    public static func getAppStreamService() -> SMAppStreamServiceProtocol {
        session.getAppStreamService()
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
public enum SMConnectionState: Equatable, CustomStringConvertible {
    
    /// Client is in initial connecting state
    case connecting
    
    /// Client successfully connected (Connection is active)
    case connected
    
    /// Client is reconnecting
    case reconnecting

    /// Client is disconnected or state before initial connection
    case disconnected(_ value: SMDisconnectionReason)
    
    /// Client is waiting for entrance permission (knock feature)
    case waitingEntrancePermission
    
    public static func ==(l: SMConnectionState, r: SMConnectionState) -> Bool {
        switch (l, r) {
        case (.connecting, .connecting):
            return true
        case (.connected, .connected):
            return true
        case (.reconnecting, .reconnecting):
            return true
        case (.waitingEntrancePermission, .waitingEntrancePermission):
            return true
        case let (.disconnected(v0), .disconnected(v1)):
            return v0 == v1
        default:
            return false
        }
    }
    
    public var description : String {
      switch self {
          case .connecting: return "connecting"
          case .connected: return "connected"
          case .reconnecting: return "reconnecting"
          case .disconnected: return "disconnected"
          case .waitingEntrancePermission: return "waitingEntrancePermission"
      }
    }
}

/// Call disconnection reason
public enum SMDisconnectionReason {
    /// Call is finished
    case callEndedByServer

    /// Client left call
    case leftCall

    /// Network error
    case networkError
    
    /// Initial state before session is started
    case callNotStarted
    
    /// Wait time expired (knock feature)
    case knockWaitTimeExpired
    
    /// Wait time expired (could not reconnect after network loss)
    case reconnectWaitTimeExpired
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

