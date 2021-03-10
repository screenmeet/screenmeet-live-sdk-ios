//
//  MSMediaSection.swift
//  ScreenMeet
//
//  Created by Ross on 30.01.2021.
//

import UIKit

class MSMediaSection: NSObject {
    var mediaObject = MSJson()
    
    init (_ iceParameters: MSJson, _ iceCandidates: MSJsonArray) {
        super.init()

        // Set ICE parameters.
        setIceParameters(iceParameters)

        // Set ICE candidates.
        mediaObject["candidates"] = MSJsonArray()

        for candidate in iceCandidates {
            var candidateObject = MSJson()

            // mediasoup does mandate rtcp-mux so candidates component is always
            // RTP (1).
            candidateObject["component"]  = 1
            candidateObject["foundation"] = candidate["foundation"]
            candidateObject["ip"]         = candidate["ip"]
            candidateObject["port"]       = candidate["port"]
            candidateObject["priority"]   = candidate["priority"]
            candidateObject["transport"]  = candidate["protocol"]
            candidateObject["type"]       = candidate["type"]

            if (candidate["tcpType"] != nil) {
                candidateObject["tcptype"] = candidate["tcpType"]
            }

            var array = mediaObject["candidates"] as! MSJsonArray
            array.append(candidateObject)
            mediaObject["candidates"] = array
        }

        mediaObject["endOfCandidates"] = "end-of-candidates"
        mediaObject["iceOptions"]      = "renomination"
    }
    
    func getMid() -> String {
        return mediaObject["mid"] as! String
    }
    
    func isClosed() -> Bool {
        return mediaObject["port"] as! Int == 0
    }
   
    func getObject() -> MSJson {
        return mediaObject
    }
   
    func setIceParameters(_ iceParameters: MSJson) {
        mediaObject["iceUfrag"] = iceParameters["usernameFragment"] as! String
        mediaObject["icePwd"]   = iceParameters["password"] as! String
    }
    
    func disable() {
        mediaObject["direction"] = "inactive"

        mediaObject["ext"] = nil
        mediaObject["ssrcs"] = nil
        mediaObject["ssrcGroups"] = nil
        mediaObject["simulcast"] = nil
        mediaObject["rids"] = nil
    }
    
    func close() {
        mediaObject["direction"] = "inactive"
        mediaObject["port"]      = 0

        mediaObject["ext"] = nil
        mediaObject["ssrcs"] = nil
        mediaObject["ssrcGroups"] = nil
        mediaObject["simulcast"] = nil
        mediaObject["rids"] = nil
        mediaObject["extmapAllowMixed"] = nil
    }
    
    func setDtlsRole(_ role: String) {
        
    }
    
    static func getCodecName(_ codec: MSJson) -> String{
        let regexString = "^(audio|video)/"
        let mimeType = codec["mimeType"] as! String
        
        let regex = try! NSRegularExpression(pattern: regexString, options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, mimeType.count)
        let codecString = regex.stringByReplacingMatches(in: mimeType, options: [], range: range, withTemplate: "")
        return codecString
    }
}

class MSAnswerMediaSection: MSMediaSection {
    
