//
//  MSHandler.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit
import WebRTC

typealias MSGetNativeCapabilitiesCompletion = ([String: Any]?, MSError?) -> Void
typealias MSSendCompletion = (MSSendData?, MSError?) -> Void
typealias MSRecvCompletion = (MSRecvData?, MSError?) -> Void

protocol MSConnectDelegate: class {
    func onConnect(_ dtlsParameters: MSJson)
    func onConnectionStateChange(_ connectionState: RTCIceConnectionState)
}

class MSHandler: NSObject {
   
    // Got no protected specificator as in C++, so making them internal for now
    // PeerConnection instance.
    var pc: MSPeerConnection!
    
    // SDP
    var remoteSdp: MSRemoteSDP!
    
    static let SctpNumStreams = [ "OS": 1024 as UInt32 , "MIS": 1024 as UInt32]
    var connectDelegate: MSConnectDelegate?
    var transportReady = false
    
    // Map of RTCTransceivers indexed by MID.
    var mapMidTransceiver = [String: RTCRtpTransceiver]()
           
    init(_ connectDelegate: MSConnectDelegate,
         _ iceParameters: MSJson,
         _ iceCandidates: MSJsonArray,
         _ dtlsParameters: MSJson,
         _ sctpParameters: MSJson?,
         _ peerConnectionOptions: MSPeerConnection.Options?) {
        super.init()
        
        self.connectDelegate = connectDelegate
        
        pc = MSPeerConnection(peerConnectionOptions) { [weak self] newIceState in
            self?.connectDelegate?.onConnectionStateChange(newIceState)
        }
        remoteSdp = MSRemoteSDP(iceParameters, iceCandidates, dtlsParameters, sctpParameters)
    }
    
    func setupTransport(_ localDtlsRole: String, _ localSdpObject: MSJson) {
        var localSdpObject = localSdpObject
        if (localSdpObject.isEmpty) {
            localSdpObject = SDPTransform.parse(pc.getLocalDescription())
        }

        // Get our local DTLS parameters.
        var dtlsParameters = SDPUtils.extractDtlsParameters(localSdpObject)

        // Set our DTLS role.
        dtlsParameters["role"] = localDtlsRole

        // Update the remote DTLS role in the SDP.
        let remoteDtlsRole = localDtlsRole == "client" ? "server" : "client"
        remoteSdp.updateDtlsRole(remoteDtlsRole)

        connectDelegate?.onConnect(dtlsParameters)
        transportReady = true
    }
    
    func close() {
        pc.close()
    }
    
    func getTransportStats(_ completion: @escaping MSPeerConnectionGetStatsCompletion){
        pc.getStats { stats in
            completion(stats)
        }
    }
    
    func updateIceServers(_ iceServerUris: [String]) {
        let configuration = pc.getConfiguration()
        configuration.iceServers = []

        for iceServerUri in iceServerUris {
            let iceServer = RTCIceServer(urlStrings: [iceServerUri])
            
            var array = configuration.iceServers
            array.append(iceServer)
            configuration.iceServers = array
        }

        if (pc.setConfiguration(configuration)) {
            return
        }

       NSLog("[MS] failed to update ICE servers")
    }
    
    func restartIce(_ iceParameters: MSJson) {
        NSLog("[MS] restart ice")
        // Provide the remote SDP handler with new remote ICE parameters.
        remoteSdp.updateIceParameters(iceParameters)

        if (!transportReady) {
            return
        }
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["iceRestart": "true"], optionalConstraints: nil)
   
