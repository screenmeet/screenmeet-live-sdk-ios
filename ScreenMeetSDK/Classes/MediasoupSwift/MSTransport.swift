//
//  MSTransport.swift
//  ScreenMeet
//
//  Created by Ross on 31.01.2021.
//

import UIKit
import WebRTC

protocol MSTransportConnectDelegate: class {
    func onConnect(_ transport: MSTransport, _ dtlsParameters: MSJson)
    func onConnectionStateChange(_ transport: MSTransport, _ connectionState: String)
}

class MSTransport: NSObject {
    // Listener.
    private weak var transportConnectDelegate: MSTransportConnectDelegate!
    // Id.
    private var id: String!
    
    // Transport (IceConneciton) connection state.
    private var connectionState: RTCIceConnectionState! = .new
    
    // App custom data.
    private var appData = MSJson()
    
    // SCTP max message size if enabled, null otherwise.
    var maxSctpMessageSize: CLong = 0
    
    // Handler.
    var handler: MSHandler!
    
    let ortc = MSOrtc()
    
    var closed: Bool = false
    
    // Extended RTP capabilities.
    var extendedRtpCapabilities: MSJson!
    
    // Whether the Consumer for RTP probation has been created.
    var probatorConsumerCreated: Bool = false
    
    init(_ delegate: MSTransportConnectDelegate,
         _ id: String,
         _ extendedRtpCapabilities: MSJson,
         _ appData: MSJson?) {
        
        super.init()
        
        self.transportConnectDelegate = delegate
        self.extendedRtpCapabilities = extendedRtpCapabilities
        
        self.id = id
        if let appData = appData {
            self.appData = appData
        }
    }
    
    func getId() -> String {
        return id
    }
    
    func isClosed() -> Bool {
        return closed
    }
    
    func getConnectionState() -> String {
        let state = MSPeerConnection.iceConnectionState2String[connectionState]
        return state ?? "unknown"
    }
    
    func getAppData() -> MSJson {
        return appData
    }
    
    func close() {
        if closed {
            return
        }

        closed = true

        // Close the handler.
        handler.close()
    }
    
    func getStats(_ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        if closed {
            return
        }
        else {
            return handler.getTransportStats(completion)
        }
    }
    
    func restartIce(_ iceParameters: MSJson) {
        if closed {
            // Transport Closed
        }
        else {
            handler.restartIce(iceParameters)
        }
    }
    
    func updateIceServers(_ iceServers: [String]) {
        if closed {
            // Transport closed
        }
        else {
            handler.updateIceServers(iceServers)
        }
    }
    
    func setHandler(_ handler: MSHandler) {
        self.handler = handler
    }
}

extension MSTransport: MSConnectDelegate {
    func onConnect(_ dtlsParameters: MSJson) {
        transportConnectDelegate?.onConnect(self, dtlsParameters)
    }
    
    func onConnectionStateChange(_ connectionState: RTCIceConnectionState) {
        let state =  MSPeerConnection.iceConnectionState2String[connectionState]
        transportConnectDelegate?.onConnectionStateChange(self, state ?? "unknown")
    }
}

typealias MSProduceCallback = (String) -> Void

protocol MSSendTransportConnectDelegate: MSTransportConnectDelegate {
    func onProduce(_ transport: MSSendTransport,
                   _ kind: String,
                   _ rtpParameters: MSJson,
                   _ appData: MSJson?,
                   _ callback: @escaping MSProduceCallback)
}

protocol MSRecvTransportConnectDelegate: MSTransportConnectDelegate {
   
}

typealias MSProduceCompletion = (MSProducer?, MSError?) -> Void

class MSSendTransport: MSTransport {
    // Listener instance.
    private weak var connectDelegate: MSSendTransportConnectDelegate?
    
    // Map of Producers indexed by id.
    private var producers =  [String: MSProducer]()
    // Whether we can produce audio/video based on computed extended RTP
    
    // capabilities.
    private var canProduceByKind: [String: Bool]!
    
    // SendHandler instance.
    private var sendHandler: MSSendHandler!
    
    // RecvHandler instance.
    private var recvHandler: MSRecvHandler!
    
