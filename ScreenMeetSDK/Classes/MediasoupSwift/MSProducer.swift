//
//  MSProducer.swift
//  ScreenMeet
//
//  Created by Ross on 31.01.2021.
//

import UIKit
import WebRTC

protocol MSProducerPrivateDelegate: class {
    func onClose(_ producer: MSProducer)
    func onReplaceTrack(_ producer: MSProducer, _ newTrack: RTCMediaStreamTrack)
    func onSetMaxSpatialLayer(_ producer: MSProducer, _ maxSpatialLayer: UInt8)
    func onGetStats(_ producer: MSProducer, _ completion: @escaping MSPeerConnectionGetStatsCompletion)
}

protocol MSProducerDelegate: class {
    func onTransportClose(_ producer: MSProducer)
}

class MSProducer: NSObject {
    
    // PrivateListener instance.
    weak var privateDelegate: MSProducerPrivateDelegate!
    
    // Public Listener instance.
    weak var delegate: MSProducerDelegate!
    
    // Id.
    var id: String!
    
    // localId.
    var localId: String!
    
    // Closed flag.
    var closed: Bool = false
    
    // Associated RTCRtpSender.
    var rtpSender: RTCRtpSender!
    
    // Local track.
    var track: RTCMediaStreamTrack!
    
    // RTP parameters.
    var rtpParameters: MSJson!
    
    // Paused flag.
    var paused = false
    
    // Video Max spatial layer.
    var maxSpatialLayer: UInt8 = 0
    
    // App custom data.
    var appData: MSJson!
    
    init(
        _ privateDelegate: MSProducerPrivateDelegate,
        _ delegate: MSProducerDelegate,
        _ id: String,
        _ localId: String,
        _ rtpSender: RTCRtpSender,
        _ track: RTCMediaStreamTrack,
        _ rtpParameters: MSJson,
        _ appData: MSJson?) {
        
        self.id = id
        self.privateDelegate = privateDelegate
        self.delegate = delegate
        self.localId = localId
        self.rtpSender = rtpSender
        self.track = track
        self.rtpParameters = rtpParameters
        self.appData = appData
        super.init()
    }
    
    func getId() -> String! {
        self.id
    }
    
    func getLocalId() -> String! {
        self.localId
    }
    func isClosed() -> Bool {
        self.closed
    }
    
    func getKind() -> String {
        self.track.kind
    }
    
    func getRtpSender() -> RTCRtpSender {
        self.rtpSender
    }
    
    func getTrack() -> RTCMediaStreamTrack {
        self.track
    }
    
    func getRtpParameters() -> MSJson! {
        self.rtpParameters
    }
    
    func isPaused() -> Bool {
        self.track.isEnabled
    }
    
    func getMaxSpatialLayer() -> UInt8 {
        self.maxSpatialLayer
    }
    
    func getAppData() -> MSJson! {
        self.appData
    }
    
    func close() {
        if (self.closed) {
            return
        }
        self.closed = true
        self.privateDelegate.onClose(self)
    }
    
    func getStats(_ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        if (self.closed) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("Producer closed");
            return
        }
        
        self.privateDelegate.onGetStats(self, completion)
    }
    
    func pause() {
        if (self.closed) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("Producer closed");
            return
        }
        self.track.isEnabled = false
    }
    
    func resume() {
        if (self.closed) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("Producer closed");
            return
        }
        self.track.isEnabled = true
    }
    
    func replaceTrack(_ track: RTCMediaStreamTrack) {
        if (self.closed) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("Producer closed");
            return
        }
        if (self.track == nil) {
            // TODO throw error
            // MSC_THROW_TYPE_ERROR("missing track");
            return
        }
        if (self.track.readyState == RTCMediaStreamTrackState.ended) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("track ended");
            return
        }
        
        // Do nothing if this is the same track as the current handled one.
        if (track == self.track) {
            //MSC_DEBUG("same track, ignored");
            return
        }

        // May throw.
        self.privateDelegate.onReplaceTrack(self, track)
        
        // Keep current paused state.
        let paused = self.isPaused()
        
        // Set the new track.
        self.track = track
        
        // If this Producer was paused/resumed and the state of the new
        // track does not match, fix it.
        if (!paused) {
            self.track.isEnabled = true
        } else {
            self.track.isEnabled = false
        }
    }
    
    func setMaxSpatialLayer(_ spatialLayer: UInt8) {
        if (self.closed) {
            // TODO throw error
            // MSC_THROW_INVALID_STATE_ERROR("Producer closed");
            return
        }
        if (self.track == nil) {
            // TODO throw error
            // MSC_THROW_TYPE_ERROR("missing track");
            return
        }
        if (self.track.kind != "video") {
            // TODO throw error
            //MSC_THROW_TYPE_ERROR("not a video Producer");
            return
        }
        
        if (spatialLayer == self.maxSpatialLayer) {
            return;
        }

        // May throw.
        self.privateDelegate.onSetMaxSpatialLayer(self, spatialLayer)

        self.maxSpatialLayer = spatialLayer
    }
    
    func transportClosed() {
        if (self.closed) {
            return
        }
        self.closed = true
        self.delegate.onTransportClose(self)
    }
}
