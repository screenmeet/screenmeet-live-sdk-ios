//
//  SMMediasoupChannel.swift
//  ScreenMeet
//
//  Created by Ross on 14.01.2021.
//

import UIKit
import WebRTC
import SocketIO

typealias SMAudioOperationCompletion = (SMError?) -> Void
typealias SMVideoOperationCompletion = (SMError?, RTCVideoTrack?) -> Void
typealias SMCapturerOperationCompletion = (SMError?) -> Void

struct ConsumeOperation: Equatable {
    var kind: String
    var id: String
    var producerKey: String
    var producerId: String
    var rtpParameters: MSJson
    
    static func == (lhs: ConsumeOperation, rhs: ConsumeOperation) -> Bool {
        return lhs.kind == rhs.kind && lhs.id == rhs.id && lhs.producerId == rhs.producerId
    }
}

protocol ProduceOperation {
    
}

struct AudioOperation: ProduceOperation {
    var isEnabled: Bool
    var completion: SMAudioOperationCompletion
}

struct VideoOperation: ProduceOperation {
    var isEnabled: Bool
    var device: AVCaptureDevice?
    var completion: SMVideoOperationCompletion
}

struct ChangeCapturerOperation: ProduceOperation {
    var device: AVCaptureDevice?
    var isImageTransfer: Bool
    var completion: SMCapturerOperationCompletion?
}

struct StopCapturerOperation: ProduceOperation {
    var completion: SMCapturerOperationCompletion?
}

class SMMediasoupChannel: NSObject, SMChannel  {
    private var mediasoupTransportOptions: SMTransportOptions!
    private var tracksManager = SMTracksManager()
    
    private var shouldCreateVideoTrackAfterReconnect = false
    private var shouldCreateAudioTrackAfterReconnect = false
    
    private var device: MSDevice!
    private var sendTransport: MSSendTransport!
    private var recvTransport: MSRecvTransport!
    private var producers = [String: MSProducer]()
    private var consumers = [String: [MSConsumer]]()
    
    private let consumersQueue = DispatchQueue(label: "mediasoup.consumers.serial.queue")
    private let consumersGroup = DispatchGroup()
    
    private let producersQueue = DispatchQueue(label: "mediasoup.producers.serial.queue", qos: .userInitiated)
    //private let producersGroup = DispatchGroup()

    private var consumeOperations = [ConsumeOperation]()
    private var produceOperations = [ProduceOperation]()
    
    private var currentConsumerOperation: ConsumeOperation!
    private var currentProducerOperation: ProduceOperation!
    
    private var transactionCompletion: StartWebRTCTransactionCompletion? = nil
    
    private var newActiveSpeakerIdToSend: String? = nil
    private var currentActiveSpeakerId: String? = nil

    /// SMChannel protocol
    
    var name: SMChannelName = .mediasoup
    
    func processEvent(_ message: SMChannelMessage) {
     
    }
    
    func buildState(from initialPayload: [String: Any]) {
        
    }
    
    /// Signalling
    
    func startTransportAndChannels(_ turnConfig: SMTurnConfiguration,
                                   _ completion: @escaping StartWebRTCTransactionCompletion) {
        
        
        /* If transports are initialized - we are probably reconnecting now*/
        if (sendTransport != nil && recvTransport != nil) {
            shouldCreateVideoTrackAfterReconnect = getVideoEnabled()
            shouldCreateAudioTrackAfterReconnect = getAudioEnabled()
            
            disconnect()
        }
        
        transport.webSocketClient.command(for: name,
                                          message: "peer",
                                          data: turnConfig) {[weak self] peerData in
            
            SMSocketDataParser().parse(peerData) { (transportOptions: SMTransportOptions?, error) in
                if let error = error {
                    completion(SMError(code: .socketError, message: "Could not parse mediasoup transport options..." + error.message))
                }
                else {
                    self?.device = MSDevice()
                    let routerData = transportOptions!.result.routerRtpCapabilities.socketRepresentation() as! [String: Any]
                    self?.device.load(routerData) { [self] error in
                        if let error = error {
                            NSLog("[MS] Device load failed: " + error.message)
                        }
                        else {
                            NSLog("[MS] Device load sucessful")
                            self?.processRouterRTPCapabilities(transportOptions!, completion)
                        }
                    }
                }
            }
        }
    }
    
