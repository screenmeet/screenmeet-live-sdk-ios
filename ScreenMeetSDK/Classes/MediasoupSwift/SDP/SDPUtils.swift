//
//  SDPUtils.swift
//  ScreenMeet
//
//  Created by Ross on 27.01.2021.
//

import UIKit

class SDPUtils: NSObject {
    static func extractRtpCapabilities(_ sdpObject: MSJson) -> MSJson {
        
        var codecs = [Int: MSJson]()
        var headerExtensions = MSJsonArray()
        
        var gotAudio = false
        var gotVideo = false
        
        for m in (sdpObject["media"] as! MSJsonArray) {
             
            let kind = m["type"] as! String
            
            if (kind == "audio"){
                if (gotAudio) { continue }
                   
                gotAudio = true;
            }
            else if (kind == "video") {
                if (gotVideo) { continue }

                gotVideo = true;
            }
            else {
                continue;
            }
            
            for rtp in m["rtp"] as! MSJsonArray {
                var mimeType = kind
                
                mimeType = mimeType + "/" + (rtp["codec"] as! String)
                var codec: MSJson = ["mimeType": mimeType,
                                     "kind": kind,
                                     "clockRate": rtp["rate"] as! Int,
                                     "preferredPayloadType": rtp["payload"] as! Int,
                                     "rtcpFeedback": MSJsonArray(),
                                     "parameters": MSJson()]
                if (kind == "audio") {
                    let jsonEncoding = rtp["encoding"]
                    
                    if jsonEncoding != nil {
                        codec["channels"] = Int(jsonEncoding as! String)
                    }
                    else {
                        codec["channels"] = 1
                    }
                }
                let intValue = Int(truncatingIfNeeded: codec["preferredPayloadType"] as! Int)
                codecs[intValue] = codec
            }
            
            // Get codec parameters.
            for fmtp in m["fmtp"] as! MSJsonArray {
                let parameters = SDPTransform.parseParams(fmtp["config"] as! String)
                
                let intValue = Int(truncatingIfNeeded: fmtp["payload"] as! Int)
                let jsonPayload = codecs[intValue]
                
                if jsonPayload == nil {
                    continue
                }
                
                var codec = jsonPayload!
                codec["parameters"] = parameters
                
                codecs[intValue] = codec
            }
            
            // Get RTCP feedback for each codec.
            for fb in m["rtcpFb"] as! MSJsonArray {
                let intValue = Int((fb["payload"] as! String))
                
                if intValue == nil {
                    continue
                }
                
                var codec = codecs[intValue!]
                
                if codec == nil {
                    continue
                }
                
                var feedback: MSJson = ["type": fb["type"] as! String]
                
                let jsonSubtype = fb["subtype"]
                
                if jsonSubtype != nil {
                    feedback["parameter"] = jsonSubtype!
                }
                
                if var feedbacks = codec!["rtcpFeedback"] as? MSJsonArray {
                    feedbacks.append(feedback)
                    codec!["rtcpFeedback"] = feedbacks
                }
                
                codecs[intValue!] = codec
                
            }
            
            // Get RTP header extensions.
            for ext in m["ext"] as! MSJsonArray {
                let headerExtension = ["kind":  kind,
                                       "uri": ext["uri"],
                                       "preferredId": ext["value"]]
                
                headerExtensions.append(headerExtension as MSJson)
            }
        }
        
        var codecsArray = MSJsonArray()
        for (_, value) in codecs {
            codecsArray.append(value)
        }
        
        let rtpCapabilities: [String: Any] = ["headerExtensions":  headerExtensions,
                                              "codecs": codecsArray,
                                              "fecMechanisms": MSJsonArray()] //TODO
        
        return rtpCapabilities
    }
    
    static func extractDtlsParameters(_ sdpObject: MSJson) -> MSJson {
        var m: MSJson!
        var fingerprint: MSJson!
        var role: String = ""

        for media in sdpObject["media"] as! MSJsonArray {
            if (media["iceUfrag"] != nil && media["port"] as! Int != 0) {
                m = media
                break
            }
        }

        if (m["fingerprint"] != nil) {
            fingerprint = m["fingerprint"] as? MSJson
        }
        else if (sdpObject["fingerprint"] != nil) {
            fingerprint = sdpObject["fingerprint"] as? MSJson
        }

        if (m["setup"] != nil) {
            let setup = m["setup"] as! String

            if (setup == "active") {
                role = "client"
            }
            else if (setup == "passive") {
                role = "server"
            }
            else if (setup == "actpass") {
                role = "auto"
            }
        }

        var arrayOfDtls = MSJsonArray()
        arrayOfDtls.append(["algorithm": fingerprint["type"] as Any,
                            "value": fingerprint["hash"] as Any])
        
        let dtlsParameters: MSJson = [ "role": role,
                                       "fingerprints": arrayOfDtls]
        
        return dtlsParameters
    }
    