    init (_ iceParameters: MSJson,
          _ iceCandidates: MSJsonArray,
          _ dtlsParameters: MSJson,
          _ sctpParameters: MSJson?,
          _ offerMediaObject: MSJson,
          _ offerRtpParameters: MSJson,
          _ answerRtpParameters: MSJson,
          _ codecOptions: MSJson?) {
        
        super.init(iceParameters, iceCandidates)
        let type = offerMediaObject["type"] as! String

        mediaObject["mid"]        = offerMediaObject["mid"]
        mediaObject["type"]       = type
        mediaObject["protocol"]   = offerMediaObject["protocol"]
        mediaObject["connection"] = [ "ip": "127.0.0.1", "version": 4]
        mediaObject["port"]       = 7

        // Set DTLS role.
        let dtlsRole = dtlsParameters["role"] as! String

        if (dtlsRole == "client") {
            mediaObject["setup"] = "active"
        }
        else if (dtlsRole == "server") {
            mediaObject["setup"] = "passive"
        }
        else if (dtlsRole == "auto") {
            mediaObject["setup"] = "actpass"
        }

        if (type == "audio" || type == "video") {
            mediaObject["direction"] = "recvonly"
            mediaObject["rtp"]       = MSJsonArray()
            mediaObject["rtcpFb"]    = MSJsonArray()
            mediaObject["fmtp"]      = MSJsonArray()

            for codec in answerRtpParameters["codecs"] as! MSJsonArray {
                var rtp = [
                    "payload": codec["payloadType"] as! Int,
                    "codec":    MSMediaSection.getCodecName(codec),
                    "rate":    codec["clockRate"] as! Int
                ] as [String : Any]
                            
                if (codec["channels"] != nil) {
                    let channels = codec["channels"] as! Int

                    if (channels > 1){
                        rtp["encoding"] = channels
                    }
                }

                var arrayOfRtps = mediaObject["rtp"] as! MSJsonArray
                arrayOfRtps.append(rtp )
                mediaObject["rtp"] = arrayOfRtps

                var codecParameters = codec["parameters"] as! MSJson

                if (codecOptions != nil && !codecOptions!.isEmpty) {
                    let offerCodecs = offerRtpParameters["codecs"] as! MSJsonArray
                    var offerCodec = offerCodecs.first { offerCodec -> Bool in
                        return offerCodec["payloadType"] as? Int == codec["payloadType"] as? Int
                    }
                    let mimeType = (codec["mimeType"] as! String).lowercased()
                    if (mimeType == "audio/opus") {
                        let opusStereoIt = codecOptions!["opusStereo"]
                        if (opusStereoIt != nil) {
                            let opusStereo = opusStereoIt as! Bool
                            var params = offerCodec!["parameters"] as! MSJson
                            params["sprop-stereo"] = opusStereo ? 1 : 0
                            offerCodec!["parameters"] = params
                            
                            codecParameters["stereo"]  = opusStereo ? 1 : 0
                        }

                        let opusFecIt = codecOptions!["opusFec"]
                        if (opusFecIt != nil) {
                            let opusFec = opusFecIt as! Bool
                            var params = offerCodec!["parameters"] as! MSJson
                            params["useinbandfec"] = opusFec ? 1 : 0
                            offerCodec!["parameters"] = params
                            
                            codecParameters["useinbandfec"] = opusFec ? 1 : 0
                        }

                        let opusDtxIt = codecOptions!["opusDtx"]
                        if (opusDtxIt != nil){
                            let opusDtx = opusDtxIt as! Bool
                            var params = offerCodec!["parameters"] as! MSJson
                            params["usedtx"] = opusDtx ? 1 : 0
                            offerCodec!["parameters"] = params
                            codecParameters["usedtx"] = opusDtx ? 1 : 0
                        }

                        let opusMaxPlaybackRateIt = codecOptions!["opusMaxPlaybackRate"]
                        if (opusMaxPlaybackRateIt != nil) {
                            let opusMaxPlaybackRate = opusMaxPlaybackRateIt as! UInt32
                            codecParameters["maxplaybackrate"] = opusMaxPlaybackRate
                        }
                    }
                    else if (mimeType == "video/vp8" || mimeType == "video/vp9" || mimeType == "video/h264" || mimeType == "video/h265") {
                        let videoGoogleStartBitrateIt = codecOptions!["videoGoogleStartBitrate"]
                        if (videoGoogleStartBitrateIt != nil) {
                            let videoGoogleStartBitrate = videoGoogleStartBitrateIt as! Int
                            codecParameters["x-google-start-bitrate"] = videoGoogleStartBitrate
                        }

                        let videoGoogleMaxBitrateIt = codecOptions!["videoGoogleMaxBitrate"]
                        if (videoGoogleMaxBitrateIt != nil) {
                            let videoGoogleMaxBitrate = videoGoogleMaxBitrateIt as! Int
                            codecParameters["x-google-max-bitrate"] = videoGoogleMaxBitrate
                        }

                        let videoGoogleMinBitrateIt = codecOptions!["videoGoogleMinBitrate"]
                        if (videoGoogleMinBitrateIt != nil) {
                            let videoGoogleMinBitrate = videoGoogleMinBitrateIt as! Int
                            codecParameters["x-google-min-bitrate"] = videoGoogleMinBitrate
                        }
                    }
                }

                var fmtp: [String:Any] = [ "payload": codec["payloadType"] as! Int ]
                var config = ""

                for (key, value) in codecParameters {
                    if (!config.isEmpty) {
                        config = config + ";"
                    }
                    config = config + key
                    config = config + "="
                    if let strValue = value as? String {
                        config = config + strValue
                    }
                    else if let flaotValue = value as? Double {
                        config = config + String(flaotValue)
                    }
                    else if let intValue = value as? Int {
                        config = config + String(intValue)
                    }
                }

                if (!config.isEmpty){
                    fmtp["config"] = config
                    var fmtpArray = mediaObject["fmtp"] as! MSJsonArray
                    fmtpArray.append(fmtp as MSJson)
                    mediaObject["fmtp"] = fmtpArray
                }

                for fb in codec["rtcpFeedback"] as! MSJsonArray{
                    var array = mediaObject["rtcpFb"] as! MSJsonArray
                    array.append(["payload": codec["payloadType"] as! Int,
                                  "type":    fb["type"] as! String,
                                  "subtype": fb["parameter"] as! String
                                ])
                    mediaObject["rtcpFb"] = array
                }
            }

            var payloads = ""

            for codec in answerRtpParameters["codecs"] as! MSJsonArray {
                let payloadType = codec["payloadType"] as! Int

                if (!payloads.isEmpty) {
                    payloads = payloads + " "
                }

                payloads = payloads + String(payloadType)
            }

            mediaObject["payloads"] = payloads
            mediaObject["ext"]      = MSJsonArray()

            // Don't add a header extension if not present in the offer.
            for ext in answerRtpParameters["headerExtensions"] as! MSJsonArray {
                let localExts = offerMediaObject["ext"] as? MSJsonArray
                let localExtIt = localExts?.first { localExt -> Bool in
                    return localExt["uri"] as! String == ext["uri"] as! String
                }
               
                if (localExtIt == nil) {
                    continue
                }

                // clang-format off
                var array = mediaObject["ext"] as! MSJsonArray
                array.append(["uri": ext["uri"] as! String,
                          "value": ext["id"] as! Int])
                mediaObject["ext"] = array
            }
               

            // Allow both 1 byte and 2 bytes length header extensions.
            let extmapAllowMixedIt = offerMediaObject["extmapAllowMixed"]

            if (extmapAllowMixedIt != nil && extmapAllowMixedIt as? String != nil) {
                mediaObject["extmapAllowMixed"] = "extmap-allow-mixed"
            }

            // Simulcast.
            let simulcastId = offerMediaObject["simulcast"]
            let ridsIt      = offerMediaObject["rids"]

            if (simulcastId != nil && simulcastId as? MSJson != nil && ridsIt as? [Any] != nil) {
                var simObj = MSJson()
                simObj["dir1"] = "recv";
                simObj["list1"] = (simulcastId as! MSJson)["list1"]
                mediaObject["simulcast"] = simObj

                mediaObject["rids"] = MSJsonArray()

                for  rid in ridsIt as! MSJsonArray {
                    if (rid["direction"] as! String != "send") {
                        continue
                    }

                                
                    var array = mediaObject["rids"] as! MSJsonArray
                    array.append(["id": rid["id"] as Any,
                                  "direction": "recv"])
                    mediaObject["rids"] = array
                }
            }
            mediaObject["rtcpMux"]   = "rtcp-mux"
            mediaObject["rtcpRsize"] = "rtcp-rsize"
        }
        else if (type == "application") {
            mediaObject["payloads"] = "webrtc-datachannel"
            mediaObject["sctpPort"]       = sctpParameters?["port"]
            mediaObject["maxMessageSize"] = sctpParameters?["maxMessageSize"]
        }
        
    }
    
