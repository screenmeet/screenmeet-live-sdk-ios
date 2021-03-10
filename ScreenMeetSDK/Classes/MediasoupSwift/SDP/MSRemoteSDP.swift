//
//  MSRemoteSDP.swift
//  ScreenMeet
//
//  Created by Ross on 30.01.2021.
//

import UIKit

class MSRemoteSDP: NSObject {
    
    // Generic sending RTP parameters for audio and video.
    private var rtpParametersByKind = MSJson()
    
    // Transport remote parameters, including ICE parameters, ICE candidates,
    // DTLS parameteres and SCTP parameters.
    private var iceParameters = MSJson()
    private var iceCandidates = MSJsonArray()
    private var dtlsParameters = MSJson()
    private var sctpParameters: MSJson? = MSJson()
    
    // MediaSection instances.
    var mediaSections = [MSMediaSection]()
    
    // MediaSection indices indexed by MID.
    var midToIndex = [String: Int]()
    
    // First MID.
    var firstMid: String!
    
    // Generic sending RTP parameters for audio and video.
    var sendingRtpParametersByKind = MSJson()
    
    // SDP global fields.
    var sdpObject = MSJson()
    
    struct MediaSectionIdx {
        var idx: Int
        var reuseMid: String? = nil
    }
    
    init(_ iceParameters: MSJson,
         _ iceCandidates: MSJsonArray,
         _ dtlsParameters: MSJson,
         _ sctpParameters: MSJson?) {
        
        super.init()
        
        self.iceParameters = iceParameters
        self.iceCandidates = iceCandidates
        self.dtlsParameters = dtlsParameters
        self.sctpParameters = sctpParameters
        
        // clang-format off
        sdpObject = [ "version": 0,
                      "origin":[ "address":        "0.0.0.0",
                                 "ipVer":          4,
                                 "netType":        "IN",
                                 "sessionId":      10000,
                                 "sessionVersion": 0,
                                 "username":       "libmediasoupclient"
                                ],
                      "name": "-",
                      "timing": ["start": 0, "stop":  0],
                      "media": MSJsonArray()]

        // If ICE parameters are given, add ICE-Lite indicator.
        if (iceParameters["iceLite"] != nil) {
             sdpObject["icelite"] = "ice-lite"
        }

        // clang-format off
        sdpObject["msidSemantic"] = [
                    "semantic": "WMS",
                    "token":    "*"
        ]
        
        // clang-format on

        // NOTE: We take the latest fingerprint.
        let numFingerprints = (dtlsParameters["fingerprints"] as! MSJsonArray).count

        let fingerPrints = dtlsParameters["fingerprints"] as! MSJsonArray
        sdpObject["fingerprint"] = [
            "type": fingerPrints[numFingerprints - 1]["algorithm"],
            "hash": fingerPrints[numFingerprints - 1]["value"]
        ]

        var groups = MSJsonArray()
        groups.append([
                        "type": "BUNDLE",
                        "mids": ""])
        
        sdpObject["groups"] = groups
    }
    
    func send(
        _ offerMediaObject: MSJson,
        _ reuseMid: String?,
        _ offerRtpParameters: MSJson,
        _ answerRtpParameters: MSJson,
        _ codecOptions: MSJson?) {
        
        let mediaSection = MSAnswerMediaSection(
                  iceParameters,
                  iceCandidates,
                  dtlsParameters,
                  sctpParameters,
                  offerMediaObject,
                  offerRtpParameters,
                  answerRtpParameters,
                  codecOptions)

        // Closed media section replacement.
        if let reuseMid = reuseMid, !reuseMid.isEmpty {
            replaceMediaSection(mediaSection, reuseMid)
        }
        else{
            addMediaSection(mediaSection)
        }
    }
    
    func receive(
        _ mid: String,
        _ kind: String,
        _ offerRtpParameters: MSJson,
        _ streamId: String,
        _ trackId: String) {
        let mediaSection = MSOfferMediaSection(self.iceParameters,
                                               self.iceCandidates,
                                               self.dtlsParameters,
                                               nil,
                                               mid,
                                               kind,
                                               offerRtpParameters,
                                               streamId,
                                               trackId)
        self.addMediaSection(mediaSection)
    }
    
    func updateIceParameters(_ iceParameters: MSJson) {
        self.iceParameters = iceParameters

        if (iceParameters["iceLite"] != nil) {
            sdpObject["icelite"] = "ice-lite"
        }
        
        for (index, mediaSection) in mediaSections.enumerated() {
            mediaSection.setIceParameters(iceParameters)
            
            var array = sdpObject["media"] as! MSJsonArray
            array[index] = mediaSection.getObject()
            sdpObject["media"] = array
        }
    }
    
