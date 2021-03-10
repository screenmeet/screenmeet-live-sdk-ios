//
//  MSVideoEncoderFactory.swift
//  ScreenMeet
//
//  Created by Ross on 06.02.2021.
//

import UIKit
import WebRTC

class MSVideoEncoderFactory : NSObject, RTCVideoEncoderFactory {

    public var encoder: RTCVideoEncoder? // ONLY WORKS WITH h264
    
    public func createEncoder(_ info: RTCVideoCodecInfo) -> RTCVideoEncoder? {

        /*
        let encoder = createEncoder(info) // will create the h264 encoder
        let customEncoder = MSVideoEncoder()
        self.encoder = customEncoder
        return encoder*/
        return nil
    }

    public func supportedCodecs() -> [RTCVideoCodecInfo] {
        return [RTCVideoCodecInfo(name: kRTCVp9CodecName)]
    }
    
}

class MSVideoEncoder: NSObject, RTCVideoEncoder {

    public var encoder: RTCVideoEncoder? // ONLY WORKS WITH h264

    public func setCallback(_ callback: @escaping RTCVideoEncoderCallback) {

        return encoder!.setCallback(callback)
    }

     public func startEncode(with settings: RTCVideoEncoderSettings, numberOfCores: Int32) -> Int {

         // Change settings here !
        return encoder!.startEncode(with: settings, numberOfCores: numberOfCores)
    }

    public func release() -> Int {

        return encoder!.release()
    }

     public func encode(_ frame: RTCVideoFrame, codecSpecificInfo info: RTCCodecSpecificInfo?, frameTypes: [NSNumber]) -> Int {

         return encoder!.encode(frame, codecSpecificInfo: info, frameTypes: frameTypes)
     }

    public func setBitrate(_ bitrateKbit: UInt32, framerate: UInt32) -> Int32 {

        return encoder!.setBitrate(bitrateKbit, framerate: framerate)
    }

    public func implementationName() -> String {

        return encoder!.implementationName()
    }

    public func scalingSettings() -> RTCVideoEncoderQpThresholds? {

        return encoder!.scalingSettings()
    }
        
    
}
