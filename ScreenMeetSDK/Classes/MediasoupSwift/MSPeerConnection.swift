//
//  MSPeerConnection.swift
//  ScreenMeet
//
//  Created by Ross on 31.01.2021.
//

import UIKit
import WebRTC

typealias MSPeerConnectionCreateOfferCompletion = (String?, MSError?) -> Void
typealias MSPeerConnectionCreateAnswerCompletion = (String?, MSError?) -> Void
typealias MSPeerConnectionSetRemoteDescriptionCompletion = (MSError?) -> Void
typealias MSPeerConnectionSetLocalDescriptionCompletion = (MSError?) -> Void
typealias MSPeerConnectionGetStatsCompletion = (RTCStatisticsReport) -> Void

typealias MSPeerConnectionIceConnectionStateChangedCallback = (RTCIceConnectionState) -> Void

class MSPeerConnection: NSObject {
    private var iceConnectionStateChangedCallback: MSPeerConnectionIceConnectionStateChangedCallback?
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var pc: RTCPeerConnection!
    
    struct Options {
        var config: RTCConfiguration!
        var factory: RTCPeerConnectionFactory?
    }
    
    enum SdType: Int {
        case offer = 0
        case pranswer
        case answer
    }
    
    static var sdpType2String: [SdType: String] = [.offer: "offer", .pranswer: "pranswer", .answer: "answer"]
    static var iceConnectionState2String: [RTCIceConnectionState: String] = [.new: "new", .checking: "checking", .completed: "completed", .connected: "connected", .failed: "failed", .disconnected: "disconnected", .closed: "closed"]
    static var iceGatheringState2String: [RTCIceGatheringState: String] = [.new: "new", .gathering: "gathering", .complete: "complete"]
    
    static var signalingState2String: [RTCSignalingState: String] = [.stable: "stable", .haveLocalOffer: "have-local-offer", .haveLocalPrAnswer: "have-local-pranswer", .haveRemoteOffer: "have-remote-offer", .haveRemotePrAnswer: "have-remote-pranswer", .closed: "closed"]
    
    static var peerConnectionState = ["New", "Connecting", "Connected", "Disconnected", "Failed", "Closed"]
    
    init(_ options: Options?, _ callback: MSPeerConnectionIceConnectionStateChangedCallback? = nil) {
        super.init()
        
        self.iceConnectionStateChangedCallback = callback
        var config = RTCConfiguration()
        
        if let options = options {
            config = options.config
        }

        // PeerConnection factory provided.
        if let options = options, let factory = options.factory {
            self.peerConnectionFactory = factory
        }
        else {
            let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
            
            /*
            if let codecInformation = (RTCDefaultVideoEncoderFactory.supportedCodecs().first { $0.name.elementsEqual("VP8") }) {
                videoEncoderFactory.preferredCodec = codecInformation
            }*/
            
            self.peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: RTCDefaultVideoDecoderFactory())
        }
               
        // Set SDP semantics to Unified Plan.
        config.sdpSemantics = .unifiedPlan
        config.iceTransportPolicy = .all
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require