    func updateDtlsRole(_  role: String) {
        dtlsParameters["role"] = role

        if (iceParameters["iceLite"] != nil) {
            sdpObject["icelite"] = "ice-lite"
        }
        
        for (index, mediaSection) in mediaSections.enumerated() {
            mediaSection.setDtlsRole(role)
            
            var array = sdpObject["media"] as! MSJsonArray
            array[index] = mediaSection.getObject()
            sdpObject["media"] = array
        }
    }
    
    func disableMediaSection(_ mid: String) {
        let idx  = midToIndex[mid];
        let mediaSection = mediaSections[idx!]
        mediaSection.disable()
    }
    
    func closeMediaSection(_ mid: String) {
        let idx = midToIndex[mid]
        let mediaSection = mediaSections[idx!]

        // NOTE: Closing the first m section is a pain since it invalidates the
        // bundled transport, so let's avoid it.
        if (mid == firstMid) {
            mediaSection.disable()
        }
        else {
            mediaSection.close()
        }

        // Update SDP media section.
        var mediaObjects = sdpObject["media"] as! MSJsonArray
        mediaObjects[idx!] = mediaSection.getObject()
        sdpObject["media"] = mediaObjects

        // Regenerate BUNDLE mids.
        regenerateBundleMids()
    }
    
    func getSdp() -> String {
        // Increase SDP version.
        var sdpOrigin = sdpObject["origin"] as! MSJson
        var version = sdpOrigin["sessionVersion"] as! Int
        version = version + 1
        sdpOrigin["sessionVersion"] = version
        sdpObject["origin"] = sdpOrigin
        
        return SDPTransform.write(&sdpObject)
    }

    private func addMediaSection(_ newMediaSection: MSMediaSection) {
        if (firstMid == nil || firstMid.isEmpty) {
            firstMid = newMediaSection.getMid()
        }

        // Add it in the vector.
        mediaSections.append(newMediaSection)

        // Add to the map.
        midToIndex[newMediaSection.getMid()] = mediaSections.count - 1

        // Add to the SDP object.
        var mediaObjects = sdpObject["media"] as! MSJsonArray
        mediaObjects.append(newMediaSection.getObject())
        sdpObject["media"] = mediaObjects

        regenerateBundleMids()
    }
    
    func replaceMediaSection(_ newMediaSection: MSMediaSection, _ reuseMid: String) {
        // Store it in the map.
        if (!reuseMid.isEmpty) {
            let idx = midToIndex[reuseMid]
            let oldMediaSection = mediaSections[idx!]

            // Replace the index in the vector with the new media section.
            mediaSections[idx!] = newMediaSection

            // Update the map.
            midToIndex[oldMediaSection.getMid()] = nil
            midToIndex[newMediaSection.getMid()] = idx

            // Delete old MediaSection.

            // Update the SDP object.
            var mediaObjects = sdpObject["media"] as! MSJsonArray
            mediaObjects[idx!] = newMediaSection.getObject()

            // Regenerate BUNDLE mids.
            regenerateBundleMids();
        }
        
        else {
            let idx = midToIndex[newMediaSection.getMid()]
            //let oldMediaSection = mediaSections[idx!]

            // Replace the index in the vector with the new media section.
            mediaSections[idx!] = newMediaSection

            // Update the SDP object.
            var mediaObjects = sdpObject["media"] as! MSJsonArray
            mediaObjects[mediaSections.count - 1] = newMediaSection.getObject()
        }
    }
    
    func regenerateBundleMids() {
        var mids = ""

        for mediaSection in mediaSections {
            if (!mediaSection.isClosed()){
                if (mids.isEmpty) {
                    mids = mediaSection.getMid()
                }
                else {
                    mids.append(" ")
                    mids.append(mediaSection.getMid())
                }
            }
        }

        var sdpGroups = sdpObject["groups"] as! MSJsonArray
        var sdpMids = sdpGroups[0]
        sdpMids["mids"] = mids
        sdpGroups[0] = sdpMids
        sdpObject["groups"] = sdpGroups
    }
    
    func getNextMediaSectionIdx() -> MediaSectionIdx {
        
        var idx = 0
        for mediaSection in mediaSections {
            if mediaSection.isClosed() {
                return MediaSectionIdx(idx: idx, reuseMid: mediaSection.getMid())
            }
            idx += 1
        }
        
        // If no closed media section is found, return next one.
        return MediaSectionIdx(idx: mediaSections.count)
       
    }

}