    func processRouterRTPCapabilities(_ transportOptions: SMTransportOptions,
                                      _ completion: @escaping StartWebRTCTransactionCompletion) {
        
        self.transactionCompletion = completion
        self.mediasoupTransportOptions = transportOptions
        
        if device.isLoaded() {
            let rtpCapabilities = device.getRtpCapabilities()
            self.transport.webSocketClient.command(for: name, message: "set-capabilities", data: rtpCapabilities) { [self] data in
                
                self.createTransports()
                
                self.transport.webSocketClient.command(for: name, message: "recv-all", data: rtpCapabilities) { data in
                    NSLog("Subscribed for all tracks")
                   
                }
            }
        }
        else {
            completion(SMError(code: .transactionInternalError, message: "Mediasoup device could not be loaded with given capabilities"))
        }
    }
    
    func createTransports() {
        createRecvTransport()
        createSendTransport()
        
        let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        channel.setInitialCallerState()
    }

    func createSendTransport() {
        let json = mediasoupTransportOptions.result.inbound.socketRepresentation() as! MSJson
        
        var iceParameters = json["iceParameters"] as! MSJson
        var iceCandidates = json["iceCandidates"] as! MSJsonArray
        var dtlsParameters = json["dtlsParameters"] as! MSJson

        var iceServers = [RTCIceServer]()
        
        self.mediasoupTransportOptions.result.outbound.iceServers.forEach { server in
            iceServers.append(RTCIceServer(urlStrings: [server.urls], username: server.username, credential: server.credential))
        }
        let config = RTCConfiguration()
        config.iceServers = iceServers
        let options = MSPeerConnection.Options(config: config, factory: nil)
        
        device.createSendTransport(self, mediasoupTransportOptions!.result.inbound.id,
                                        &iceParameters,
                                        &iceCandidates,
                                        &dtlsParameters,
                                        nil,
                                        options,
                                        nil) { [self] sendTransport, error in
            if let error = error {
                NSLog("[MS] Could not instantiate transport: " + error.message)
            }
            else {
                self.sendTransport = sendTransport!
                
                checkBothTransportsCreated()
            }
        }
    }
    
    func createRecvTransport() {
        let json = mediasoupTransportOptions.result.outbound.socketRepresentation() as! MSJson
        
        var iceParameters = json["iceParameters"] as! MSJson
        var iceCandidates = json["iceCandidates"] as! MSJsonArray
        var dtlsParameters = json["dtlsParameters"] as! MSJson
        
        var iceServers = [RTCIceServer]()
        
        self.mediasoupTransportOptions.result.inbound.iceServers.forEach { server in
            iceServers.append(RTCIceServer(urlStrings: [server.urls], username: server.username, credential: server.credential))
        }
        let config = RTCConfiguration()
        config.iceServers = iceServers
        let options = MSPeerConnection.Options(config: config, factory: nil)
        
        device.createRecvTransport(self,
                                        mediasoupTransportOptions!.result.outbound.id,
                                        &iceParameters,
                                        &iceCandidates,
                                        &dtlsParameters,
                                        nil,
                                        options,
                                        nil) { [weak self] recvTransport, error in
            if let error = error {
                NSLog("[MS] Could not instantiate transport: " + error.message)
            }
            else {
                self?.recvTransport = recvTransport!
                checkBothTransportsCreated()
            }
        }
    }
    
    func addAudioTrack(_ completion: SMAudioOperationCompletion? = nil) {
        let audioTrack = self.tracksManager.makeAudioTrack()
        
        sendTransport.produce(self, audioTrack, nil, nil, nil) { [weak self] producer, error in
            if let error = error {
                NSLog("Could not create audio track: " + error.message)
                completion?(SMError(code: .mediaTrackError, message: error.message))
            }
            else {
                self?.producers["audio"] = producer
                
                let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setAudioState(true) { error in
                    if let error = error {
                        completion?(error)
                    }
                    else {
                        completion?(nil)
                    }
                }
            }
        }
    }
    