        pc.createOffer(constraints) { [self] offer, error in
            if let error = error {
                NSLog("[MS] pc.createOffer() issue: " + error.message)
            }
            else {
                NSLog("[MS] calling pc.setLocalDescription(): " + offer!)
                pc.setLocalDescription(.offer, offer!) { error in
                    let sdp = remoteSdp.getSdp()
                    NSLog("[MS] calling pc.setRemoteDescription(): " + sdp)
                    pc.setRemoteDescription(.answer, sdp) { error in
                        if let error = error {
                            NSLog("[MS] calling pc.setLocalDescription() issue: " + error.message)
                        }
                        else {
                            // Ok
                        }
                    }
                }
            }
        }
    }
    
    static func getNativeRtpCapabilities(_ completion: @escaping MSGetNativeCapabilitiesCompletion) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        let pc = MSPeerConnection(nil)
        _ = pc.addTransceiver(.video)
        _ = pc.addTransceiver(.audio)
        
        pc.createOffer(constraints) { sdp, error in
            
            if let error = error {
                completion(nil, MSError(type: .device, message: error.message))
                pc.close()
            }
            else {
                pc.close()
                
                NSLog("SDP::" + sdp!)
                let sdpObject = SDPTransform.parse(sdp!)
                let nativeRtpCapabilities = SDPUtils.extractRtpCapabilities(sdpObject)
                
                completion(nativeRtpCapabilities, nil)
                pc.close()
            }
        }
    }
    
    static func getNativeSctpCapabilities() -> MSJson {
        var caps = MSJson()
        caps["numStreams"] = SctpNumStreams
        return caps
    }
    
    static func fillJsonRtpEncodingParameters(_ jsonEncoding: inout MSJson, _ encoding: RTCRtpEncodingParameters) {
        jsonEncoding["active"] = encoding.isActive

        if let rid = encoding.rid, !rid.isEmpty {
            jsonEncoding["rid"] = encoding.rid
        }

        if let maxBitrateBps = encoding.maxBitrateBps {
            jsonEncoding["maxBitrate"] = maxBitrateBps
        }

        if let maxFramerate = encoding.maxFramerate {
            jsonEncoding["maxFramerate"] = maxFramerate
        }

        if let scaleResolutionDownBy = encoding.scaleResolutionDownBy {
            jsonEncoding["scaleResolutionDownBy"] = scaleResolutionDownBy
        }

        jsonEncoding["networkPriority"] = encoding.networkPriority.rawValue
    }
}

struct MSSendData {
    var localId: String!
    var rtpSender: RTCRtpSender!
    var rtpParameters: MSJson!
}

struct MSRecvData {
    var localId: String!
    var rtpReceiver: RTCRtpReceiver!
    var track: RTCMediaStreamTrack
}

class MSSendHandler: MSHandler {
    private var newTransceiver: RTCRtpTransceiver! // swift has issues with capturing variables in nested closured, so lets strong reference it
    private var sendingRtpParametersByKind: MSJson!
    
    // Generic sending RTP parameters for audio and video suitable for the SDP remote answer.
    private var sendingRemoteRtpParametersByKind: MSJson!
    
    init( _ connectDelegate: MSConnectDelegate,
          _ iceParameters: MSJson,
          _ iceCandidates: MSJsonArray,
          _ dtlsParameters: MSJson,
          _ sctpParameters: MSJson?,
          _ peerConnectionOptions: MSPeerConnection.Options?,
          _ sendingRtpParametersByKind: MSJson,
          _ sendingRemoteRtpParametersByKind: MSJson? = MSJson()) {
        
        super.init(connectDelegate,
                   iceParameters,
                   iceCandidates,
                   dtlsParameters,
                   sctpParameters,
                   peerConnectionOptions)
        self.sendingRtpParametersByKind = sendingRtpParametersByKind
        self.sendingRemoteRtpParametersByKind = sendingRemoteRtpParametersByKind
    }
    
    func send(_ track: RTCMediaStreamTrack,
              _ encodings: Array<RTCRtpEncodingParameters>?,
              _ codecOptions: MSJson?,
              _ completion: @escaping MSSendCompletion) {

        //MSLogger.shared.startPeerLog(pc.getPeeer())
        
        if (track.kind == "audio") {
           
            NSLog("Audio")
        }
        let mediaSectionIdx = remoteSdp.getNextMediaSectionIdx()
        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = .sendOnly

        if let encodings = encodings {
            transceiverInit.sendEncodings = encodings
        }

        self.newTransceiver = pc.addTransceiver(track, transceiverInit)
        //self.newTransceiver.direction = .sendOnly

        if (self.newTransceiver == nil) {
            //MSLogger.shared.printPeerLog(pc.getPeeer())
            NSLog("[MS] Could not create transceiver")
            completion(nil, MSError(type: .peerConnection, message: "Error creating transceiver"))
            return
        }
    
        let optional = [ "DtlsSrtpKeyAgreement": "false"]
        let offerConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optional)
        
