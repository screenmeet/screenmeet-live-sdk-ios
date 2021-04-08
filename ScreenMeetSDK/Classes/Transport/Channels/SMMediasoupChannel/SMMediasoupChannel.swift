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
    var completion: SMCapturerOperationCompletion?
}

class SMMediasoupChannel: NSObject, SMChannel  {
    private var mediasoupTransportOptions: SMTransportOptions!
    private var tracksManager = SMTracksManager()
    
    private var shouldCreteVideoTrackAfterReconnect = false
    private var shouldCreteAudioTrackAfterReconnect = false
    
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
            shouldCreteVideoTrackAfterReconnect = getVideoEnabled()
            shouldCreteAudioTrackAfterReconnect = getAudioEnabled()
            
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
    }

    func createSendTransport() {
        let json = mediasoupTransportOptions.result.inbound.socketRepresentation() as! MSJson
        
        var iceParameters = json["iceParameters"] as! MSJson
        var iceCandidates = json["iceCandidates"] as! MSJsonArray
        var dtlsParameters = json["dtlsParameters"] as! MSJson

        device.createSendTransport(self, mediasoupTransportOptions!.result.inbound.id,
                                        &iceParameters,
                                        &iceCandidates,
                                        &dtlsParameters,
                                        nil,
                                        nil,
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
        
        device.createRecvTransport(self,
                                        mediasoupTransportOptions!.result.outbound.id,
                                        &iceParameters,
                                        &iceCandidates,
                                        &dtlsParameters,
                                        nil,
                                        nil,
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
        
        let codecOptions = [ "audioStartBitrate": 24000]
        //let appData = "{\n \"profile\": \"cam\" \n}"
        
        sendTransport.produce(self, audioTrack, nil, codecOptions, nil) { [weak self] producer, error in
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

        let appData = [ "profile": "cam"]
        
        let encodings = SMEncodingsBuilder().defaultSimulcastEncodings()
        
        sendTransport.produce(self, videoTrack, encodings, codecOptions, appData) { [weak self] producer, error in
            if let error = error {
                completion?(SMError(code: .mediaTrackError, message: error.message), nil)
                NSLog("Could not create video track: ", error.message)
            }
            else {
                self?.producers["video"] = producer
                
                let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setVideoState(true)
                
                self?.tracksManager.startCapturer(self?.tracksManager.videoSourceDevice ?? nil) { error in
                    completion?(nil, videoTrack)
                    videoTrack.isEnabled = true
                }
            }
        }
    }
    
    
    func consumeTrack(_ trackMessage: SMNewTrackAvailableMessage) {
        let kind: String = trackMessage.consumerParams.kind
        let id: String = trackMessage.producerCid
        let producerId: String = trackMessage.consumerParams.producerId
        let rtpParameters: MSJson = trackMessage.consumerParams.rtpParameters.socketRepresentation() as! MSJson
        
        let operation = ConsumeOperation(kind: kind,
                                         id: id,
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
        
        if (newCallerState.videoEnabled == false) {
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
        remoteVideoTrack?.isEnabled = true
        
        let remoteAudioTrack: RTCAudioTrack? = audioConsumer?.getTrack() as? RTCAudioTrack
        remoteAudioTrack?.isEnabled = true
        
        extendedParticipant.aduioTrack = remoteAudioTrack
        extendedParticipant.videoTrack = remoteVideoTrack
        
        return extendedParticipant
    }
    
    func notifyParticipantVideoCreated(_ participantId: String) {
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
        if producers["audio"] != nil {
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
    
    func changeCapturer(_ videoSourceDevice: AVCaptureDevice!, completionHandler: SMCapturerOperationCompletion? = nil) {
        /* if there's a pending change capturer operation - do nothing. Just wait till it completes*/
        if let _ = produceOperations.first(where: { operation -> Bool in operation as? ChangeCapturerOperation != nil }) {
            return
        }
        
        let changeCapturerOperation = ChangeCapturerOperation(device: videoSourceDevice, completion: completionHandler)
        produceOperations.append(changeCapturerOperation)
        if currentProducerOperation == nil {
            queueProducerOperation()
        }
    }
    
    func setVideoSourceDevice(_ device: AVCaptureDevice?) {
        tracksManager.videoSourceDevice = device
    }
    
    func getVideoSourceDevice() -> AVCaptureDevice? {
        return tracksManager.videoSourceDevice
    }
    
    func disconnect() {
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
        
        tracksManager.stopCapturer { [weak self] error in
            DispatchQueue.main.async {
                self?.tracksManager.cleanupVideo()
                self?.tracksManager.cleanupAudio()
            }
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
            if (shouldCreteVideoTrackAfterReconnect) {
                addVideoTrack() { [weak self] error, videoTrack in
                    if (error == nil && self?.shouldCreteAudioTrackAfterReconnect == true) {
                        DispatchQueue.main.async {
                            ScreenMeet.session.delegate?.onLocalVideoCreated(videoTrack!)
                        }
                        
                        self?.addAudioTrack()
                    }
                }
            }
        }
    }
    
    private func changeCapturerInternal(_ videoSourceDevice: AVCaptureDevice!, completionHandler: SMCapturerOperationCompletion? = nil) {
        self.tracksManager.videoSourceDevice = videoSourceDevice
        
        if (getVideoEnabled() == false) {
            completionHandler?(SMError(code: .capturerInternalError, message: "Local video is currently stopped. Could not change capturer"))
        }
        else {
            tracksManager.changeCapturer(videoSourceDevice, completionHandler)
        }
    }
    
    private func setAudioStateInternal(_ isEnabled: Bool,  _ completion: @escaping SMAudioOperationCompletion) {
        if isEnabled {
            addAudioTrack(completion)
        }
        else {
            if let producer = producers["audio"] {
                producer.close()
                producers["audio"] = nil
                tracksManager.cleanupAudio()
                
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
        if isEnabled {
            addVideoTrack(completion)
        }
        else {
            if let producer = producers["video"] {
                producer.close()
                producers["video"] = nil
                tracksManager.cleanupVideo()
                
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
                changeCapturerInternal(changeCapturerOperation.device) { [weak self] error in
                    self?.proceedWithNextProduceOperation()
                    changeCapturerOperation.completion?(error)
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
                    NSLog(consumer!.getKind() +  " consumer id: " + consumer!.getId())
                    
                    if (self.consumers[consumer!.getId()] == nil) {
                        self.consumers[consumer!.getId()] = [MSConsumer]()
                    }
                    self.consumers[consumer!.getId()]?.append(consumer!)
                    if consumer!.getKind() == "video" {
                        notifyParticipantVideoCreated(currentConsumerOperation.id)
                    }
                    if consumer!.getKind() == "audio" {
                        notifyParticipantAudioCreated(currentConsumerOperation.id)
                    }
                    
                    let payload = SMResumeTrackPayload(_target_cid: currentConsumerOperation.id,
                                                              kind: currentConsumerOperation.kind)
                    transport.webSocketClient.command(for: .mediasoup, message: "resume-track", data: payload.socketRepresentation()) { data in
                        NSLog("Resume track sent")
                        
                        consumersGroup.leave()
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
        
        let payload = trackPayload.socketRepresentation()
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
                reconnectSendTransport()
            }
            NSLog("[MS] send transport connection state: " + (stringState ?? "unknown"))
        }
        else {
            if connectionState == .failed || connectionState == .disconnected {
                reconnectRecvTransport()
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