    func addVideoTrack(_ completion: SMVideoOperationCompletion? = nil) {
        let videoTrack = tracksManager.makeVideoTrack()
        videoTrack.isEnabled = false
        let codecOptions = ["videoGoogleStartBitrate": 1000]

        var sourceType = "camera"
        var appData = [ "profile": "camera"]
        
        if tracksManager.videoSourceDevice == nil {
            appData = [ "profile": "screen_share"]
            sourceType = "screen_share"
        }

        let encodings = SMEncodingsBuilder().defaultSimulcastEncodings()
        
        sendTransport.produce(self, videoTrack, encodings, codecOptions, appData) { [weak self] producer, error in
            if let error = error {
                completion?(SMError(code: .mediaTrackError, message: error.message), nil)
                NSLog("Could not create video track: ", error.message)
            }
            else {
                self?.producers["video"] = producer
                
                let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setVideoState(true, sourceType)
                
                self?.tracksManager.startCapturer(self?.tracksManager.videoSourceDevice ?? nil) { error in
                    
                    if let capturerError = error {
                        
                        //this completion is needed to properly fail the pending startVideo operation (that is pending in the queue)
                        completion?(capturerError, nil)
                        
                        // capturer failed, should stop video track
                        self?.setVideoState(false) { error, videoTrack in
                            DispatchQueue.main.async {
                                ScreenMeet.session.delegate?.onLocalVideoStopped()
                                ScreenMeet.session.delegate?.onError(capturerError)
                            }
                        }
                    }
                    else {
                        completion?(nil, videoTrack)
                        videoTrack.isEnabled = true
                    }
                    
                }
            }
        }
    }
    
    
    func consumeTrack(_ trackMessage: SMNewTrackAvailableMessage) {
        let kind: String = trackMessage.consumerParams.kind
        let id: String = trackMessage.producerCid
        let producerId: String = trackMessage.consumerParams.producerId
        let producerKey: String = trackMessage.consumerParams.track
        let rtpParameters: MSJson = trackMessage.consumerParams.rtpParameters.socketRepresentation() as! MSJson
        
        let operation = ConsumeOperation(kind: kind,
                                         id: id,
                                         producerKey: producerKey,
                                         producerId: producerId,
                                         rtpParameters: rtpParameters)
        
        consumeOperations.insert(operation, at: consumeOperations.count)
        
        if currentConsumerOperation == nil {
            queueConsumerOperation()
        }
    }
    
    /// Comminicate events back to delegate
    
    func removeParticipant(_ participantId: String, _ identity: SMIdentityInfo) {
        //Remove all consumers
        consumers[participantId]?.removeAll()
        
        let participant = SMParticipant(id: participantId, identity: identity, callerState: SMCallerState())
        ScreenMeet.session.delegate?.onParticipantLeft(participant)
    }
    
    func notifyParticipantsMediaStateChanged(_ participantId: String, _ newCallerState: SMCallerState) {
        if (newCallerState.videoEnabled == false && newCallerState.screenEnabled == false && newCallerState.screenAnnotationEnabled == false) {
           removeVideoConsumer(participantId)
        }
        
        let participantsChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
        let identity = participantsChannel.getIdentity(participantId)
        
        var participant = SMParticipant(id: participantId, identity: identity ?? SMIdentityInfo(), callerState: newCallerState)
        participant = extendParticipantWithTracks(participant)
        
        
        ScreenMeet.session.delegate?.onParticipantMediaStateChanged(participant)
    }
    
    func handleActiveSpeaker() {
        if let newActiveSpeakerIdToSend = newActiveSpeakerIdToSend {
            
            /* Check if there's a video consumer for active speaker*/
            let array = consumers[newActiveSpeakerIdToSend]
            
            
            let consumer = array?.first(where: { consumer -> Bool in
                consumer.getKind() == "video"
            })
            
            /*If there's a running video consumer for active speaker and previously sent
             active speaker id is not the same (avoid resending same activeSpeaker id again),
             set the active view to a new activeSpeakerId*/
            if consumer != nil && newActiveSpeakerIdToSend != currentActiveSpeakerId {
                let payload = ["_target_cid": newActiveSpeakerIdToSend]
                self.transport.webSocketClient.command(for: .mediasoup, message: "set-active-view", data: payload) { [self] data in
                    NSLog("set-active-view callback")
                    
                    self.currentActiveSpeakerId = newActiveSpeakerIdToSend
                    self.newActiveSpeakerIdToSend = nil
                    
                    var participant = makeParticipant(currentActiveSpeakerId!)
                    participant = extendParticipantWithTracks(participant)
                    
                    ScreenMeet.session.delegate?.onActiveSpeakerChanged(participant)
                }
            }
        }
    }
    