        pc.createOffer(offerConstraints, completion: { [self] sdp, error in
            
            let offer: String! = sdp
            let localSdpObject = SDPTransform.parse(offer)
            
            if !transportReady {
                setupTransport("server", localSdpObject)
            }
            
            print("[MS] Calling pc->SetLocalDescription(): %s", offer.utf8)

            pc.setLocalDescription(.offer, offer) { [self] error in
                if let error = error {
                    //newTransceiver.direction = .inactive
                    newTransceiver.sender.track = nil

                    completion(nil, MSError(type: .peerConnection, message: error.message))
                }
                else {
                    var sendingRtpParameters = sendingRtpParametersByKind[track.kind] as! MSJson
                    
                    // We can now get the transceiver.mid.
                    let localId: String! = newTransceiver.mid

                    // Set MID.
                    sendingRtpParameters["mid"] = localId
                
                    let localSdp = pc.getLocalDescription()
                    let localSdpObject = SDPTransform.parse(localSdp)

                    let offerMediaObject = (localSdpObject["media"] as! MSJsonArray)[mediaSectionIdx.idx]

                    // Set RTCP CNAME.
                    var rtcp = sendingRtpParameters["rtcp"] as! MSJson
                    rtcp["cname"] = SDPUtils.getCname(offerMediaObject)
                    sendingRtpParameters["rtcp"] = rtcp

                    // Set RTP encodings by parsing the SDP offer if no encodings are given.
                    if (encodings == nil ){
                        sendingRtpParameters["encodings"] = SDPUtils.getRtpEncodings(offerMediaObject)
                    }
                    // Set RTP encodings by parsing the SDP offer and complete them with given
                    // one if just a single encoding has been given.
                    else if let encodings = encodings, encodings.count == 1
                    {
                        var newEncodings = SDPUtils.getRtpEncodings(offerMediaObject)

                        if var firstNewEncodings = newEncodings?.first {
                            let firstEncodings = encodings[0]
                            MSHandler.fillJsonRtpEncodingParameters(&firstNewEncodings, firstEncodings )
                            
                            newEncodings![0] = firstNewEncodings
                            sendingRtpParameters["encodings"] = newEncodings
                        }
                        else {
                            completion(nil, MSError(type: .peerConnection, message: "[MS] SDPUtils.getRtpEncodings() issue"))
                        }
                    }

                    // Otherwise if more than 1 encoding are given use them verbatim.
                    else if let encodings = encodings, encodings.count > 1
                    {
                        sendingRtpParameters["encodings"] = MSJsonArray()
                        for encoding in encodings {
                            var jsonEncoding = MSJson()

                            MSHandler.fillJsonRtpEncodingParameters(&jsonEncoding, encoding )
                            
                            var array = sendingRtpParameters["encodings"] as! MSJsonArray
                            array.append(jsonEncoding)
                            sendingRtpParameters["encodings"] = array
                        }
                    }
                    
                    // If VP8 and there is effective simulcast, add scalabilityMode to each encoding.
                    let codecs = sendingRtpParameters["codecs"] as! MSJsonArray
                    let firstCodec = codecs[0]
                    let mimeType = (firstCodec["mimeType"] as! String).lowercased()
                    
                    if ((sendingRtpParameters["encodings"] as? MSJsonArray)?.count ?? 0 > 1 &&
                            (mimeType == "video/vp8" || mimeType == "video/h264")) {
                        
                        var arrayOfsendingRtpParameters = sendingRtpParameters["encodings"] as! MSJsonArray
                        for (index, encoding) in arrayOfsendingRtpParameters.enumerated() {
                            var encoding = encoding
                            encoding["scalabilityMode"] = "S1T3"
                            arrayOfsendingRtpParameters[index] = encoding
                        }
                        sendingRtpParameters["encodings"] = arrayOfsendingRtpParameters
                    }

                    remoteSdp.send(offerMediaObject,
                                   mediaSectionIdx.reuseMid,
                                   sendingRtpParameters,
                                   sendingRtpParametersByKind[track.kind] as! MSJson,
                                   codecOptions)
                   
                    let answer = remoteSdp.getSdp()
                    print("[MS] Calling pc->SetRemoteDescription(): %s", answer.utf8)
                    
                   // DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                        pc.setRemoteDescription(.answer, answer) { error in
                            if let error = error {
                                completion(nil, MSError(type: .peerConnection, message: error.message))

                            }
                            else {
                                // Store in the map.
                                mapMidTransceiver[localId] = newTransceiver
                                let sendData = MSSendData(localId: localId,
                                                          rtpSender: newTransceiver.sender,
                                                          rtpParameters: sendingRtpParameters)
                                completion(sendData, nil)
                            }
                        }
                    //}
                    
                    
                }
            }
        })
    }
    
    func stopSending(_ localId: String) {
        NSLog("[MS] stopSending")

        NSLog("[MS] localId: " + localId);
        let locaIdIt = mapMidTransceiver[localId]

        if (locaIdIt == nil) {
            NSLog("associated RtpTransceiver not found")
            return
        }

        let transceiver = locaIdIt
        transceiver?.sender.track = nil
        
        if let transceiver = transceiver {
            if pc.removeTrack(transceiver.sender) {
                remoteSdp.closeMediaSection(transceiver.mid)
            }
            else {
                NSLog("[MS] remoteSdp.closeMediaSection issue")
                return
            }
        }
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        pc.createOffer(constraints) { [self] offer, error in
            if let error = error {
                NSLog("[MS] Handler.stopSending createOffer issues: " + error.message)
                return
            }
            else {
                NSLog("[MS] calling pc.setLocalDescription(): " + offer!)

                pc.setLocalDescription(.offer, offer!) { error in
                    if let error = error {
                        NSLog("[MS] Handler.stopSending setLocalDescription issues: " + error.message)
                        return
                    }
                    else {
                        let answer = remoteSdp.getSdp()

                        NSLog("[MS] calling pc.setRemoteDescription(): " + answer)
                        pc.setRemoteDescription(.answer, answer) { error in
                            if let error = error {
                                NSLog("[MS] pc.setRemoteDescription issue: " + error.message)
                            }
                            else {
                                //Ok
                            }
                        }
                    }
                }
            }
        }
    }
    
    func replaceTrack(_ localId: String, _ track: RTCMediaStreamTrack) {
        NSLog("[MS] localId: " + localId + ". Track id: " + track.trackId)
        let localIdIt = mapMidTransceiver[localId]

        if (localIdIt == nil) {
            NSLog("[MS] replaceTrack issue : " + "associated RtpTransceiver not found" )
        }
                   
        let transceiver = localIdIt!
        transceiver.sender.track = track
    }
    
    func setMaxSpatialLayer(_ localId: String, _ spatialLayer: UInt8) {
        NSLog("[MS] localId:" + localId  + ". SpatialLayer:" + String(spatialLayer))

        let localIdIt = mapMidTransceiver[localId]

        if (localIdIt == nil) {
            NSLog("associated RtpTransceiver not found")
            return
        }

        let transceiver = localIdIt!
        _ = transceiver.sender.parameters
    }
    
    func getSenderStats(_ localId: String, _ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        NSLog("[MS] localId: " + localId);

        let localIdIt = mapMidTransceiver[localId]

        if (localIdIt == nil) {
            NSLog("[MS] associated RtpTransceiver not found")
            return
        }

        let transceiver = localIdIt!
        pc.getStats(transceiver.sender) { stats in
            completion(stats)
        }
    }
     
    override func restartIce(_ iceParameters: MSJson) {
        
    }
}