        // Create the webrtc::Peerconnection.
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        pc = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }
    
    func close() {
        pc.close()
    }
    
    func getConfiguration() -> RTCConfiguration {
        return pc.configuration
    }
    
    func setConfiguration(_ config: RTCConfiguration) -> Bool {
        let result = pc.setConfiguration(config)

        if result {
            return true
        }

        NSLog("PeerConnection.SetConfiguration failed")

        return false
    }
    
    func createOffer(_ constraints: RTCMediaConstraints, completion: @escaping MSPeerConnectionCreateOfferCompletion) {
        pc.offer(for: constraints) { sessionDescription, error in
            if let sdp = sessionDescription?.sdp {
                completion(sdp, nil)
            }
            else {
                completion(nil, MSError(type: .peerConnection, message: error!.localizedDescription))
        
            }
        }
    }
    
    func createAnswer(_ constraints: RTCMediaConstraints, _ completion: @escaping MSPeerConnectionCreateAnswerCompletion) {
        pc.answer(for: constraints) { sessionDescription, error in
            if let sdp = sessionDescription?.sdp {
                completion(sdp, nil)
            }
            else {
                completion(nil, MSError(type: .peerConnection, message: error!.localizedDescription))
            }
        }
    }
    
    func setLocalDescription(_ type: RTCSdpType, _ sdp: String, _ completion: @escaping MSPeerConnectionSetLocalDescriptionCompletion) {
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)

        pc.setLocalDescription(sessionDescription) { error in
            if let error = error {
                completion(MSError(type: .peerConnection, message: error.localizedDescription))
            }
            else {
                completion(nil)
            }
        }
    }

    
    func setRemoteDescription(_ type: RTCSdpType,
                              _ sdp: String,
                              _ completion: @escaping MSPeerConnectionSetRemoteDescriptionCompletion) {
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)

        pc.setRemoteDescription(sessionDescription) { error in
            if let error = error {
                completion(MSError(type: .peerConnection, message: error.localizedDescription))
            }
            else {
                completion(nil)
            }
        }
        
        
    }

    func getLocalDescription() -> String {
        let description = pc.localDescription
        return description!.sdp
    }

    func getRemoteDescription() -> String{
        let description = pc.remoteDescription
        return description!.sdp
    }

    func getTransceivers() -> [RTCRtpTransceiver] {
        return pc.transceivers
    }

    func addTransceiver(_ mediType: RTCRtpMediaType) -> RTCRtpTransceiver {
        let transceiver: RTCRtpTransceiver = pc.addTransceiver(of: mediType)
        transceiver.sender.streamIds = ["0"]
        return transceiver
    }
    
    func getPeeer() -> RTCPeerConnection {
        return pc
    }
    
    func addTransceiver(_ track: RTCMediaStreamTrack, _ initObject: RTCRtpTransceiverInit) -> RTCRtpTransceiver {
        /*
        * Define a stream id so the generated local description is correct.
        * - with a stream id:    "a=ssrc:<ssrc-id> mslabel:<value>"
        * - without a stream id: "a=ssrc:<ssrc-id> mslabel:"
        *
        * The second is incorrect (https://tools.ietf.org/html/rfc5576#section-4.1)
        */
        
        initObject.streamIds = ["0"]
        
        
        let transceiver: RTCRtpTransceiver = pc.addTransceiver(with: track, init: initObject)
        //transceiver.sender.parameters.encodings = initObject.sendEncodings
        return transceiver
    }
    
    func getSenders() -> [RTCRtpSender] {
        return pc.senders
    }

    func removeTrack(_ sender: RTCRtpSender) -> Bool {
        return pc.removeTrack(sender)
    }

    func getStats(_ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        pc.statistics { report in
            completion(report)
        }
    }
    
    func getStats(_ sender: RTCRtpSender, _ completion:  @escaping MSPeerConnectionGetStatsCompletion) {
        pc.statistics(for: sender) { report in
            completion(report)
        }
    }
    
    func getStats(_ receiver: RTCRtpReceiver, _ completion:  @escaping MSPeerConnectionGetStatsCompletion) {
        pc.statistics(for: receiver) { report in
            completion(report)
        }
    }
    
    deinit {
        NSLog("Deinit")
    }
}

extension MSPeerConnection: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        NSLog("[MS ICE] peer connection changed state: " + MSPeerConnection.peerConnectionState[newState.rawValue])
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        NSLog("[MS ICE] signalling state: " + MSPeerConnection.signalingState2String[stateChanged]!)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        NSLog("[MS ICE] Did add stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        NSLog("[MS ICE] Did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        NSLog("[MS ICE] Should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        NSLog("[MS ICE] Ice connection state: " + MSPeerConnection.iceConnectionState2String[newState]!)
        iceConnectionStateChangedCallback?(newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        NSLog("[MS ICE] Ice gathering state: " + MSPeerConnection.iceGatheringState2String[newState]!)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        NSLog("[MS ICE] Did generate ICE candidate: " + candidate.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        NSLog("[MS ICE] Did remove ICE candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        NSLog("[MS ICE] Did open data channel")
    }
}