    func extendParticipantWithTracks(_ participant: SMParticipant) -> SMParticipant {
        var extendedParticipant = participant
        let consumers = self.consumers[participant.id]
        
        let audioConsumer = consumers?.first(where: { consumer -> Bool in
            consumer.getKind() == "audio"
        })
        
        let videoConsumer = consumers?.first(where: { consumer -> Bool in
            consumer.getKind() == "video"
        })
        
        let remoteVideoTrack: RTCVideoTrack? = videoConsumer?.getTrack() as? RTCVideoTrack
        let remoteAudioTrack: RTCAudioTrack? = audioConsumer?.getTrack() as? RTCAudioTrack
        
        extendedParticipant.aduioTrack = remoteAudioTrack
        extendedParticipant.videoTrack = remoteVideoTrack
        
        return extendedParticipant
    }
    
    func notifyParticipantVideoCreated(_ participantId: String) {
        let callerStateChannel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        let participantChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
        let callerState = callerStateChannel.getCallerState(participantId)
        let identity = participantChannel.getIdentity(participantId)
        var participant = SMParticipant(id: participantId, identity:
                                            identity ?? SMIdentityInfo(),
                                            callerState: callerState ?? SMCallerState(),
                                            videoTrack: nil,
                                            aduioTrack: nil)
        if (participant.callerState.screenEnabled) {
            transport.webSocketClient.command(for: .mediasoup, message: "set_substream", data: ["_target_cid": participantId, "layer": 0]) { data in
                NSLog("[MS] set_substream 0 for sreenshare of participant \(participantId) called")
            }
        }
        if (participant.callerState.videoEnabled) {
            transport.webSocketClient.command(for: .mediasoup, message: "set_substream", data: ["_target_cid": participantId, "layer": 2]) { data in
                NSLog("[MS] set_substream 2 for video of participant \(participantId) called")
            }
        }
        
        DispatchQueue.main.async { [self] in
            participant = extendParticipantWithTracks(participant)
            
            ScreenMeet.session.delegate?.onParticipantVideoTrackCreated(participant)
        }
    }
    
    func notifyParticipantAudioCreated(_ participantId: String) {
        DispatchQueue.main.async { [self] in
            let callerStateChannel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
            let participantChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
            let callerState = callerStateChannel.getCallerState(participantId)
            let identity = participantChannel.getIdentity(participantId)
            
            var participant = SMParticipant(id: participantId, identity:
                                                identity ?? SMIdentityInfo(),
                                                callerState: callerState ?? SMCallerState(),
                                                videoTrack: nil,
                                                aduioTrack: nil)
            
            participant = extendParticipantWithTracks(participant)
            
            ScreenMeet.session.delegate?.onParticipantAudioTrackCreated(participant)
        }
        
    }
    
    func notifyParticipantJoined(_ participantId: String, _ identity: SMIdentityInfo) {
        DispatchQueue.main.async { [self] in
            var participant = SMParticipant(id: participantId,
                                            identity: identity,
                                            callerState:SMCallerState()) // real callerstate should be deliverd via media state changed right after this call
            
            participant = extendParticipantWithTracks(participant)
            ScreenMeet.session.delegate?.onParticipantJoined(participant)
        }
    }
    
    deinit {
        NSLog("Mediasoup channel was dealloced of channel")
    }
    
    /// Get tracks state
    
    func getVideoEnabled() -> Bool {
        if producers["video"] != nil {
            return true
        }
        
        return false
    }
    
    func getAudioEnabled() -> Bool {
        if producers["audio"] != nil && producers["audio"]!.track.isEnabled == true{
            return true
        }
        
        return false
    }
    
    /// Active Speaker
    
    func setNewActiveSpeakerIdToSend(_ newActiveSpeakerIdToSend: String) {
        self.newActiveSpeakerIdToSend = newActiveSpeakerIdToSend
        handleActiveSpeaker()
    }
    
    /// Outbound
    
    func setVideoState(_ isEnabled: Bool, _ completion: @escaping SMVideoOperationCompletion) {
        /* if there's a pending video operation - do nothing. Just wait till it completes*/
        if let _ = produceOperations.first(where: { operation -> Bool in operation as? VideoOperation != nil }) {
            return
        }
        
        let videoOperation = VideoOperation(isEnabled: isEnabled,
                                            device: tracksManager.videoSourceDevice,
                                            completion: completion)
        produceOperations.append(videoOperation)
        if currentProducerOperation == nil {
            queueProducerOperation()
        }
    }
    
    func setAudioState(_ isEnabled: Bool,  _ completion: @escaping SMAudioOperationCompletion) {
        /* if there's a pending audio operation - do nothing. Just wait till it completes*/
        if let _ = produceOperations.first(where: { operation -> Bool in operation as? AudioOperation != nil }) {
            return
        }
        
        let audioOperation = AudioOperation(isEnabled: isEnabled, completion: completion)
        produceOperations.append(audioOperation)
        if currentProducerOperation == nil {
            queueProducerOperation()
        }
    }
    