    init(
        _ connectDelegate: MSSendTransportConnectDelegate,
        _ id: String,
        _ iceParameters: MSJson,
        _ iceCandidates: MSJsonArray,
        _ dtlsParameters: MSJson,
        _ sctpParameters: MSJson?,
        _ peerConnectionOptions: MSPeerConnection.Options?,
        _ extendedRtpCapabilities: MSJson,
        _ canProduceByKind: [String: Bool],
        _ appData: MSJson?) {
    
        super.init(connectDelegate as MSTransportConnectDelegate, id, extendedRtpCapabilities, appData)
        
        self.connectDelegate = connectDelegate
        self.canProduceByKind = canProduceByKind
        
        let maxMessageSize = sctpParameters?["maxMessageSize"]

        if let maxMessageSize =  maxMessageSize as? Int {
            self.maxSctpMessageSize = maxMessageSize
        }
           
        let sendingRtpParametersByKind = [
            "audio": ortc.getSendingRtpParameters("audio", extendedRtpCapabilities),
            "video": ortc.getSendingRtpParameters("video", extendedRtpCapabilities)
        ]

        let sendingRemoteRtpParametersByKind = [
            "audio": ortc.getSendingRemoteRtpParameters("audio", extendedRtpCapabilities),
            "video": ortc.getSendingRemoteRtpParameters("video", extendedRtpCapabilities)
        ]
        
        self.sendHandler = MSSendHandler(self,
                                         iceParameters,
                                         iceCandidates,
                                         dtlsParameters,
                                         sctpParameters,
                                         peerConnectionOptions,
                                         sendingRtpParametersByKind,
                                         sendingRemoteRtpParametersByKind)
        setHandler(sendHandler)
    }
    
    func produce(_ producerDelegate: MSProducerDelegate,
                 _ track: RTCMediaStreamTrack,
                 _ encodings: Array<RTCRtpEncodingParameters>?,
                 _ codecOptions: MSJson?,
                 _ appData: MSJson?,
                 _ completion: @escaping MSProduceCompletion) {
        
        if isClosed() {
            completion(nil, MSError(type: .producer, message: "sendTransport closed"))
        }
        else if track.readyState == .ended {
            completion(nil, MSError(type: .producer, message: "track ended"))
        }
        else if canProduceByKind[track.kind] == nil {
            completion(nil, MSError(type: .producer, message: "cannot produce track kind"))
        }
             
        if let codecOptions = codecOptions {
            if let error = ortc.validateProducerCodecOptions(codecOptions) {
                completion(nil, error)
                return
            }
        }

       
        sendHandler.send(track, encodings, codecOptions) { [self] sendData, error in
            if let error = error {
                completion(nil, error)
            }
            else {
                
                // This will fill rtpParameters's missing fields with default values.
                var rtp = sendData!.rtpParameters
                if let error = ortc.validateRtpParameters(&rtp!) {
                    completion(nil, error)
                }
                
                connectDelegate?.onProduce(self, track.kind, sendData!.rtpParameters, appData, { producerId in
                    
                    var rtpParameters = sendData!.rtpParameters!
                    
                    if let error = ortc.validateRtpParameters(&rtpParameters) {
                        sendHandler.stopSending(sendData!.localId)
                        completion(nil, error)
                        return
                    }
                    
                    let producer = MSProducer(self,
                               producerDelegate,
                               producerId,
                               sendData!.localId,
                               sendData!.rtpSender,
                               track,
                               sendData!.rtpParameters,
                               appData)
                            

                    self.producers[producer.id] = producer
                    completion(producer, nil)
                })
            }
            
        }
        
       
    }
    
    override func close() {
        if closed {
            return
        }
        super.close()

        // Close all Producers.
        for (_, producer) in producers {
            producer.transportClosed()
        }
    }
    
}

extension MSSendTransport: MSProducerPrivateDelegate {
    
    func onClose(_ producer: MSProducer) {
        producers[producer.getId()] = nil
        
        if closed {
            return
        }

        sendHandler.stopSending(producer.getLocalId())
    }
    
    func onSetMaxSpatialLayer(_ producer: MSProducer, _ maxSpatialLayer: UInt8) {
        sendHandler.setMaxSpatialLayer(producer.getLocalId(), maxSpatialLayer)
    }
    
    
    func onReplaceTrack(_ producer: MSProducer, _ track: RTCMediaStreamTrack) {
        sendHandler.replaceTrack(producer.getLocalId(), track)
    }
    