    override func setDtlsRole(_ role: String) {
        if (role == "client") {
            mediaObject["setup"] = "active"
        }
        else if (role == "server") {
            mediaObject["setup"] = "passive"
        }
        else if (role == "auto") {
            mediaObject["setup"] = "actpass"
        }
    }

}

class MSOfferMediaSection: MSMediaSection {
    
    init (_ iceParameters: MSJson,
          _ iceCandidates: MSJsonArray,
          _ dtlsParameters: MSJson,
          _ sctpParameters: MSJson?,
          _ mid: String,
          _ kind: String,
          _ offerRtpParameters: MSJson,
          _ streamId: String,
          _ trackId: String) {
        
        super.init(iceParameters, iceCandidates)
        
        mediaObject["mid"]  = mid
        mediaObject["type"] = kind

        if (sctpParameters == nil) {
            mediaObject["protocol"] = "UDP/TLS/RTP/SAVPF"
        }
        else {
            mediaObject["protocol"] = "UDP/DTLS/SCTP"
        }

        mediaObject["connection"] = ["ip": "127.0.0.1", "version": 4]
        mediaObject["port"] = 7

        // Set DTLS role.
        mediaObject["setup"] = "actpass"

        if (kind == "audio" || kind == "video") {
            mediaObject["direction"] = "sendonly"
            mediaObject["rtp"]       = MSJsonArray()
            mediaObject["rtcpFb"]    = MSJsonArray()
            mediaObject["fmtp"]      = MSJsonArray()

            for codec in offerRtpParameters["codecs"] as! MSJsonArray {
                var rtp = ["payload": codec["payloadType"],
                           "codec":   MSMediaSection.getCodecName(codec),
                           "rate":    codec["clockRate"]]
            
                if (codec["channels"] != nil) {
                    let channels = codec["channels"] as! Int

                    if (channels > 1) {
                        rtp["encoding"] = channels
                    }
                }

                var array = mediaObject["rtp"] as! MSJsonArray
                array.append(rtp as MSJson)
                mediaObject["rtp"] = array
                
                let codecParameters = codec["parameters"] as! MSJson
                var fmtp = ["payload": codec["payloadType"] ]
                var config = ""

                for (key, value) in codecParameters {
                    if (!config.isEmpty) {
                        config = config + ";"
                    }

                    config = config + key
                    config = config + "="
                   
                    if let strValue = value as? String {
                        config = config + strValue
                    }
                    else if let floatValue = value as? Double {
                        config = config + String(floatValue)
                    }
                    else if let intValue = value as? Int {
                        config = config + String(intValue)
                    }
                }

                if (!config.isEmpty) {
                    fmtp["config"] = config
                    var array = mediaObject["fmtp"] as! MSJsonArray
                    array.append(fmtp as MSJson)
                    mediaObject["fmtp"] = array
                }

                for fb in codec["rtcpFeedback"] as! MSJsonArray {
                    var array = mediaObject["rtcpFb"] as! MSJsonArray
                    array.append(["payload": codec["payloadType"] as! Int,
                              "type":    fb["type"] as! String,
                              "subtype": fb["parameter"] as! String])
                    mediaObject["rtcpFb"] = array
                }
            }

            var payloads = ""

            for codec in offerRtpParameters["codecs"] as! MSJsonArray {
                let payloadType = codec["payloadType"] as! Int

                if (!payloads.isEmpty) {
                    payloads = payloads + " "
                }

                payloads = payloads + String(payloadType)
            }

            mediaObject["payloads"] = payloads
            mediaObject["ext"]      = MSJsonArray()

            for ext in offerRtpParameters["headerExtensions"] as! MSJsonArray {
                var array = mediaObject["ext"] as! MSJsonArray
                array.append([ "uri":   ext["uri"] as! String,
                               "value": ext["id"] as! Int])
            }
            
            mediaObject["rtcpMux"] = "rtcp-mux"
            mediaObject["rtcpRsize"] = "rtcp-rsize"

            let encodings = offerRtpParameters["encodings"] as! MSJsonArray
            let encoding = encodings[0]
                
            let ssrc = encoding["ssrc"] as! Int
            let rtxSsrc: Int

            let rtxIt = encoding["rtx"] as? MSJson
            if (rtxIt != nil && rtxIt?["ssrc"] != nil) {
                let rtxObj = encoding["rtx"] as! MSJson
                rtxSsrc = rtxObj["ssrc"] as! Int
            }
            else {
                rtxSsrc = 0
            }

            mediaObject["ssrcs"]      = MSJsonArray()
            mediaObject["ssrcGroups"] = MSJsonArray()

            let rtcpOfferRtpParameters = offerRtpParameters["rtcp"] as! MSJson
                
            let cnameIt = rtcpOfferRtpParameters["cname"]
            if (cnameIt != nil && cnameIt as? String != nil) {
                let cname = cnameIt as! String

                var msid = streamId
                msid = msid + " " + trackId

                var ssrcsArray = mediaObject["ssrcs"] as! MSJsonArray
                ssrcsArray.append(["id": ssrc, "attribute": "cname", "value": cname])
                ssrcsArray.append(["id": ssrc, "attribute": "msid", "value": msid])
                mediaObject["ssrcs"] = ssrcsArray
                    
                if (rtxSsrc != 0) {
                    let  ssrcs = String(ssrc) + " " + String(rtxSsrc)

                    var ssrcsArray = mediaObject["ssrcs"] as! MSJsonArray
                    ssrcsArray.append(["id": rtxSsrc, "attribute": "cname", "value": cname ])
                    ssrcsArray.append([ "id": rtxSsrc, "attribute": "msid", "value": msid ])
                    mediaObject["ssrcs"] = ssrcsArray
                        
                    let ssrcGroupsArray = mediaObject["ssrcGroups"] as! MSJsonArray
                       
                    ssrcsArray.append([ "semantics": "FID", "ssrcs": ssrcs])
                    mediaObject["ssrcGroups"] = ssrcGroupsArray
                }
            }
        }
        else if (kind == "application") {
            mediaObject["payloads"]   = "webrtc-datachannel"
            mediaObject["sctpPort"]   = sctpParameters?["port"] as! Int
            mediaObject["maxMessageSize"] = sctpParameters?["maxMessageSize"] as! Int
        }
        
    }
    
    override func setDtlsRole(_ role: String) {
        mediaObject["setup"] = "actpass"
    }
}