    func changeCapturer(_ videoSourceDevice: AVCaptureDevice!, _ isImageTransfer: Bool, completionHandler: SMCapturerOperationCompletion? = nil) {
        /* if there's a pending change capturer operation - do nothing. Just wait till it completes*/
        if let _ = produceOperations.first(where: { operation -> Bool in operation as? ChangeCapturerOperation != nil }) {
            return
        }
        
        let changeCapturerOperation = ChangeCapturerOperation(device: videoSourceDevice, isImageTransfer: isImageTransfer, completion: completionHandler)
        produceOperations.append(changeCapturerOperation)
        if currentProducerOperation == nil {
            queueProducerOperation()
        }
    }
    
    func stopCapturer(completionHandler: SMCapturerOperationCompletion? = nil) {
        /* if there's a pending change capturer operation - do nothing. Just wait till it completes*/
        if let _ = produceOperations.first(where: { operation -> Bool in operation as? StopCapturerOperation != nil }) {
            return
        }
        
        let stopCapturerOperation = StopCapturerOperation(completion: completionHandler)
        produceOperations.append(stopCapturerOperation)
        if currentProducerOperation == nil {
            queueProducerOperation()
        }
    }
    
    func setVideoSourceDevice(_ device: AVCaptureDevice?) {
        tracksManager.videoSourceDevice = device
        tracksManager.shouldUseCustomImageSessionForVideoSharing = false
    }
    
    func getVideoSourceDevice() -> AVCaptureDevice? {
        return tracksManager.videoSourceDevice
    }
    
    func customImageTransferSessionOn() -> Bool {
        return tracksManager.shouldUseCustomImageSessionForVideoSharing
    }
    
    func stopImageTransferSessionIfNeeded() {
        tracksManager.shouldUseCustomImageSessionForVideoSharing = false
    }
    
    func createImageTransferHandler() -> SMImageHandler {
        return tracksManager.createImageTransferHandler()
    }
    
    func disconnect(_ completion: (() -> ())? = nil) {
        tracksManager.cleanupAudio()
        tracksManager.cleanupVideo()
        
        if ScreenMeet.getConnectionState() == .connected {
            transport.webSocketClient.command(for: .mediasoup, message: "video-stopped", data: [String: Any]()) {_ in
                completion?()
            }
        }
        else {
            completion?()
        }

        if (sendTransport != nil) {
            sendTransport.close()
            producers = [String: MSProducer]()
            sendTransport = nil
        }
        
        if (recvTransport != nil) {
            recvTransport.close()
            consumers = [String: [MSConsumer]]()
            recvTransport = nil
        }
    }
    
    func getIceConnectionState() -> SMIceConnectionState {
        let state = recvTransport.getConnectionState()
        return SMIceConnectionState(rawValue: state) ?? .disconnected
    }
    
    private func removeVideoConsumer(_ participantId: String) {
        var consumers = self.consumers[participantId]
        
        let videoConsumer = consumers?.first(where: { consumer -> Bool in
            consumer.getKind() == "video"
        })
        
        videoConsumer?.close()
        consumers?.removeAll(where: { consumer -> Bool in
            consumer.getKind() == "video"
        })
        
        self.consumers[participantId] = consumers

    }
    
    private func makeParticipant(_ participantId: String) -> SMParticipant {
        let callerStateChannel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        let participantChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
        let callerState = callerStateChannel.getCallerState(participantId)
        let identity = participantChannel.getIdentity(participantId)
        
        let participant = SMParticipant(id: participantId,
                                        identity: identity ?? SMIdentityInfo(),
                                        callerState: callerState ?? SMCallerState())
        return participant
    }
    
    private func checkBothTransportsCreated() {
        if (sendTransport != nil && recvTransport != nil) {
            transactionCompletion?(nil)
            
            /* check if the tracks should be restored (after reconnecting)*/
            if (shouldCreateVideoTrackAfterReconnect) {
                addVideoTrack() { [weak self] error, videoTrack in
                    if error == nil {
                        self?.shouldCreateVideoTrackAfterReconnect = false
                        DispatchQueue.main.async {
                            ScreenMeet.session.delegate?.onLocalVideoCreated(videoTrack!)
                        }
                    }
                    if (self?.shouldCreateAudioTrackAfterReconnect == true) {
                        self?.shouldCreateAudioTrackAfterReconnect = false
                        self?.addAudioTrack { error in
                            ScreenMeet.session.delegate?.onLocalAudioCreated()
                        }
                    }
                }
            }
            else if (shouldCreateAudioTrackAfterReconnect == true) {
                addAudioTrack { [weak self] error in
                    self?.shouldCreateAudioTrackAfterReconnect = false
                    ScreenMeet.session.delegate?.onLocalAudioCreated()
                }
            }
        }
    }
    