    func onGetStats(_ producer: MSProducer, _ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        if closed {
           // MSC_THROW_INVALID_STATE_ERROR("SendTransport closed");
        }
                   
        sendHandler.getSenderStats(producer.getLocalId(), completion)
    }

}

typealias MSConsumeCompletion = (MSConsumer?, MSError?) -> Void

class MSRecvTransport: MSTransport, MSConsumerPrivateDelegate {
    init(
        _ connectDelegate: MSRecvTransportConnectDelegate,
        _ id: String,
        _ iceParameters: MSJson,
        _ iceCandidates: MSJsonArray,
        _ dtlsParameters: MSJson,
        _ sctpParameters: MSJson?,
        _ peerConnectionOptions: MSPeerConnection.Options?,
        _ extendedRtpCapabilities: MSJson,
        _ appData: MSJson!) {
        super.init(connectDelegate, id, extendedRtpCapabilities, appData)
        
        self.recvHandler = MSRecvHandler(self,
                                         iceParameters,
                                         iceCandidates,
                                         dtlsParameters,
                                         sctpParameters,
                                         peerConnectionOptions)
        setHandler(recvHandler)
       
    }
    // Map of Consumers indexed by id.
    private var consumers = [String: MSConsumer]()
    // SendHandler instance.
    private var recvHandler: MSRecvHandler!
    
    func consume(
        _ consumerDelegate: MSConsumerDelegate,
        _ id: String,
        _ producerId: String,
        _ kind: String,
        _ rtpParameters: inout MSJson,
        _ appData: MSJson?,
        _ completion: @escaping MSConsumeCompletion) {
        if (self.isClosed()) {
            completion(nil, MSError(type: .consumer, message: "RecvTransport closed"))
            return
        } else if (id.isEmpty) {
            completion(nil, MSError(type: .consumer, message: "id missing"))
            return
        } else if (producerId.isEmpty) {
            completion(nil, MSError(type: .consumer, message: "producer id missing"))
            return
        } else if (kind != "audio" && kind != "video") {
            completion(nil, MSError(type: .consumer, message: "invalid kind"))
            return
        }
  
        else if (!ortc.canReceive(&rtpParameters, extendedRtpCapabilities!)) {
            completion(nil, MSError(type: .consumer, message: "cannot consume this producer"))
        }

        recvHandler.receive(id, kind, &rtpParameters) { [rtpParameters] recvData, error in
            if let error = error {
                completion(nil, error)
            }
            else {
                
                let consumer = MSConsumer(self,
                                          consumerDelegate,
                                          id,
                                          recvData!.localId,
                                          producerId,
                                          recvData!.rtpReceiver,
                                          recvData!.track,
                                          rtpParameters,
                                          appData)
                
                self.consumers[consumer.getId()] = consumer
                
                if !self.probatorConsumerCreated && kind == "video" {
                    let probatorId = "probator"
                    if var probatorRtpParameters = self.ortc.generateProbatorRtpParameters(consumer.getRtpParameters()) {
                        self.recvHandler.receive(probatorId, kind, &probatorRtpParameters) { recvData, error in
                            if let error = error {
                                completion(nil, error)
                            }
                            else {
                                self.probatorConsumerCreated = true
                                completion(consumer, nil)
                            }
                        }
                    }
                    else {
                        completion(nil, MSError(type: .consumer, message: "Could not create probator parameters"))
                    }
                }
                else {
                    completion(consumer, nil)
                }
            }
        }
  
    }
    
    override func close() {
        if (self.closed) {
            return
        }
        super.close()
        self.consumers.values.forEach({consumer in
            consumer.transportClosed()
        })
    }
        
    func onClose(consumer: MSConsumer) {
        self.consumers.removeValue(forKey: consumer.getId())
        if (self.closed) {
            return
        }

        recvHandler.stopReceiving(consumer.getLocalId())
    }
    
    func onGetStats(consumer: MSConsumer, _ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        return self.recvHandler.getReceiverStats(consumer.getLocalId(), completion)
    }

}
