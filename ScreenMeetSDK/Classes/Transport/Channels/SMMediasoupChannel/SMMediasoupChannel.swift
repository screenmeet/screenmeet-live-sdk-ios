//
//  SMMediasoupChannel.swift
//  ScreenMeet
//
//  Created by Ross on 14.01.2021.
//

import UIKit
import WebRTC
import SocketIO

struct ConsumeOperation: Equatable {
    var kind: String
    var id: String
    var producerId: String
    var rtpParameters: MSJson
    
    static func == (lhs: ConsumeOperation, rhs: ConsumeOperation) -> Bool {
        return lhs.kind == rhs.kind && lhs.id == rhs.id && lhs.producerId == rhs.producerId
    }
}

class SMMediasoupChannel: NSObject, SMChannel  {
    private var videoSourceDevice: AVCaptureDevice!
    private var delegate: ScreenMeetDelegate? = nil
    private var mediasoupTransportOptions: SMTransportOptions!
    private var tracksManager = SMTracksManager()
    
    private var device: MSDevice!
    private var sendTransport: MSSendTransport!
    private var recvTransport: MSRecvTransport!
    private var producers = [String: MSProducer]()
    private var consumers = [String: [MSConsumer]]()
    
    private let consumersQueue = DispatchQueue(label: "mediasoup.consumers.serial.queue", attributes: .concurrent)
    private var operations = [ConsumeOperation]()
    private var currentOperation: ConsumeOperation!
    let group = DispatchGroup()
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
                                   _ videoSourceDevice: AVCaptureDevice!,
                                   _ completion: @escaping StartWebRTCTransactionCompletion) {
        self.videoSourceDevice = videoSourceDevice
        
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
        createSwiftRecvTransport()
        createSwiftSendTransport()
        
        addSwiftVideoTrack(shouldAddAudioAfterCompletion: true)
    }

    func createSwiftSendTransport() {
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
    
    func createSwiftRecvTransport() {
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
    
    func addSwiftAudioTrack() {
        let audioTrack = self.tracksManager.makeAudioTrack()
        
        let codecOptions = [ "audioStartBitrate": 24000]
        //let appData = "{\n \"profile\": \"cam\" \n}"
        
        sendTransport.produce(self, audioTrack, nil, codecOptions, nil) { [weak self] producer, error in
            if let error = error {
                NSLog("Could not create audio track: " + error.message)
            }
            else {
                self?.delegate?.onLocalAudioCreated()
                self?.producers["audio"] = producer
                
                let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setAudioState(true)
            }
        }
    }
    
    func addSwiftVideoTrack(shouldAddAudioAfterCompletion: Bool = false) {
        startCapturer()
        
        let videoTrack = tracksManager.makeVideoTrack()
        let codecOptions = ["videoGoogleStartBitrate": 1000]

        let appData = [ "profile": "cam"]
        
        let encodings = SMEncodingsBuilder().defaultSimulcastEncodings()
        
        sendTransport.produce(self, videoTrack, encodings, codecOptions, appData) { [weak self] producer, error in
            if let error = error {
                NSLog("Could not create video track: ", error.message)
            }
            else {
                self?.producers["video"] = producer
                
                let channel = self?.transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
                channel.setVideoState(true)

                self?.delegate?.onLocalVideoCreated(videoTrack)
                self?.addSwiftAudioTrack()
            }
        }
    }
    
    func startCapturer() {
        tracksManager.startCapturer(videoSourceDevice)
    }
    
    func changeCapturer(_ videoSourceDevice: AVCaptureDevice!, completionHandler: SMCaptureCompletion? = nil) {
        self.videoSourceDevice = videoSourceDevice
        
        if (getVideoEnabled() == false) {
            completionHandler?(SMError(code: .capturerInternalError, message: "Local video is currently stopped. Could not change capturer"))
        }
        else {
            tracksManager.changeCapturer(videoSourceDevice, completionHandler)
        }
    }
    
    func getVideoSourceDevice() -> AVCaptureDevice? {
        return self.videoSourceDevice
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
        
        operations.insert(operation, at: operations.count)
        
        if currentOperation == nil {
            queuOperation()
        }
    }
    
    private func checkBothTransportsCreated() {
        if (sendTransport != nil && recvTransport != nil) {
            transactionCompletion?(nil)
        }
    }
    
    private func queuOperation() {
        if operations.isEmpty {
            handleActiveSpeaker()
            return
        }
        
        currentOperation = operations.first!
        group.enter()
        
        consumersQueue.async(flags: .barrier) { [self] in
            recvTransport.consume(self,
                                  currentOperation.id,
                                  currentOperation.producerId,
                                  currentOperation.kind,
                                  &currentOperation.rtpParameters,
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
                        notifyParticipantVideoCreated(currentOperation.id)
                    }
                    if consumer!.getKind() == "audio" {
                        notifyParticipantAudioCreated(currentOperation.id)
                    }
                    
                    let payload = SMResumeTrackPayload(_target_cid: currentOperation.id,
                                                   kind: currentOperation.kind)
                    transport.webSocketClient.command(for: .mediasoup, message: "resume-track", data: payload.socketRepresentation()) { data in
                        NSLog("Resume track sent")
                        
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .global()) { [weak self] in
            self?.operations.remove(at: 0)
            self?.currentOperation = nil
            self?.queuOperation()
        }
    }
    
    /// Comminicate events back to delegate
    
    func removeParticipant(_ participantId: String, _ identity: SMIdentityInfo) {
        //Remove all consumers
        consumers[participantId]?.removeAll()
        
        let participant = SMParticipant(id: participantId, identity: identity, callerState: SMCallerState())
        delegate?.onParticipantLeft(participant)
    }
    
    func notifyParticipantsMediaStateChanged(_ participantId: String, _ newCallerState: SMCallerState) {
        
        if (newCallerState.videoEnabled == false) {
            removeVideoConsumer(participantId)
        }
        let participantsChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
        let identity = participantsChannel.getIdentity(participantId)
        
        var participant = SMParticipant(id: participantId, identity: identity ?? SMIdentityInfo(), callerState: newCallerState)
        participant = extendParticipantWithTracks(participant)
        delegate?.onParticipantMediaStateChanged(participant)
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
                    
                    delegate?.onActiveSpeakerChanged(participant)
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
            
            delegate?.onParticipantVideoTrackCreated(participant)
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
            
            delegate?.onParticipantAudioTrackCreated(participant)
        }
        
    }
    
    func notifyParticipantJoined(_ participantId: String, _ identity: SMIdentityInfo) {
        DispatchQueue.main.async { [self] in
            var participant = SMParticipant(id: participantId,
                                            identity: identity,
                                            callerState:SMCallerState()) // real callerstate should be deliverd via media state changed right after this call
            
            participant = extendParticipantWithTracks(participant)
            delegate?.onParticipantJoined(participant)
        }
    }
    
    deinit {
        NSLog("Mediasoup channel was dealloced of channel")
    }
    
    /// Get tracks state
    
    func getVideoEnabled() -> Bool {
        if let producer = producers["video"] {
            return true
        }
        
        return false
    }
    
    func getAudioEnabled() -> Bool {
        if let producer = producers["audio"] {
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
    
    func setVideoState(_ isEnabled: Bool) {
        if isEnabled {
            addSwiftVideoTrack()
        }
        else {
            if let producer = producers["video"] {
                producer.close()
                producers["video"] = nil
                tracksManager.cleanup()
                
                //xxxxxxx startCapturer()
            }
        }
    }
    
    func setAudioState(_ isEnabled: Bool) {
        if isEnabled {
            addSwiftAudioTrack()
        }
        else {
            if let producer = producers["audio"] {
                producer.close()
                producers["audio"] = nil
            }
        }
    }
    
    func setDelegate(_ delegate: ScreenMeetDelegate?) {
        self.delegate = delegate
    }
    
    func disconnect(_ completion: @escaping SMDisconnectCompletion) {
        sendTransport.close()
        recvTransport.close()
        producers = [String: MSProducer]()
        consumers = [String: [MSConsumer]]()
        
        tracksManager.stopCapturer { [weak self] error in
            DispatchQueue.main.async {
                completion(nil)
                self?.tracksManager.cleanup()
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
        else {
            NSLog("")
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
    
    func onConnectionStateChange(_ transport: MSTransport, _ connectionState: String) {
        if transport is MSSendTransport {
//            delegate?.onIceConnectionStateChanged("send", SMIceConnectionState(rawValue: connectionState) ?? .closed)
            NSLog("[MS] send transport connection state: " + connectionState)
        }
        else {
//            delegate?.onIceConnectionStateChanged("recv", SMIceConnectionState(rawValue: connectionState) ?? .closed)
            NSLog("[MS] recv transport connection state: " + connectionState)
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