    private func changeCapturerInternal(_ videoSourceDevice: AVCaptureDevice!, _ isImageTransfer: Bool, completionHandler: SMCapturerOperationCompletion? = nil) {
        self.tracksManager.videoSourceDevice = videoSourceDevice
        
        if (getVideoEnabled() == false) {
            DispatchQueue.main.async {
                completionHandler?(SMError(code: .capturerInternalError, message: "Local video is currently stopped. Could not change capturer"))
            }
        }
        else {
            tracksManager.changeCapturer(videoSourceDevice, isImageTransfer) { [weak self] capturerError in
                if let capturerError = capturerError {
                    completionHandler?(capturerError)
                    
                    // capturer failed, should stop video track
                    self?.setVideoState(false) { error, videoTrack in
                        ScreenMeet.session.delegate?.onLocalVideoStopped()
                        ScreenMeet.session.delegate?.onError(capturerError)
                    }
                }
                else {
                    if videoSourceDevice == nil {
                        let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                        channel.setVideoState(true, "screen_share")
                    }
                    else {
                        let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                        channel.setVideoState(true, "camera")
                    }
                    completionHandler?(nil)
                }
            }
        }
    }
    
    private func stopCapturerInternal(completionHandler: SMCapturerOperationCompletion? = nil) {
        if (getVideoEnabled() == false) {
            completionHandler?(SMError(code: .capturerInternalError, message: "Local video is currently stopped. Could not change capturer"))
        }
        else {
            tracksManager.stopCapturer { capturerError in
                if let capturerError = capturerError {
                    completionHandler?(capturerError)
                }
                else {
                    completionHandler?(nil)
                }
            }
        }
    }
    
    private func setAudioStateInternal(_ isEnabled: Bool,  _ completion: @escaping SMAudioOperationCompletion) {
        let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel

        if sendTransport == nil {
            completion(SMError(code: .capturerInternalError, message: "Transport for sending audio not created. Are you sure you are connected?"))
            return
        }
        if isEnabled {
            if let producer = producers["audio"]{
                producer.track.isEnabled = true
                
                channel.setAudioState(true) { error in
                    if let error = error {
                        completion(error)
                    }
                    else {
                        completion(nil)
                    }
                }
            }
            else {
                addAudioTrack(completion)
            }
        }
        else {
            if let producer = producers["audio"] {
                /*producer.close()
                producers["audio"] = nil
                tracksManager.cleanupAudio()*/
                producer.track.isEnabled = false
                
                let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setAudioState(false) { error in
                    if let error = error {
                        completion(error)
                    }
                    else {
                        completion(nil)
                    }
                }
            }
            else {
                completion(nil)
            }
        }
    }
    
    private func setVideoStateInternal(_ isEnabled: Bool, _ completion: @escaping SMVideoOperationCompletion) {
        if sendTransport == nil {
            completion(SMError(code: .capturerInternalError, message: "Transport for sending video not created. Are you sure you are connected?"), nil)
            return
        }
        if isEnabled {
            addVideoTrack(completion)
        }
        else {
            tracksManager.shouldUseCustomImageSessionForVideoSharing = false
            if let producer = producers["video"] {
                producer.close()
                producers["video"] = nil
                tracksManager.cleanupVideo()
                transport.webSocketClient.command(for: .mediasoup, message: "video-stopped", data: [String: Any]()) {_ in
                    NSLog("[MS] video-stopped sent")
                }
                
                let channel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setVideoState(false) { error in
                    if let error = error {
                        completion(error, nil)
                    }
                    else {
                        completion(nil, nil)
                    }
                }
            }
            else {
                completion(nil, nil)
            }
        }
    }
    
