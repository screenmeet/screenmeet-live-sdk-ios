//
//  Device.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit
import WebRTC

typealias DeviceLoadCompletion = (MSError?) -> Void
typealias CreateSendTransportCompletion = (MSSendTransport?, MSError?) -> Void
typealias CreateRecvTransportCompletion = (MSRecvTransport?, MSError?) -> Void

class MSDevice: NSObject {
    private var ortc = MSOrtc()
    private var loaded: Bool = false
    
    private var extendedRtpCapabilities: MSJson!
    private var recvRtpCapabilities: MSJson!
    private var sctpCapabilities: MSJson!
    
    private var canProduceByKind: [String: Bool] = [
        "audio": false,
        "video": false
    ]
    
    func load( _ capabilities: [String: Any], _ completion: @escaping DeviceLoadCompletion) {
        if loaded {
            completion(MSError(type: .device, message: "Already Loaded"))
        }
        
        var routerCapabilities = capabilities
        if let error = ortc.validateRtpCapabilities(&routerCapabilities) {
            completion(error)
            return
        }
        
        MSHandler.getNativeRtpCapabilities { nativeCapabilities, error in
            if let error = error {
                completion(error)
                return
            }
            
            if let extendedRtpCapabilities = self.ortc.getExtendedRtpCapabilities(nativeCapabilities!, routerCapabilities) {
                self.extendedRtpCapabilities = extendedRtpCapabilities
                self.recvRtpCapabilities = self.ortc.getRecvRtpCapabilities(extendedRtpCapabilities)
                
                if let error = self.ortc.validateRtpCapabilities(&self.recvRtpCapabilities) {
                    completion(error)
                    return
                }
                
                self.canProduceByKind["audio"] = self.ortc.canSend("audio", extendedRtpCapabilities)
                self.canProduceByKind["video"] = self.ortc.canSend("video", extendedRtpCapabilities);
                
                self.sctpCapabilities = MSHandler.getNativeSctpCapabilities()
                
                if let error = self.ortc.validateSctpCapabilities(self.sctpCapabilities) {
                    completion(error)
                    return
                }
                
                self.loaded = true
                completion(nil)
            }
            else {
                completion(self.ortc.getError())
            }
        }
    }
    
    func createSendTransport(_ connectDelegate: MSSendTransportConnectDelegate,
                             _ id: String,
                             _ iceParameters: inout MSJson,
                             _ iceCandidates: inout MSJsonArray,
                             _ dtlsParameters: inout MSJson,
                             _ sctpParameters: MSJson?,
                             _ peerConnectionOptions: MSPeerConnection.Options?,
                             _ appData: MSJson?,
                             _ completion: CreateSendTransportCompletion) {
        
        if !loaded {
            completion(nil, MSError(type: .transport, message: "not loaded"))
        }

        // Validate arguments.
        if let error = ortc.validateIceParameters(&iceParameters) {
            completion(nil, error)
        }
        if let error = ortc.validateIceCandidates(&iceCandidates) {
            completion(nil, error)
        }
        if let error = ortc.validateDtlsParameters(&dtlsParameters) {
            completion(nil, error)
        }

        if var sctpParameters = sctpParameters {
            if let error = ortc.validateSctpParameters(&sctpParameters) {
                completion(nil, error)
            }
        }
        
        let transport = MSSendTransport(connectDelegate,
                        id,
                        iceParameters,
                        iceCandidates,
                        dtlsParameters,
                        sctpParameters,
                        peerConnectionOptions,
                        self.extendedRtpCapabilities!,
                        self.canProduceByKind,
                        appData)
        
        return completion(transport, nil)
    }
    
    func createRecvTransport(_ connectDelegate: MSRecvTransportConnectDelegate,
                             _ id: String,
                             _ iceParameters: inout MSJson,
                             _ iceCandidates: inout MSJsonArray,
                             _ dtlsParameters: inout MSJson,
                             _ sctpParameters: MSJson?,
                             _ peerConnectionOptions: MSPeerConnection.Options?,
                             _ appData: MSJson?,
                             _ completion: CreateRecvTransportCompletion) {
        
        if !loaded {
            completion(nil, MSError(type: .transport, message: "not loaded"))
        }

        // Validate arguments.
        if let error = ortc.validateIceParameters(&iceParameters) {
            completion(nil, error)
        }
        if let error = ortc.validateIceCandidates(&iceCandidates) {
            completion(nil, error)
        }
        if let error = ortc.validateDtlsParameters(&dtlsParameters) {
            completion(nil, error)
        }

        if var sctpParameters = sctpParameters {
            if let error = ortc.validateSctpParameters(&sctpParameters) {
                completion(nil, error)
            }
        }
        
        let transport = MSRecvTransport(connectDelegate,
                        id,
                        iceParameters,
                        iceCandidates,
                        dtlsParameters,
                        sctpParameters,
                        peerConnectionOptions,
                        self.extendedRtpCapabilities!,
                        appData)
        
        return completion(transport, nil)
    }
    
    func isLoaded() -> Bool {
        return loaded
    }
    
    /**
    * RTP capabilities of the Device for receiving media.
    */
    func getRtpCapabilities() -> MSJson{

        if (!loaded) {
            NSLog("[MS] not loaded");
        }

        return recvRtpCapabilities
    }
        
}