class MSRecvHandler: MSHandler {
    struct RecvData{
        var localId: String!
        var rtpReceiver: RTCRtpReceiver!
        var track: RTCMediaStreamTrack!
    }
    
    override init( _ connectDelegate: MSConnectDelegate,
                   _ iceParameters: MSJson,
                   _ iceCandidates: MSJsonArray,
                   _ dtlsParameters: MSJson,
                   _ sctpParameters: MSJson?,
                   _ peerConnectionOptions: MSPeerConnection.Options?) {
        
        super.init(connectDelegate,
                   iceParameters,
                   iceCandidates,
                   dtlsParameters,
                   sctpParameters,
                   peerConnectionOptions)
    }
    
    func receive(_ id: String, _ kind: String, _ rtpParameters: inout MSJson, _ completion: @escaping MSRecvCompletion) {
        var localId = ""
        
        var rtpParameters = rtpParameters
        
        // mid is optional, check whether it exists and is a non empty string.
        if let mid = rtpParameters["mid"] as? String, !mid.isEmpty {
            localId = "r" + mid
        }
        else {
            localId = String(mapMidTransceiver.count)
        }

        let rtcp = rtpParameters["rtcp"] as! MSJson
        let cname = rtcp["cname"] as! String

        remoteSdp.receive(localId, kind, rtpParameters, cname, id)

        let offer = remoteSdp.getSdp()

        pc.setRemoteDescription(.offer, offer) { [self] error in
            if let error = error {
                completion(nil, MSError(type: .peerConnection, message: error.message))
                return
            }
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            pc.createAnswer(constraints) { answer, error in
                if let error = error {
                    completion(nil, MSError(type: .peerConnection, message: error.message))
                    return
                }
                pc.createAnswer(constraints) { sdp, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    var localSdpObject = SDPTransform.parse(sdp!)
                    let media = (localSdpObject["media"] as! MSJsonArray).first { item -> Bool in
                        return item["mid"] as? String == localId
                    }
                    
                    var answerMediaObject = media!

                    // May need to modify codec parameters in the answer based on codec
                    // parameters in the offer.
                    SDPUtils.applyCodecParameters(&rtpParameters, &answerMediaObject)
                   
                    let answer = SDPTransform.write(&localSdpObject)

                    if (!transportReady) {
                        setupTransport("client", localSdpObject)
                    }

                    pc.setLocalDescription(.answer, answer) { error in
                        if let error = error {
                            completion(nil, MSError(type: .peerConnection, message: error.message))
                            return
                        }
                        let transceivers = pc.getTransceivers()
                        
                        let transceiver = transceivers.first { t -> Bool in
                            t.mid == localId
                        }
                        
                        if (transceiver == nil) {
                            completion(nil, MSError(type: .peerConnection, message: "new RTCRtpTransceiver not found"))
                            return
                        }

                        // Store in the map.
                        mapMidTransceiver[localId] = transceiver
                        
                        let recvData = MSRecvData(localId: localId,
                                                  rtpReceiver: transceiver!.receiver,
                                                  track: transceiver!.receiver.track!)
                        completion(recvData, nil)
                    }
                       
                }
            }
        }

        
    }
    