    static func getCname(_ offerMediaObject: MSJson) -> String {
        let jsonMssrcsIt = offerMediaObject["ssrc"]
        if (jsonMssrcsIt == nil) {
            return ""
        }

        let mSsrcs = jsonMssrcsIt as? MSJsonArray

        let jsonSsrcIt = mSsrcs?.first { line -> Bool in
            let jsonAttributeIt = line["attribute"]
            return jsonAttributeIt as? String != nil
        }
        
        if jsonSsrcIt == nil {
            return ""
        }
        
        let ssrcCnameLine = jsonSsrcIt!
        return ssrcCnameLine["value"] as! String
    }

    static func getRtpEncodings(_ offerMediaObject: MSJson) -> MSJsonArray? {
        var ssrcs = Set<Int>()

        for line in offerMediaObject["ssrcs"] as! MSJsonArray {
            let ssrc = line["id"] as! Int
            ssrcs.insert(ssrc)
        }
        
        if ssrcs.isEmpty {
            //MSC_THROW_ERROR("no a=ssrc lines found");
            NSLog("no a=ssrc lines found")
            return nil
        }
                
        // Get media and RTX SSRCs.
        var ssrcToRtxSsrc = [Int: Int]()
        let jsonSsrcGroupsIt = offerMediaObject["ssrcGroups"]
        if (jsonSsrcGroupsIt != nil) {
            let ssrcGroups = jsonSsrcGroupsIt

            // First assume RTX is used.
            for  line in ssrcGroups as! MSJsonArray {
                if (line["semantics"] as? String != "FID") {
                    continue
                }

                let fidLine = line["ssrcs"] as! String
                let v       = fidLine.components(separatedBy: " ")
                let ssrc    = Int(v[0])
                let rtxSsrc = Int(v[1])

                if (ssrcs.contains(ssrc!)){
                    // Remove both the SSRC and RTX SSRC from the Set so later we know that they
                    // are already handled.
                    ssrcs.remove(ssrc!)
                    ssrcs.remove(rtxSsrc!)
                }

                // Add to the map.
                ssrcToRtxSsrc[ssrc!] = rtxSsrc
            }
        }

        // If the Set of SSRCs is not empty it means that RTX is not being used, so take
        // media SSRCs from there.
        for ssrc in ssrcs {
            // Add to the map.
            ssrcToRtxSsrc[ssrc] = 0
        }

        // Fill RTP parameters.
        var encodings = MSJsonArray()

        for  (key, value) in ssrcToRtxSsrc {
            var encoding: MSJson = [ "ssrc": key ]

            if value != 0 {
                encoding["rtx"] = [ "ssrc": value ]
            }

            encodings.append(encoding)
        }

        return encodings
    }

    static func applyCodecParameters(_ offerRtpParameters: inout MSJson, _ answerMediaObject: inout MSJson) {
        for codec in offerRtpParameters["codecs"] as! MSJsonArray {
            let mimeType = (codec["mimeType"] as! String).lowercased()

            // Avoid parsing codec parameters for unhandled codecs.
            if (mimeType != "audio/opus") {
                continue
            }

            let rtps = answerMediaObject["rtp"] as? MSJsonArray
            let jsonRtpIt = rtps?.first(where: { r -> Bool in
                r["payload"] as! Int == codec["payloadType"] as! Int
            })
                       

            if (jsonRtpIt == nil) {
                continue
            }

            // Just in case.
            if (answerMediaObject["fmtp"] == nil) {
                answerMediaObject["fmtp"] = MSJsonArray()
            }

            let fmtps = answerMediaObject["fmtp"] as? MSJsonArray
            var jsonFmtpIt = fmtps?.first(where: { f -> Bool in
                return f["payload"] as! Int == codec["payloadType"] as! Int
            })
                
            if (jsonFmtpIt == nil){
                let fmtp = [ "payload": codec["payloadType"], "config": "" ]
                var array = answerMediaObject["fmtp"] as! MSJsonArray
                array.append(fmtp as MSJson)
                answerMediaObject["fmtp"] = array
                
                jsonFmtpIt = array.last!
            }

            var fmtp = jsonFmtpIt!
            var parameters = SDPTransform.parseParams(fmtp["config"] as! String)

            if (mimeType == "audio/opus") {
                let params = codec["parameters"] as? MSJson
                let jsonSpropStereoIt = params?["sprop-stereo"]

                if (jsonSpropStereoIt as? Bool != nil){
                    let spropStereo = jsonSpropStereoIt as! Bool
                    parameters["stereo"] = spropStereo ? 1 : 0;
                    }
                }

                // Write the codec fmtp.config back.
                var config = ""

                for (key, value) in parameters{
                    if (!config.isEmpty) {
                        config.append(";")
                    }

                    config.append(key)
                    config.append("=")
                    
                    if let strValue = value as? String {
                        config.append(strValue)
                    }
                    else if let floatValueValue = value as? Double {
                        config.append(String(floatValueValue))
                    }
                    else if let intValueValue = value as? Int {
                        config.append(String(intValueValue))
                    }
                }

                fmtp["config"] = config
            
                // Replace last object
                var array = answerMediaObject["fmtp"] as! MSJsonArray
                array[array.count-1] = fmtp
                answerMediaObject["fmtp"] = array
            }
    }
    
}
