//
//  MSConsumer.swift
//  ScreenMeet
//
//  Created by Ivan Makhnyk on 01.02.2021.
//

import Foundation
import WebRTC

class MSConsumer: NSObject {
    private var privateDelegate: MSConsumerPrivateDelegate
    private var delegate: MSConsumerDelegate
    private var id: String!
    private var localId: String!
    private var producerId: String!
    private var closed: Bool = false
    // Associated RTCRtpReceiver.
    private var rtpReceiver: RTCRtpReceiver!
    // Local track.
    private var track: RTCMediaStreamTrack!
    // RTP parameters.
    private var rtpParameters: MSJson!
    // Paused flag.
    private var paused: Bool = false
    // App custom data.
    private var appData: MSJson! = nil
    
    init(_ privateDelegate: MSConsumerPrivateDelegate,
         _ delegate: MSConsumerDelegate,
         _ id: String,
         _ localId: String,
         _ producerId: String,
         _ rtpReceiver: RTCRtpReceiver,
         _ track: RTCMediaStreamTrack,
         _ rtpParameters: MSJson!,
         _ appData: MSJson?) {
        self.privateDelegate = privateDelegate
        self.delegate = delegate
        self.id = id
        self.localId = localId
        self.producerId = producerId
        self.rtpReceiver = rtpReceiver
        self.track = track
        self.rtpParameters = rtpParameters
        self.appData = appData
    }
    
    public func getId() -> String {
        return self.id
    }
    public func getLocalId() -> String {
        return self.localId
    }
    public func getProducerId() -> String {
        return self.producerId
    }

    public func isClosed() -> Bool {
        return self.closed
    }

    public func getKind() -> String {
        return self.track.kind
    }

    func getRtpReceiver() -> RTCRtpReceiver! {
        return self.rtpReceiver
    }
    
    func getTrack() -> RTCMediaStreamTrack! {
        return self.track
    }

    func getRtpParameters() -> MSJson! {
        return self.rtpParameters
    }
    
    func getAppData() -> MSJson! {
        return self.appData
    }
    
    func close() -> Void {
        if (self.closed) {
            return
        }

        self.closed = true;

        self.privateDelegate.onClose(consumer: self);
    }
    
    func getStats(_ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        if (self.closed) {
            // MSC_THROW_INVALID_STATE_ERROR("Consumer closed");
            return
        }
        
        self.privateDelegate.onGetStats(consumer: self, completion)
    }
    
    func pause() -> Void {
        if (self.closed){
            print("Consumer paused")
            return
        }
        self.track.isEnabled = false
    }
    
    func resume() -> Void {
        if (self.closed){
            print("Consumer resumed")
            return
        }
        self.track.isEnabled = true
    }
    
    func transportClosed() -> Void {
        if (self.closed) {
            return
        }
        print("Consumer transportClosed")
        self.closed = true
        self.delegate.onTransportClose(consumer: self)
    }
    
    deinit {
        NSLog("[MS] Consumer dealloced")
    }
    
}

protocol MSConsumerPrivateDelegate {
    func onClose(consumer: MSConsumer) -> Void
    func onGetStats(consumer: MSConsumer,  _ completion: @escaping MSPeerConnectionGetStatsCompletion)
}

/* Public Listener API */
protocol MSConsumerDelegate {
    func onTransportClose(consumer: MSConsumer) -> Void
}