    func stopReceiving(_ localId: String) {
       
        let localIdIt = mapMidTransceiver[localId]

        if (localIdIt == nil) {
            NSLog("[MS] associated RtpTransceiver not found")
            return
        }

        let transceiver = localIdIt!
        remoteSdp.closeMediaSection(transceiver.mid)
        let offer = remoteSdp.getSdp()

        pc.setRemoteDescription(.offer, offer) { [self] error in
         
            let answerConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            
            pc.createAnswer(answerConstraints) { answer, error in
                if let error = error {
                    NSLog("[MS] Could not stop receiving. pc.createAnswer() failed: " + error.message)
                    return
                }
                else {
                    pc.setLocalDescription(.answer, answer!) { error in
                        if let error = error {
                            NSLog("[MS] Could not stop receiving. pc.setLocalDescription() failed: " + error.message)
                            return
                        }
                        else {
                            // Success
                        }
                    }
                }
            }
        }
    }
     
    func getReceiverStats(_ localId: String, _ completion: @escaping MSPeerConnectionGetStatsCompletion) {
        let localIdIt = mapMidTransceiver[localId]

        if (localIdIt == nil) {
            NSLog("associated RtpTransceiver not found")
            return
        }

        let transceiver = localIdIt!

        pc.getStats(transceiver.receiver) { stats in
            completion(stats)
        }
    }
    
    override func restartIce(_ iceParameters: MSJson) {
        // Provide the remote SDP handler with new remote ICE parameters.
        remoteSdp.updateIceParameters(iceParameters)

        if (!transportReady) {
            return
        }

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        pc.createAnswer(constraints) { [self] answer, error in
            if let error = error {
                NSLog("[MS] Could not restart ice for recv transport. pc.createAnswer() failed: " + error.message)
            }
            else {
                pc.setLocalDescription(.answer, answer!) { error in
                    if let error = error {
                        NSLog("[MS] Could not restart ice for recv transport. pc.setLocalDescription() failed: " + error.message)
                    }
                }
            }
        }


    }
    
    
}