    private func queueProducerOperation() {
        if produceOperations.isEmpty {
            return
        }
        
        currentProducerOperation = produceOperations.first!
        producersQueue.async(flags: .inheritQoS) { [self] in
            if let videoOperation = currentProducerOperation as? VideoOperation {
                tracksManager.videoSourceDevice = videoOperation.device
                setVideoStateInternal(videoOperation.isEnabled) { [weak self] error, videoTrack in
                    self?.proceedWithNextProduceOperation()
                    videoOperation.completion(error, videoTrack)
                }
            }
            if let audioOperation = currentProducerOperation as? AudioOperation {
                setAudioStateInternal(audioOperation.isEnabled) { [weak self] error in
                    self?.proceedWithNextProduceOperation()
                    audioOperation.completion(error)
                }
            }
            
            if let changeCapturerOperation = currentProducerOperation as? ChangeCapturerOperation {
                changeCapturerInternal(changeCapturerOperation.device, changeCapturerOperation.isImageTransfer) { [weak self] error in
                    self?.proceedWithNextProduceOperation()
                    
                    SMLogCapturerChangeTransaction().witDevice(changeCapturerOperation.device).run()
                    changeCapturerOperation.completion?(error)
                }
            }
            
            if let stopCapturerOperation = currentProducerOperation as? StopCapturerOperation {
                stopCapturerInternal() { [weak self] error in
                    self?.proceedWithNextProduceOperation()
                    stopCapturerOperation.completion?(error)
                }
            }
        }
    }
    
    private func proceedWithNextProduceOperation() {
        produceOperations.remove(at: 0)
        currentProducerOperation = nil
        queueProducerOperation()
    }
    
    private func queueConsumerOperation() {
        if consumeOperations.isEmpty {
            handleActiveSpeaker()
            return
        }
        
        currentConsumerOperation = consumeOperations.first!
        consumersGroup.enter()
        
        consumersQueue.async(flags: .barrier) { [self] in
            recvTransport.consume(self,
                                  currentConsumerOperation.id,
                                  currentConsumerOperation.producerId,
                                  currentConsumerOperation.kind,
                                  &currentConsumerOperation.rtpParameters,
                                  nil) { [self] consumer, error in
                
                if let error = error {
                    NSLog("Could not handle remote track: " + error.message)
                }
                else {
                    if (self.consumers[consumer!.getId()] == nil) {
                        self.consumers[consumer!.getId()] = [MSConsumer]()
                    }
                    
                    if consumer!.getKind() == "video" {
                        /* remove previous video consumer*/
                        self.consumers[consumer!.getId()]?.filter({ consumer in
                            consumer.getKind() == "video"
                        }).forEach({ consumer in
                            consumer.close()
                        })

                        self.consumers[consumer!.getId()]?.removeAll(where: { consumer in
                            consumer.getKind() == "video"
                        })
                    }
                    if consumer!.getKind() == "audio" {
                        /* remove previous video consumer*/
                        self.consumers[consumer!.getId()]?.filter({ consumer in
                            consumer.getKind() == "audio"
                        }).forEach({ consumer in
                            consumer.close()
                        })

                        self.consumers[consumer!.getId()]?.removeAll(where: { consumer in
                            consumer.getKind() == "audio"
                        })
                    }
                    
                    self.consumers[consumer!.getId()]?.append(consumer!)
                    
                    let payload = SMResumeTrackPayload(_target_cid: currentConsumerOperation.id,
                                                       producerKey: currentConsumerOperation.producerKey,
                                                             track: currentConsumerOperation.producerKey,
                                                              kind: currentConsumerOperation.kind)
                    transport.webSocketClient.command(for: .mediasoup, message: "resume-track", data: payload.socketRepresentation()) { [weak self] data in
                       
                        if consumer!.getKind() == "video" {
                            self?.notifyParticipantVideoCreated(currentConsumerOperation.id)
                        }
                        if consumer!.getKind() == "audio" {
                            self?.notifyParticipantAudioCreated(currentConsumerOperation.id)
                        }
                        
                        self?.consumersGroup.leave()
                    }
                }
            }
        }
        
        consumersGroup.notify(queue: .global()) { [weak self] in
            self?.consumeOperations.remove(at: 0)
            self?.currentConsumerOperation = nil
            self?.queueConsumerOperation()
        }
    }
    
    private func reconnectSendTransport() {
        transport.webSocketClient.command(for: name,
                                          message: "restart-ice",
                                          data: ["transportType": "inbound"]) { [weak self] dataToParse in
            
            if let string = dataToParse[0] as? String {
                NSLog("[MS] Send transport ICE reconnect failed: " + string)
            }
            if let data = dataToParse[0] as? MSJson {
                if data["error"] == nil {
                    let result = data["result"] as! MSJson
                    
                    let iceServers = result["iceServers"] as! MSJsonArray
                    let iceParameters = result["iceParameters"] as! MSJson
                    
                    self?.sendTransport.updateIceServers(iceServers)
                    self?.sendTransport.restartIce(iceParameters)
                }
            }
        }
    }
    
    private func reconnectRecvTransport() {
        transport.webSocketClient.command(for: name,
                                          message: "restart-ice",
                                          data: ["transportType": "outbound"]) { [weak self] dataToParse in
            if let string = dataToParse[0] as? String {
                NSLog("[MS] Recv transport ICE reconnect failed: " + string)
            }
            if let data = dataToParse[0] as? MSJson {
                if data["error"] == nil {
                    let result = data["result"] as! MSJson
                    
                    let iceServers = result["iceServers"] as! MSJsonArray
                    let iceParameters = result["iceParameters"] as! MSJson
                    
                    self?.recvTransport.updateIceServers(iceServers)
                    self?.recvTransport.restartIce(iceParameters)
                }
            }
        }
    }
}

extension SMMediasoupChannel: MSSendTransportConnectDelegate {

    func onProduce(_ transport: MSSendTransport, _ kind: String, _ rtpParameters: MSJson, _ appData: MSJson?, _ callback: @escaping (String) -> Void) {
  
        var stringAppData = [String: String]()
        if let appData = appData {
            for (key, value) in appData {
                stringAppData[key] = value as? String
            }
        }
        
        var rtp: SMTrackRtpParameters!
        do {
            rtp = try SMTrackRtpParameters.init(dictionary: rtpParameters)
        }
        catch {
            NSLog(error.localizedDescription)
        }
        
        let trackPayload = SMSendTrackPayload(transportId: transport.getId(),
                                              appData: stringAppData,
                                              kind: kind,
                                              rtpParameters: rtp,
                                              paused: false)
        
        let payload = trackPayload.socketRepresentation() as! [String: Any]
        
        NSLog("[MSAudio] Sending track")
        self.transport.webSocketClient.command(for: self.name, message: "send-track", data: payload) { data in
                SMSocketDataParser().parse(data) { (response: SMSendTrackSocketReponse?, error) in
                   if let error = error {
                       NSLog("Could not parse send-track response: " + error.message)
                   }
                   else {
                        let id = response!.result.id
                        callback(id)
                    }
                }
            }
    }
    
    func onConnect(_ transport: MSTransport, _ dtlsParameters: MSJson) {
        var dtls: SMTransportOptionsDtlsParameters!
        do {
            dtls = try SMTransportOptionsDtlsParameters.init(dictionary: dtlsParameters)
        }
        catch {
            NSLog(error.localizedDescription)
        }
        
        var transportType = "send"
        
        if transport is MSRecvTransport {
            transportType = "recv"
        }
        
        let connectTransportPayload = SMConnectTransportPayload(transportId: transport.getId(),
                                            transportType: transportType,
                                            dtlsParameters: dtls)
    
        self.transport.webSocketClient.command(for: self.name,
                                          message: "connect-transport",
                                          data: connectTransportPayload.socketRepresentation()) { data in
            NSLog("connect-transport " + transportType + " callback")
        }
        
        NSLog("[MS] on connect")
    }
    
    func onConnectionStateChange(_ transport: MSTransport, _ connectionState: RTCIceConnectionState) {
        let stringState = MSPeerConnection.iceConnectionState2String[connectionState]
        
        if transport is MSSendTransport {
            if connectionState == .failed || connectionState == .disconnected {
                NSLog("SMMediasoupChannel.reconnectSendTransport()")
                //reconnectSendTransport()
            }
            NSLog("[MS] send transport connection state: " + (stringState ?? "unknown"))
        }
        else {
            if connectionState == .failed || connectionState == .disconnected {
                NSLog("SMMediasoupChannel.reconnectRecvTransport()")
                //reconnectRecvTransport()
            }
            NSLog("[MS] recv transport connection state: " + (stringState ?? "unknown"))
        }
    }
}

extension SMMediasoupChannel: MSRecvTransportConnectDelegate {
}


extension SMMediasoupChannel: MSProducerDelegate {
    func onTransportClose(_ producer: MSProducer) {
        producer.track.isEnabled = false
        producer.close()
    }
}

extension SMMediasoupChannel: MSConsumerDelegate {
    func onTransportClose(consumer: MSConsumer) {
        consumer.getTrack()?.isEnabled = false
        consumer.close()
        NSLog("consumer closed")
    }
}
