//
//  MSOrtc.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import WebRTC

class MSOrtc: NSObject {
    private var latestError: MSError!
    
    private let probatorMid = "probator"
    private let probatorSsrc: Int = 1234
    /**
    * Validates RtpCapabilities. It may modify given data by adding missing
    * fields with default values.
    */
    func validateRtpCapabilities(_ caps: inout MSJson) -> MSError? {
        if let codecs = caps["codecs"] {
            if (codecs as? [Any]) == nil {
                return MSError(type: .sdpTransformFormatError, message: "codecs is not an array")
            }
        }
        else {
            caps["codecs"] = MSJsonArray()
        }
        
        // codecs is optional. If unset, fill with an empty array.
        var validatedCodecs = MSJsonArray()
        for codec in caps["codecs"] as! MSJsonArray {
            if let validatedCodec = validateRtpCodecCapability(codec) {
                validatedCodecs.append(validatedCodec)
            }
            else {
                return latestError
            }
        }
        caps["codecs"] = validatedCodecs
        
        // headerExtensions is optional. If unset, fill with an empty array.
        var validatedHeaderExtentions = MSJsonArray()
        for headerExtension in caps["headerExtensions"] as! MSJsonArray {
            if let validatedHeaderExtension = validateRtpHeaderExtension(headerExtension) {
                validatedHeaderExtentions.append(validatedHeaderExtension)
            }
            else {
                return latestError
            }
        }
        caps["headerExtensions"] = validatedHeaderExtentions
        return nil
        
    }
    
    /**
    * Validates RtpCodecCapability. It may modify given data by adding missing
    * fields with default values.
    */
    
    func validateRtpCodecCapability(_ codec: MSJson) -> MSJson? {
        var validatedCodec = codec
        
        let mimeTypeRegex = "^(audio|video)/(.+)"
        
        let mimeType = codec["mimeType"]
        let preferredPayloadType = codec["preferredPayloadType"]
        let clockRate = codec["clockRate"]
        let channels = codec["channels"]
        let parameters = codec["parameters"]
        let rtcpFeedback = codec["rtcpFeedback"]
        
        // mimeType is mandatory.
        if (mimeType == nil || (mimeType as? String) == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "missing codec.mimeType")
            return nil
        }
        
        let stringMimeType = mimeType as! String
        let matchedStrings = stringMimeType.matches(mimeTypeRegex)
        
        if matchedStrings.isEmpty {
            latestError = MSError(type: .sdpTransformFormatError, message: "invalid codec.mimeType")
            return nil
        }
        
        validatedCodec["kind"] = matchedStrings[1]
        
        // preferredPayloadType is optional.
        if (preferredPayloadType != nil && preferredPayloadType as? Int == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "invalid codec.preferredPayloadType")
            return nil
        }

        // clockRate is mandatory.
        if (clockRate == nil || (clockRate as? Int) == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "missing codec.clockRate")
            return nil
        }
        
        // channels is optional. If unset, set it to 1 (just if audio).
        if (validatedCodec["kind"] as? String == "audio"){
            if (channels == nil || (channels as? Int) == nil) {
                validatedCodec["channels"] = 1
            }
        }
        else {
            if (channels != nil) {
                validatedCodec["channels"] = nil
            }
        }
        
        // parameters is optional. If unset, set it to an empty object.
        if (parameters == nil || parameters as? MSJson == nil) {
            validatedCodec["parameters"] = MSJson()
        }
        
        for (key, value) in validatedCodec["parameters"] as! MSJson {
           
            if (value as? String == nil && value as? Int == nil) {
                latestError = MSError(type: .sdpTransformFormatError, message: "invalid codec parameter")
                return nil
            }
            // Specific parameters validation.
            if (key == "apt")
            {
                if (value as? Int == nil) {
                    latestError = MSError(type: .sdpTransformFormatError, message: "invalid codec apt parameter")
                    return nil
                }
            }
        }
        
        // rtcpFeedback is optional. If unset, set it to an empty array.
        if (rtcpFeedback == nil || rtcpFeedback as? [Any] == nil) {
            validatedCodec["rtcpFeedback"] = MSJsonArray()
        }

        var validatedFeedbacks = validatedCodec["rtcpFeedback"] as! MSJsonArray
        for (index, fb) in validatedFeedbacks.enumerated() {
            if let validatedRtcpFeedback = validateRtcpFeedback(fb) {
                validatedFeedbacks[index] = validatedRtcpFeedback
            }
            else {
                return nil
            }
        }
        
        validatedCodec["rtcpFeedback"] = validatedFeedbacks
        
        return validatedCodec
    }
    
    /**
    * Validates RtpHeaderExtensionParameters. It may modify given data by adding missing
        * fields with default values.
    */
    func validateRtpHeaderExtension(_ ext: MSJson) -> MSJson? {
        var validatedExt = ext
        
        let kind = ext["kind"]
        let uri = ext["uri"]
        let preferredId = ext["preferredId"]
        let preferredEncrypt = ext["preferredEncrypt"]
        let direction = ext["direction"]
        
        // kind is optional. If unset set it to an empty string.
        if (kind == nil || kind as? String == nil) {
            validatedExt["kind"] = ""
        }
        
        if kind as? String != "" && kind as? String != "audio" && kind as? String != "video" {
            latestError = MSError(type: .sdpTransformFormatError, message: "invalid ext.kind")
            return nil
        }
        
        // uri is mandatory.
        if (uri == nil || uri as? String == nil || (uri as? String)?.isEmpty ?? false) {
            latestError = MSError(type: .sdpTransformFormatError, message: "missing ext.uri")
            return nil
        }
        
        // preferredId is mandatory.
        if (preferredId == nil || preferredId as? Int == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "missing ext.preferredId")
            return nil
        }
        
        // preferredEncrypt is optional. If unset set it to false.
        if (preferredEncrypt != nil && preferredEncrypt as? Bool == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "invalid ext.preferredEncrypt")
            return nil
        }
        else if preferredEncrypt == nil {
            validatedExt["preferredEncrypt"] = false
        }
                
        
        // direction is optional. If unset set it to sendrecv.
        if (direction != nil && direction as? String == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "invalid ext.direction")
            return nil
        }
        else {
            validatedExt["direction"] = "sendrecv"
        }
        
        return validatedExt
    }
    
    /**
    * Validates RtpEncodingParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateRtpEncodingParameters(_ encoding: MSJson) -> MSJson? {
        var modififedEncoding = encoding
        
        let ssrc            = encoding["ssrc"]
        let rid             = encoding["rid"]
        let rtx             = encoding["rtx"]
        let dtx             = encoding["dtx"]
        let scalabilityMode = encoding["scalabilityMode"]

        // ssrc is optional.
        if (ssrc != nil && ssrc as? Int == nil) {
            latestError = MSError(type: .device, message: "invalid encoding.ssrc")
            return nil
        }

        // rid is optional.
        if (rid != nil && rid as? String == nil || (rid as? String)?.isEmpty ?? false) {
            latestError = MSError(type: .device, message: "invalid encoding.rid")
            return nil
        }

        // rtx is optional.
        if (rtx != nil && rtx as? MSJson == nil) {
            latestError = MSError(type: .device, message: "invalid encoding.rtx")
            return nil
        }
        else if (rtx != nil) {
            let rtxSsrc = (rtx as! MSJson)["ssrc"]

            // RTX ssrc is mandatory if rtx is present.
            if (rtxSsrc == nil || rtxSsrc as? Int == nil) {
                latestError = MSError(type: .device, message: "missing encoding.rtx.ssrc")
                return nil
            }
        }

        // dtx is optional. If unset set it to false.
        if (dtx == nil || dtx as? Bool == nil) {
            modififedEncoding["dtx"] = false
        }
                    

        // scalabilityMode is optional.
        if (scalabilityMode != nil && scalabilityMode as? String == nil || (scalabilityMode as? String)?.isEmpty ?? false ) {
            latestError = MSError(type: .device, message: "invalid encoding.scalabilityMode")
            return nil
        }
        
        return modififedEncoding
    }
    
    /**
    * Validates RtcpParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateRtcpParameters(_ rtcp: MSJson) -> MSJson? {
        var modifiedRtcp = rtcp
        
        let cname       = rtcp["cname"]
        let reducedSize = rtcp["reducedSize"]

        // cname is optional.
        if (cname != nil && cname as? String == nil) {
            latestError = MSError(type: .device, message: "invalid rtcp.cname")
            return nil
        }

        // reducedSize is optional. If unset set it to true.
        if (reducedSize == nil || reducedSize as? Bool == nil) {
            modifiedRtcp["reducedSize"] = true
        }
                   
        return modifiedRtcp
    }
            
    
    /**
    * Validates RtpParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateRtpParameters(_ params: inout MSJson) -> MSError? {
        let mid              = params["mid"]
        var codecs           = params["codecs"] as? MSJsonArray
        var headerExtensions = params["headerExtensions"]
        var encodings        = params["encodings"]
        var rtcp             = params["rtcp"]

        // mid is optional.
        if (mid == nil && (mid as? String == nil || (mid as? String)?.isEmpty ?? false)) {
            return MSError(type: .device, message: "params.mid is not a string")
        }

        // codecs is mandatory.
        if (codecs == nil || codecs == nil) {
            return MSError(type: .device, message: "missing params.codecs")
        }

        for (index, codec) in codecs!.enumerated() {
            let codec = codec
            if let modifiedCodec = validateRtpCodecParameters(codec) {
                codecs![index] = modifiedCodec
            }
            else {
                return latestError
            }
            
        }
        params["codecs"] = codecs!

        // headerExtensions is optional. If unset, fill with an empty array.
        if (headerExtensions != nil && headerExtensions as? [Any] == nil) {
            return MSError(type: .device, message: "params.headerExtensions is not an array")
        }
        else if (headerExtensions == nil) {
            let array = MSJsonArray()
            params["headerExtensions"] = array
            headerExtensions = array
        }

        var headerExtensionsArray = (headerExtensions as! MSJsonArray)
        for (index, ext) in headerExtensionsArray.enumerated() {
            if let validatedExtension = validateRtpHeaderExtensionParameters(ext) {
                headerExtensionsArray[index] = validatedExtension
            }
            else {
                return latestError
            }
        }
        
        params["headerExtensions"] = headerExtensionsArray

        // encodings is optional. If unset, fill with an empty array.
        if (encodings != nil && encodings as? [Any] == nil) {
            return MSError(type: .device, message: "params.encodings is not an array")
        }
        else if (encodings == nil){
            let array = MSJsonArray()
            params["encodings"] = array
            encodings = array
        }

        var encodingsArray = encodings as! MSJsonArray
        for (index, encoding) in encodingsArray.enumerated() {
            if let validatedRtpEncoding = validateRtpEncodingParameters(encoding) {
                encodingsArray[index] = validatedRtpEncoding
            }
            else {
                return latestError
            }
        }
        params["encodings"] = encodingsArray
        

        // rtcp is optional. If unset, fill with an empty object.
        if (rtcp != nil && rtcp as? MSJson == nil){
            return MSError(type: .device, message: "params.rtcp is not an object")
        }
        else if rtcp == nil {
            let object = MSJson()
            params["rtcp"] = object
            rtcp = object
        }

        if let modifiedRtcp = validateRtcpParameters(rtcp as! MSJson) {
            params["rtcp"] = modifiedRtcp
            return nil
        }
        
        return latestError
    }
    
    /**
    * Validates RtpCodecParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateRtpCodecParameters(_ codec: MSJson) -> MSJson? {
        
        var modifiedCodec = codec
        let mimeTypeRegex = "^(audio|video)/(.+)"

        let mimeType      = codec["mimeType"]
        let payloadType  = codec["payloadType"]
        let clockRate    = codec["clockRate"]
        let channels     = codec["channels"]
        var parameters   = codec["parameters"]
        var rtcpFeedback = codec["rtcpFeedback"]

        // mimeType is mandatory.
        if (mimeType == nil || mimeType as? String == nil) {
            latestError = MSError(type: .device, message: "missing codec.mimeType")
            return nil
        }
        
        let mimeTypeMatches = (mimeType as! String).matches(mimeTypeRegex)

        if (mimeTypeMatches.isEmpty) {
            latestError = MSError(type: .device, message: "invalid codec.mimeType")
            return nil
        }
                    
        // payloadType is mandatory.
        if (payloadType == nil || payloadType as? Int == nil) {
            latestError = MSError(type: .device, message: "missing codec.payloadType")
            return nil
        }

        // clockRate is mandatory.
        if (clockRate == nil || clockRate as? Int == nil) {
            latestError = MSError(type: .device, message: "missing codec.clockRate")
            return nil
        }

        // Retrieve media kind from mimeType.
        let kind = mimeTypeMatches[1]

        // channels is optional. If unset, set it to 1 (just for audio).
        if (kind == "audio") {
            if (channels == nil || channels as? Int == nil) {
                modifiedCodec["channels"] = 1
            }
        }
        else {
            if (channels != nil) {
                modifiedCodec["channels"] = nil
            }
        }

        // parameters is optional. If unset, set it to an empty object.
        if (parameters == nil || parameters as? MSJson == nil) {
            modifiedCodec["parameters"] = MSJson()
            parameters = modifiedCodec["parameters"]
        }

        for (key, value) in parameters as! MSJson {
                  
            if (value as? String == nil && value as? Int == nil) {
                latestError = MSError(type: .device, message: "invalid codec parameter")
                return nil
            }

            // Specific parameters validation.
            if (key == "apt") {
                if (value as? Int == nil) {
                    latestError = MSError(type: .device, message: "invalid codec apt parameter")
                    return nil
                }
            }
        }

        // rtcpFeedback is optional. If unset, set it to an empty array.
        if (rtcpFeedback == nil || rtcpFeedback as? [Any] == nil) {
            modifiedCodec["rtcpFeedback"] = MSJsonArray()
            rtcpFeedback = modifiedCodec["rtcpFeedback"]
        }

        var rtcpFeedbacks = (rtcpFeedback as! MSJsonArray)
        for (index, fb) in rtcpFeedbacks.enumerated() {
            if let validatedFeedback = validateRtcpFeedback(fb) {
                rtcpFeedbacks[index] = validatedFeedback
            }
            else {
                return nil
            }
        }
        
        modifiedCodec["rtcpFeedback"] = rtcpFeedbacks
        return modifiedCodec
    }
    
    /**
    * Validates RtpHeaderExtensionParameters. It may modify given data by adding missing
    * fields with default values.
     */
    func validateRtpHeaderExtensionParameters(_ ext: MSJson) -> MSJson? {
        var modififedExt = ext
        
        let uri        = ext["uri"]
        let id         = ext["id"]
        let encrypt    = ext["encrypt"]
        var parameters = ext["parameters"]

        // uri is mandatory.
        if (uri == nil || uri as? String == nil || (uri as? String)?.isEmpty ?? false) {
            latestError = MSError(type: .device, message: "missing ext.uri")
            return nil
        }

        // id is mandatory.
        if (id == nil || id as? Int == nil) {
            latestError = MSError(type: .device, message: "missing ext.id")
            return nil
        }

        // encrypt is optional. If unset set it to false.
        if (encrypt != nil && encrypt as? Bool == nil) {
            latestError = MSError(type: .device, message: "invalid ext.encrypt")
            return nil
        }
        else if (encrypt == nil) {
            modififedExt["encrypt"] = false
        }
                    

        // parameters is optional. If unset, set it to an empty object.
        if (parameters == nil || parameters as? MSJson == nil) {
            modififedExt["parameters"] = MSJson()
            parameters = modififedExt["parameters"]
        }
        
        for (_, value) in parameters as! MSJson {
            if (value as? String == nil && value as? Int == nil) {
                latestError = MSError(type: .device, message: "invalid header extension parameter")
                return nil
            }
        }
        
        return modififedExt
    }
    
    
    func validateRtcpFeedback(_ fb: MSJson) -> MSJson? {
        var validatedFeedback = fb
        
        let type = fb["type"]
        let parameter = fb["parameter"]
        
        // type is mandatory.
        if (type == nil || type as? String == nil) {
            latestError = MSError(type: .sdpTransformFormatError, message: "missing fb.type")
            return nil
        }
        
        // parameter is optional. If unset set it to an empty string.
        if (parameter == nil || parameter as? String == nil) {
            validatedFeedback["parameter"] = ""
        }
        
        return validatedFeedback
                        
    }
    
    /**
    * Validates SctpCapabilities. It may modify given data by adding missing
    * fields with default values.
    */
    
    func validateSctpCapabilities(_ caps: MSJson) -> MSError? {
        let numStreams = caps["numStreams"]
        if numStreams == nil || numStreams as? MSJson == nil {
            return MSError(type: .device, message: "missing caps.numStreams")
        }
        
        return validateNumSctpStreams(numStreams as! MSJson)
    }
    
    /**
    * Validates NumSctpStreams. It may modify given data by adding missing
    * fields with default values.
    */
    func validateNumSctpStreams(_ numStreams: MSJson) -> MSError? {
        let os  = numStreams["OS"]
        let mis = numStreams["MIS"]

        // OS is mandatory.
        if (os == nil || os as? UInt32 == nil) {
            return MSError(type: .device, message: "missing numStreams.OS")
        }
        

        // MIS is mandatory.
        if (mis == nil || mis as? UInt32 == nil) {
            return MSError(type: .device, message: "missing numStreams.MIS")
        }
        
        return nil
    }
    
    /**
    * Validates SctpParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateSctpParameters(_ params: inout MSJson) -> MSError? {
        let port           = params["port"]
        let os             = params["OS"]
        let mis            = params["MIS"]
        let maxMessageSize = params["maxMessageSize"]

        // port is mandatory.
        if (port == nil || port as? Int == nil){
            return MSError(type: .device, message: "missing params.port")
        }

        // OS is mandatory.
        if (os == nil || os as? Int == nil) {
            return MSError(type: .device, message: "missing params.OS")
        }

        // MIS is mandatory.
        if (mis == nil || mis as? Int == nil) {
            return MSError(type: .device, message: "missing params.MIS")
        }

        // maxMessageSize is mandatory.
        if (maxMessageSize == nil || maxMessageSize as? Int == nil) {
            return MSError(type: .device, message: "missing params.maxMessageSize")
        }
        
        return nil
    }

    /**
    * Validates SctpStreamParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateSctpStreamParameters(_ params: inout MSJson) -> MSError? {
        let streamId          = params["streamId"]
        let ordered           = params["ordered"]
        let maxPacketLifeTime = params["maxPacketLifeTime"]
        let maxRetransmits    = params["maxRetransmits"]
        let priority          = params["priority"]
        let label             = params["label"]
        let sctpProtocol      = params["protocol"]

        // streamId is mandatory.
        if (streamId == nil || streamId as? Int == nil) {
            return MSError(type: .device, message: "missing params.streamId")
        }

        // ordered is optional.
        var orderedGiven = false

        if (ordered != nil && ordered as? Bool != nil) {
            orderedGiven = true
        }
        else {
            params["ordered"] = true
        }

        // maxPacketLifeTime is optional. If unset set it to 0.
        if (maxPacketLifeTime == nil || maxPacketLifeTime as? Int == nil){
            params["maxPacketLifeTime"] = 0
        }

        // maxRetransmits is optional. If unset set it to 0.
        if (maxRetransmits == nil || maxRetransmits as? Int == nil) {
            params["maxRetransmits"] = 0
        }

        if (maxPacketLifeTime != nil && maxRetransmits != nil) {
            return MSError(type: .device, message: "cannot provide both maxPacketLifeTime and maxRetransmits")
        }

        // clang-format off
        if (orderedGiven &&
            params["ordered"] as! Bool == true &&
            (maxPacketLifeTime != nil || maxRetransmits != nil)) {
            return MSError(type: .device, message: "cannot be ordered with maxPacketLifeTime or maxRetransmits")
        }
        else if (!orderedGiven && (maxPacketLifeTime != nil || maxRetransmits != nil)) {
            params["ordered"] = false;
        }

        // priority is optional. If unset set it to empty string.
        if (priority == nil || priority as? String == nil) {
            params["priority"] = "";
        }

        // label is optional. If unset set it to empty string.
        if (label == nil || label as? String == nil) {
            params["label"] = "";
        }

        // protocol is optional. If unset set it to empty string.
        if (sctpProtocol == nil || sctpProtocol as? String == nil) {
            params["protocol"] = "";
        }
        
        return nil
    }

    /**
    * Validates IceParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateIceParameters(_ params: inout MSJson) -> MSError? {
        let usernameFragment   = params["usernameFragment"]
        let password           = params["password"]
        let iceLite            = params["iceLite"]

        // usernameFragment is mandatory.
        if (usernameFragment == nil ||
            usernameFragment as? String == nil ||
                (usernameFragment as? String)?.isEmpty ?? false
        ) {
            return MSError(type: .device, message: "missing params.usernameFragment")
        }

        // userFragment is mandatory.
        if (password == nil || password as? String == nil || (password as? String)?.isEmpty ?? false ) {
            return MSError(type: .device, message: "missing params.password")
        }

        // iceLIte is optional. If unset set it to false.
        if (iceLite == nil || iceLite as? Bool == nil) {
            params["iceLite"] = false
        }
        
        return nil
    }

    /**
    * Validates IceCandidate. It may modify given data by adding missing
    * fields with default values.
    */
    func validateIceCandidate(_ params: MSJson) -> MSJson? {
        let modifiedParams = params
        
        let protocolRegex = "(udp|tcp)"
        let typeRegex = "(host|srflx|prflx|relay)"

        let foundation = params["foundation"]
        let priority   = params["priority"]
        let ip         = params["ip"]
        let iceProtocol   = params["protocol"]
        let port       = params["port"]
        let type       = params["type"]

        // foundation is mandatory.
        if (foundation == nil || (foundation as? String == nil || (foundation as? String)?.isEmpty ?? false)) {
            latestError = MSError(type: .device, message: "missing params.foundation")
            return nil
        }

        // priority is mandatory.
        if (priority == nil || priority as? Int == nil) {
            latestError = MSError(type: .device, message: "missing params.priority")
            return nil
        }

        // ip is mandatory.
        if (ip == nil || (ip as? String == nil || (ip as? String)?.isEmpty ?? false)) {
            latestError =  MSError(type: .device, message: "missing params.ip")
            return nil
        }

        // protocol is mandatory.
        if (iceProtocol == nil || (iceProtocol as? String == nil || (iceProtocol as? String)?.isEmpty ?? false)) {
            latestError = MSError(type: .device, message: "missing params.protocol")
            return nil
        }
        
        let protocolMatches = (iceProtocol as! String).matches(protocolRegex)

        if (protocolMatches.isEmpty) {
            latestError = MSError(type: .device, message: "invalid params.protocol")
            return nil
        }

        // port is mandatory.
        if (port == nil || port as? Int == nil) {
            latestError = MSError(type: .device, message: "missing params.port")
            return nil
        }

        // type is mandatory.
        if (type == nil || (type as? String == nil || (type as? String)?.isEmpty ?? false )) {
            latestError = MSError(type: .device, message: "missing params.type")
            return nil
        }

        let typeMatches = (type as! String).matches(typeRegex)
            
        if (typeMatches.isEmpty) {
            latestError = MSError(type: .device, message: "invalid params.type")
            return nil
        }
    
        return modifiedParams
    }

    /**
    * Validates IceCandidates. It may modify given data by adding missing
    * fields with default values.
    */
    func validateIceCandidates(_ params: inout MSJsonArray) -> MSError? {
        for (index, iceCandidate) in params.enumerated() {
            if let validatedCandidate = validateIceCandidate(iceCandidate) {
                params[index] = validatedCandidate
            }
            else {
                return latestError
            }
        }
        
        return nil
    }

    /**
    * Validates DtlsFingerprint. It may modify given data by adding missing
    * fields with default values.
    */
    func validateDtlsFingerprint(_ params: inout MSJson) -> MSJson? {
        let modifiedParams = params
        
        let algorithm = params["algorithm"]
        let value     = params["value"]

        // foundation is mandatory.
        if ( algorithm == nil || (algorithm as? String == nil || (algorithm as? String)?.isEmpty ?? false )) {
            latestError = MSError(type: .device, message: "missing params.algorithm")
            return nil
        }

        // foundation is mandatory.
        if (value == nil || (value as? String == nil || (value as? String)?.isEmpty ?? false)) {
            latestError = MSError(type: .device, message: "missing params.value")
            return nil
        }
        
        return modifiedParams
    }

    /**
    * Validates DtlsParameters. It may modify given data by adding missing
    * fields with default values.
    */
    func validateDtlsParameters(_ params: inout MSJson) -> MSError? {
        let roleRegex = "(auto|client|server)"
        let role         = params["role"]
        let fingerprints = params["fingerprints"]
        
        // role is mandatory.
        if (role == nil || (role as? String == nil || (role as? String)?.isEmpty ?? false)) {
            return MSError(type: .device, message: "missing params.role")
        }
        
        let roleMatches = (role as! String).matches(roleRegex)
        if (roleMatches.isEmpty) {
            return MSError(type: .device, message: "invalid params.role")
        }

        // fingerprints is mandatory.
        if (fingerprints == nil || (fingerprints as? [Any] == nil || (fingerprints as? [Any])?.isEmpty ?? false )) {
            return MSError(type: .device, message: "missing params.fingerprints")
        }

        var arrayOfFingerPrints = fingerprints as! MSJsonArray
        
        for (index, fingerprint) in arrayOfFingerPrints.enumerated() {
            var fingerprint = fingerprint
            if let validatedFingerprint = validateDtlsFingerprint(&fingerprint) {
                arrayOfFingerPrints[index] = validatedFingerprint
            }
            else {
                return latestError
            }
        }
        
        params["fingerprints"] = arrayOfFingerPrints
        
        return nil
    }

    
    /**
    * Validates Producer codec options. It may modify given data by adding missing
    * fields with default values.
    */
    func validateProducerCodecOptions(_ params: MSJson) -> MSError? {
        let opusStereo              = params["opusStereo"]
        let opusFec                 = params["opusFec"]
        let opusDtx                 = params["opusDtx"]
        let opusMaxPlaybackRate     = params["opusMaxPlaybackRate"]
        let opusPtime               = params["opusPtime"]
        let videoGoogleStartBitrate = params["videoGoogleStartBitrate"]
        let videoGoogleMaxBitrate   = params["videoGoogleMaxBitrate"]
        let videoGoogleMinBitrate   = params["videoGoogleMinBitrate"]

        if (opusStereo != nil && opusStereo as? Bool == nil){
            return MSError(type: .producer, message: "invalid params.opusStereo")
        }

        if (opusFec != nil && opusFec as? Bool == nil) {
            return MSError(type: .producer, message: "invalid params.opusFec")
        }

        if (opusDtx != nil && opusDtx as? Bool == nil) {
            return MSError(type: .producer, message: "invalid params.opusDtx")
        }

        if (opusMaxPlaybackRate != nil && opusMaxPlaybackRate as? Int == nil) {
            return MSError(type: .producer, message: "invalid params.opusMaxPlaybackRate")
        }

        if (opusPtime != nil && opusPtime as? Int == nil){
            return MSError(type: .producer, message: "invalid params.opusPtime")
        }

        if (videoGoogleStartBitrate != nil && videoGoogleStartBitrate as? Int == nil){
            return MSError(type: .producer, message: "invalid params.videoGoogleStartBitrate")
        }

        if (videoGoogleMaxBitrate != nil && videoGoogleMaxBitrate as? Int == nil){
            return MSError(type: .producer, message: "invalid params.videoGoogleMaxBitrate")
        }

        if (videoGoogleMinBitrate != nil && videoGoogleMinBitrate as? Int == nil) {
            return MSError(type: .producer, message: "invalid params.videoGoogleMinBitrate")
        }
        
        return nil
    }
    
    func getExtendedRtpCapabilities(_ localCaps: MSJson, _ remoteCaps: MSJson) -> MSJson? {
        
        /*So we are able to mutate them inside validateRtpCapabilities()*/
        var localCaps = localCaps
        var remoteCaps = remoteCaps
        
        if let error = validateRtpCapabilities(&localCaps) {
            latestError = error
            return nil
        }
        if let error = validateRtpCapabilities(&remoteCaps) {
            latestError = error
            return nil
        }
        
        var extendedRtpCapabilities: MSJson = [
            "codecs": MSJsonArray(),
            "headerExtensions": MSJsonArray()
        ]
        
        // Match media codecs and keep the order preferred by remoteCaps.
        let remoteCapsCodec = remoteCaps["codecs"] as! MSJsonArray
        for remoteCodec in remoteCapsCodec {
            if MSOrtc.isRtxCodec(remoteCodec) {
                continue
            }
            
            var localCodecs = localCaps["codecs"] as! MSJsonArray
            
            var matchingLocalCodec: MSJson!
            
            for (index, localCodec) in localCodecs.enumerated() {
                let result: MSMatchCodecResult = MSOrtc.matchCodecs(localCodec, remoteCodec, true, true)
                
                if result.isEqual {
                    matchingLocalCodec = result.modifiedCodec!
                    
                    localCodecs[index] = matchingLocalCodec
                    break
                }
            }
            
            if matchingLocalCodec == nil {
                continue
            }
            
            var extendedCodec: MSJson = ["mimeType": matchingLocalCodec["mimeType"] as! String,
                                         "kind": matchingLocalCodec["kind"]  as! String,
                                         "clockRate": matchingLocalCodec["clockRate"]  as! Int,
                                         "localPayloadType":  matchingLocalCodec["preferredPayloadType"]  as! Int,
                                        // "localRtxPayloadType":  nil,
                                         "remotePayloadType": remoteCodec["preferredPayloadType"]  as! Int,
                                         //"remoteRtxPayloadType": nil,
                                         "localParameters": matchingLocalCodec["parameters"]  as! MSJson,
                                         "remoteParameters": remoteCodec["parameters"]  as! MSJson,
                                         "rtcpFeedback": MSOrtc.reduceRtcpFeedback(matchingLocalCodec, remoteCodec)]
            
            if (matchingLocalCodec["channels"] != nil) {
                extendedCodec["channels"] = matchingLocalCodec["channels"]
            }
                

            var array = (extendedRtpCapabilities["codecs"] as! MSJsonArray)
            array.append(extendedCodec)
            extendedRtpCapabilities["codecs"] = array
        }
        
        // Match RTX codecs.
        var extendedCodecs = extendedRtpCapabilities["codecs"] as! MSJsonArray
        for (index, extendedCodec) in extendedCodecs.enumerated() {
            var extendedCodec = extendedCodec
            let localCodecs = localCaps["codecs"] as? MSJsonArray
            
            let localCodec = localCodecs?.first { localCodec -> Bool in
                MSOrtc.isRtxCodec(localCodec) && (localCodec["parameters"] as! MSJson)["apt"] as? String == extendedCodec["localPayloadType"] as? String
            }
            
            if (localCodec == nil) {
                continue
            }
            
            let matchingLocalRtxCodec = localCodec!
            let remoteCodecs = remoteCaps["codecs"] as? MSJsonArray
            
            let remoteCodec = remoteCodecs?.first { remoteCodec -> Bool in
                MSOrtc.isRtxCodec(remoteCodec) && (remoteCodec["parameters"] as! MSJson)["apt"] as? String == extendedCodec["localPayloadType"] as? String
            }
            
            if remoteCodec == nil {
                continue
            }
            
            let matchingRemoteRtxCodec = remoteCodec!
            extendedCodec["localRtxPayloadType"]  = matchingLocalRtxCodec["preferredPayloadType"]
            extendedCodec["remoteRtxPayloadType"] = matchingRemoteRtxCodec["preferredPayloadType"]
            
            extendedCodecs[index] = extendedCodec
        }
        extendedRtpCapabilities["codecs"] = extendedCodecs
        
        // Match header extensions.
        let remoteExts = remoteCaps["headerExtensions"] as! MSJsonArray
        
        for remoteExt in remoteExts {
            
            let localExts = localCaps["headerExtensions"] as? MSJsonArray
            
            let localExt = localExts?.first { localExt -> Bool in
                return MSOrtc.matchHeaderExtensions(localExt, remoteExt)
            }
           
            if localExt == nil {
                continue
            }
            
            let matchingLocalExt = localExt!

            // TODO: Must do stuff for encrypted extensions.

            // clang-format off
            var extendedExt: MSJson = [
                "kind": remoteExt["kind"] as! String,
                "uri": remoteExt["uri"] as! String,
                "sendId":  matchingLocalExt["preferredId"] as! Int,
                "recvId":  remoteExt["preferredId"] as! Int,
                "encrypt": matchingLocalExt["preferredEncrypt"] as! Bool
            ]
            
            let remoteExtDirection = remoteExt["direction"] as! String

            if (remoteExtDirection == "sendrecv") {
                extendedExt["direction"] = "sendrecv"
            }
            else if (remoteExtDirection == "recvonly") {
                extendedExt["direction"] = "sendonly"
            }
            else if (remoteExtDirection == "sendonly") {
                extendedExt["direction"] = "recvonly"
            }
            else if (remoteExtDirection == "inactive") {
                extendedExt["direction"] = "inactive"
            }

            var array = (extendedRtpCapabilities["headerExtensions"] as! MSJsonArray)
            array.append(extendedExt)
            extendedRtpCapabilities["headerExtensions"] = array
            
        }
        
        return extendedRtpCapabilities;
    }
    
    func getRecvRtpCapabilities(_ extendedRtpCapabilities: MSJson) -> MSJson {
        var rtpCapabilities: MSJson = ["codecs": MSJsonArray(),
                                       "headerExtensions": MSJsonArray()]
        
        let extendedCodecs = extendedRtpCapabilities["codecs"] as! MSJsonArray
        for extendedCodec in extendedCodecs {
            
            var codec: MSJson =
                [ "mimeType": extendedCodec["mimeType"] as! String,
                  "kind": extendedCodec["kind"] as! String,
                  "preferredPayloadType": extendedCodec["remotePayloadType"] as! Int,
                  "clockRate": extendedCodec["clockRate"] as! Int,
                  "parameters": extendedCodec["localParameters"] as! MSJson,
                  "rtcpFeedback": extendedCodec["rtcpFeedback"] as! MSJsonArray
                ]
            
            if (extendedCodec["channels"] != nil) {
                codec["channels"] = extendedCodec["channels"]
            }
                
            var codecs = rtpCapabilities["codecs"] as! MSJsonArray
            codecs.append(codec)
            rtpCapabilities["codecs"] = codecs

            // Add RTX codec.
            if (extendedCodec["remoteRtxPayloadType"] == nil) {
                continue
            }

            let mimeType = (extendedCodec["kind"] as! String) + "/rtx"
            
            // clang-format off
            let rtxCodec: MSJson = [
                "mimeType": mimeType,
                "kind": extendedCodec["kind"] as! String,
                "preferredPayloadType": extendedCodec["remoteRtxPayloadType"] as! Int,
                "clockRate": extendedCodec["clockRate"] as! Int,
                "parameters":
                    [
                        "apt": extendedCodec["remotePayloadType"] as! Int
                    ],
                "rtcpFeedback": MSJsonArray()
            ]
            // clang-format on

            var rtpCodecs = rtpCapabilities["codecs"] as! MSJsonArray
            rtpCodecs.append(rtxCodec)
            rtpCapabilities["codecs"] = rtpCodecs
        }
        
        for extendedExtension in extendedRtpCapabilities["headerExtensions"] as! MSJsonArray {
            let direction = extendedExtension["direction"] as! String

            // Ignore RTP extensions not valid for receiving.
            if (direction != "sendrecv" && direction != "recvonly") {
                continue
            }

            let ext = [
                "kind": extendedExtension["kind"],
                "uri": extendedExtension["uri"],
                "preferredId": extendedExtension["recvId"],
                "preferredEncrypt": extendedExtension["encrypt"],
                "direction": extendedExtension["direction"]
            ]

            var headerExtensions = rtpCapabilities["headerExtensions"] as! MSJsonArray
            headerExtensions.append(ext as MSJson)
            rtpCapabilities["headerExtensions"] = headerExtensions
            
        }
        
        return rtpCapabilities
    }
    
    /**
    * Generate RTP parameters of the given kind for sending media.
    * Just the first media codec per kind is considered.
    * NOTE: mid, encodings and rtcp fields are left empty.
    */
    func getSendingRtpParameters(_ kind: String, _ extendedRtpCapabilities: MSJson) -> MSJson {
        var rtpParameters: MSJson = [
            //"mid": nil,
            "codecs": MSJsonArray(),
            "headerExtensions": MSJsonArray(),
            "encodings": MSJsonArray(),
            "rtcp": MSJson()
        ]
        
        for extendedCodec in extendedRtpCapabilities["codecs"] as! MSJsonArray {
            if (kind != extendedCodec["kind"] as? String) {
                continue
            }
                
            var codec: MSJson =
            [
                "mimeType":     extendedCodec["mimeType"] as! String,
                "payloadType":  extendedCodec["localPayloadType"] as! Int,
                "clockRate":    extendedCodec["clockRate"] as! Int,
                "parameters":   extendedCodec["localParameters"] as! MSJson,
                "rtcpFeedback": extendedCodec["rtcpFeedback"] as! MSJsonArray
            ]


            if (extendedCodec["channels"] != nil) {
                codec["channels"] = extendedCodec["channels"]
            }
                

            var array = rtpParameters["codecs"] as! MSJsonArray
            array.append(codec)
            rtpParameters["codecs"] = array

            // Add RTX codec.
            if (extendedCodec["localRtxPayloadType"] != nil) {
                let mimeType = extendedCodec["kind"] as! String + "/rtx"


                let rtxCodec: MSJson = [
                    "mimeType": mimeType,
                    "payloadType": extendedCodec["localRtxPayloadType"] as! Int,
                    "clockRate":   extendedCodec["clockRate"] as! Int,
                    "parameters": ["apt": extendedCodec["localPayloadType"] as! Int],
                    "rtcpFeedback": MSJsonArray()
                ]

                var array = rtpParameters["codecs"] as! MSJsonArray
                array.append(rtxCodec)
                rtpParameters["codecs"] = array
            }

            // NOTE: We assume a single media codec plus an optional RTX codec.
            break
        }

        for extendedExtension in extendedRtpCapabilities["headerExtensions"] as! MSJsonArray {
            if (kind != extendedExtension["kind"] as? String) {
                continue
            }

            let direction = extendedExtension["direction"] as! String

            // Ignore RTP extensions not valid for sending.
            if (direction != "sendrecv" && direction != "sendonly") {
                continue
            }

            let ext = [
                "uri": extendedExtension["uri"],
                "id": extendedExtension["sendId"],
                "encrypt": extendedExtension["encrypt"],
                "parameters": MSJson()
            ]

            var array = rtpParameters["headerExtensions"] as! MSJsonArray
            array.append(ext as MSJson)
            rtpParameters["headerExtensions"] = array
        }

        return rtpParameters
    }
    
    /**
    * Generate RTP parameters of the given kind for sending media.
    */
    func getSendingRemoteRtpParameters(_ kind: String, _ extendedRtpCapabilities: MSJson) -> MSJson {
        var rtpParameters: MSJson = [
            //"mid", nullptr,
            "codecs": MSJsonArray(),
            "headerExtensions": MSJsonArray(),
            "encodings": MSJsonArray(),
            "rtcp": MSJson()
        ]
 

        for extendedCodec in extendedRtpCapabilities["codecs"] as! MSJsonArray {
            if (kind != extendedCodec["kind"] as? String) {
                continue
            }


            var codec: [String:Any] = [
                "mimeType":  extendedCodec["mimeType"] as! String,
                "payloadType": extendedCodec["localPayloadType"] as! Int,
                "clockRate": extendedCodec["clockRate"] as! Int,
                "parameters": extendedCodec["remoteParameters"] as! MSJson,
                "rtcpFeedback": extendedCodec["rtcpFeedback"] as! MSJsonArray
            ]

            if (extendedCodec["channels"] != nil) {
                codec["channels"] = extendedCodec["channels"]
            }

            var array = rtpParameters["codecs"] as! MSJsonArray
            array.append(codec)
            rtpParameters["codecs"] = array

            // Add RTX codec.
            if (extendedCodec["localRtxPayloadType"] != nil) {
                let mimeType = extendedCodec["kind"] as! String + "/rtx"

                // clang-format off
                let rtxCodec = [
                    "mimeType":    mimeType,
                    "payloadType": extendedCodec["localRtxPayloadType"],
                    "clockRate":   extendedCodec["clockRate"],
                            
                    "parameters": [ "apt", extendedCodec["localPayloadType"] as! Int ],
                    "rtcpFeedback": MSJsonArray()
                ]
                // clang-format on

                var array = rtpParameters["codecs"] as! MSJsonArray
                array.append(rtxCodec as MSJson)
                rtpParameters["codecs"] = array
            }

            // NOTE: We assume a single media codec plus an optional RTX codec.
            break
        }

        for extendedExtension in extendedRtpCapabilities["headerExtensions"] as! MSJsonArray {
            if (kind != extendedExtension["kind"] as? String) {
                continue
            }

            let direction = extendedExtension["direction"] as! String

            // Ignore RTP extensions not valid for sending.
            if (direction != "sendrecv" && direction != "sendonly") {
                continue
            }

            let ext: [String:Any] = [
                "uri": extendedExtension["uri"] as! String,
                "id": extendedExtension["sendId"] as! Int,
                "encrypt": extendedExtension["encrypt"] as! Bool,
                "parameters": MSJson()
            ]
            
            // clang-format on

            var array = rtpParameters["headerExtensions"] as! MSJsonArray
            array.append(ext)
            rtpParameters["headerExtensions"] = array
        }

        let headerExtensions = rtpParameters["headerExtensions"] as? MSJsonArray

        // Reduce codecs' RTCP feedback. Use Transport-CC if available, REMB otherwise.
        var headerExtension = headerExtensions?.first {  ext -> Bool in
            return ext["uri"] as? String == "http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01"
        }

        if (headerExtension != nil) {
            var codecsArray = rtpParameters["codecs"] as! MSJsonArray
            for (index, codec) in codecsArray.enumerated() {
                        
                var rtcpFeedbackArray = codec["rtcpFeedback"] as! MSJsonArray
                for (index, fb) in rtcpFeedbackArray.enumerated() {
                    let type = fb["type"] as! String
                            
                    if type == "goog-remb" {
                        rtcpFeedbackArray.remove(at: index)
                    }
                }
                        
                var codec = codecsArray[index]
                codec["rtcpFeedback"] = rtcpFeedbackArray
                codecsArray[index] = codec
            }
        
            rtpParameters["codecs"] = codecsArray
            return rtpParameters
        }

        headerExtension = headerExtensions?.first { ext -> Bool in
            return ext["uri"] as? String == "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time"
        }

        if (headerExtension != nil) {
            var codecsArray = rtpParameters["codecs"] as! MSJsonArray
            for (index, codec) in codecsArray.enumerated() {
                        
                var rtcpFeedbackArray = codec["rtcpFeedback"] as! MSJsonArray
                for (index, fb) in rtcpFeedbackArray.enumerated() {
                    let type = fb["type"] as! String
                            
                    if type == "transport-cc" {
                        rtcpFeedbackArray.remove(at: index)
                    }
                }
                        
                var codec = codecsArray[index]
                codec["rtcpFeedback"] = rtcpFeedbackArray
                codecsArray[index] = codec
                        
            }

            return rtpParameters;
        }

        var codecsArray = rtpParameters["codecs"] as! MSJsonArray
        for (index, codec) in codecsArray.enumerated() {

            var rtcpFeedbackArray = codec["rtcpFeedback"] as! MSJsonArray
            for (index, fb) in rtcpFeedbackArray.enumerated() {
                let type = fb["type"] as! String
                        
                if type == "transport-cc" || type == "goog-remb" {
                    rtcpFeedbackArray.remove(at: index)
                }
            }
                    
            var codec = codecsArray[index]
            codec["rtcpFeedback"] = rtcpFeedbackArray
            codecsArray[index] = codec
        }

        return rtpParameters
    }
    
    /**
     * Create RTP parameters for a Consumer for the RTP probator.
     */
    func generateProbatorRtpParameters(_ videoRtpParameters: MSJson) -> MSJson? {

        // This may throw.
        var validatedRtpParameters = videoRtpParameters

        // This may throw.
        if validateRtpParameters(&validatedRtpParameters) != nil {
            return nil
        }
        
        var rtpParameters: MSJson = ["mid": probatorMid,
                                     "codecs": MSJsonArray(),
                                     "headerExtensions": MSJsonArray(),
                                     "encodings": MSJsonArray(),
                                     "rtcp": ["cname": "probator"]]
        
        let validatedRtpParametersCodecs = validatedRtpParameters["codecs"] as! MSJsonArray
        let rtpParametersCodecs: MSJsonArray = [validatedRtpParametersCodecs[0]]
        rtpParameters["codecs"] = rtpParametersCodecs
        
        var arrayOfRtpParametersHeadersExtensions = MSJsonArray()
        for ext in validatedRtpParameters["headerExtensions"] as! MSJsonArray {
            if ext["uri"] as! String == "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time" ||
               ext["uri"] as! String == "http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01" {
                
                arrayOfRtpParametersHeadersExtensions.append(ext)
            }
        }
        
        rtpParameters["headerExtensions"] = arrayOfRtpParametersHeadersExtensions
       
        var encoding = MSJson()
        encoding["ssrc"] = probatorSsrc

        let arrayOfRtpParametersEncodings = [encoding]
        rtpParameters["encodings"] = arrayOfRtpParametersEncodings

        return rtpParameters
        
    }
    
    /**
    * Whether media can be sent based on the given RTP capabilities.
    */
    func canSend(_ kind: String, _ extendedRtpCapabilities: MSJson) -> Bool {

        let codecs = extendedRtpCapabilities["codecs"] as? MSJsonArray
        let codec = codecs?.first { codec -> Bool in
            kind == codec["kind"] as? String
        }
                
       return codec != nil
    }
    
    /**
     * Whether the given RTP parameters can be received with the given RTP
     * capabilities.
     */
    func canReceive(_ rtpParameters: inout MSJson, _ extendedRtpCapabilities: MSJson) -> Bool {
    
        // This may throw.
        let _ = validateRtpParameters(&rtpParameters);

        if ((rtpParameters["codecs"] as! MSJsonArray).isEmpty) {
            return false
        }

        let arrayOfCodecs = rtpParameters["codecs"] as! MSJsonArray
        
        let firstMediaCodec = arrayOfCodecs[0]
        let codecs = extendedRtpCapabilities["codecs"] as! MSJsonArray
        
        let codec = codecs.first { codec -> Bool in
            codec["remotePayloadType"] as! Int == firstMediaCodec["payloadType"] as! Int
        }
        
        return codec != nil
    }
    
    static func isRtxCodec(_ codec: MSJson) -> Bool {

        let regex = "^(audio|video)/rtx$"
        let mimeType = codec["mimeType"] as! String

        return mimeType.range(of: regex, options: .regularExpression) != nil
    }
    
    static func matchCodecs(_ aCodec: MSJson, _ bCodec: MSJson, _ strict: Bool, _ modify: Bool) -> MSMatchCodecResult {
        var modififedCodec = aCodec
        let aMimeType = (aCodec["mimeType"] as! String).lowercased()
        let bMimeType = (bCodec["mimeType"] as! String).lowercased()
        
        if aMimeType != bMimeType {
            return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
        }
        
        if aCodec["clockRate"] as! Int != bCodec["clockRate"] as! Int {
            return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
        }
        
        if (aCodec["clockRate"] != nil) != (bCodec["clockRate"] != nil) {
            return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
        }
        
        if (aCodec["channels"] != nil) && (aCodec["channels"] as! Int != bCodec["channels"] as! Int) {
            return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
        }
        
        if aMimeType == "video/h264" {
            let aPacketizationMode = MSOrtc.getH264PacketizationMode(aCodec)
            let bPacketizationMode = MSOrtc.getH264PacketizationMode(bCodec)

            if (aPacketizationMode != bPacketizationMode) {
                return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
            }
            
            if strict {
                var aParameters: CodecParameterMap = CodecParameterMap()
                var bParameters: CodecParameterMap = CodecParameterMap()

                aParameters["level-asymmetry-allowed"] = String(MSOrtc.getH264LevelAssimetryAllowed(aCodec))
                aParameters["packetization-mode"]      = String(aPacketizationMode)
                aParameters["profile-level-id"]        = MSOrtc.getH264ProfileLevelId(aCodec)
                bParameters["level-asymmetry-allowed"] = String(MSOrtc.getH264LevelAssimetryAllowed(bCodec))
                bParameters["packetization-mode"]      = String(bPacketizationMode)
                bParameters["profile-level-id"]        = MSOrtc.getH264ProfileLevelId(bCodec)
                
                if !H264.isSameH264Profile(aParameters, bParameters) {
                    return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
                }
                
                if let newParameters = H264.generateProfileLevelIdForAnswer(aParameters, bParameters) {
                    if (modify) {
                        let profileLevelId = newParameters["profile-level-id"]

                        if (profileLevelId != nil) {
                            var dict = modififedCodec["parameters"] as! MSJson
                            dict["profile-level-id"] = profileLevelId
                            modififedCodec["parameters"] = dict
                        }
                        else {
                            modififedCodec["parameters"] = nil
                        }
                    }
                }
                else {
                    return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
                }
            }
        }
        // Match VP9 parameters.
        else if (aMimeType == "video/vp9"){
            // If strict matching check profile-id.
            if (strict) {
                let aProfileId = MSOrtc.getVP9ProfileId(aCodec);
                let bProfileId = MSOrtc.getVP9ProfileId(bCodec);

                if (aProfileId != bProfileId) {
                    return MSMatchCodecResult(modifiedCodec: nil, isEqual: false)
                }
            }
        }
        
        return MSMatchCodecResult(modifiedCodec: modififedCodec, isEqual: true)
    }
    
    static func getH264PacketizationMode(_ codec: MSJson) -> Int {
        let parameters = codec["parameters"] as! MSJson
        let packetizationMode = parameters["packetization-mode"]

        if (packetizationMode == nil || packetizationMode as? Int == nil) {
            return 0
        }

        return packetizationMode as! Int
    }
    
    static func getH264LevelAssimetryAllowed(_ codec: MSJson) -> Int {
        let parameters = codec["parameters"] as! MSJson
        let levelAssimetryAllowedIt = parameters["level-asymmetry-allowed"]

        // clang-format off
        if (levelAssimetryAllowedIt == nil || levelAssimetryAllowedIt as? Int == nil) {
            return 0
        }

        return levelAssimetryAllowedIt as! Int
    }
    
    static func getH264ProfileLevelId(_ codec: MSJson) -> String {
        let parameters = codec["parameters"] as! MSJson
        let profileLevelId = parameters["profile-level-id"]

        if (profileLevelId == nil) {
            return ""
        }
        else if (profileLevelId as? Int != nil) {
            return String(profileLevelId as! Int)
        }
            
        return profileLevelId as! String
    }
    
    static func getVP9ProfileId(_ codec: MSJson) -> String{
        let parameters = codec["parameters"] as! MSJson
        let profileId = parameters["profile-id"]

        if (profileId == nil) {
            return "0"
        }

        if (profileId as? Int != nil) {
            return String(profileId as! Int)
        }
        
        return profileId as! String
    }
    
    static func matchHeaderExtensions(_ aExt: MSJson, _ bExt: MSJson) -> Bool {
       
        if (aExt["kind"] as? String != bExt["kind"] as? String) {
            return false
        }
            
        return aExt["uri"] as? String == bExt["uri"] as? String
    }
    
    static func reduceRtcpFeedback(_ codecA: MSJson, _ codecB: MSJson) -> MSJsonArray {
        var reducedRtcpFeedback = MSJsonArray()
        let rtcpFeedbackA = codecA["rtcpFeedback"] as! MSJsonArray
        let rtcpFeedbackB = codecB["rtcpFeedback"] as! MSJsonArray

        for aFb in rtcpFeedbackA {
            let rtcpFeedback = rtcpFeedbackB.first { bFb -> Bool in
                return (aFb["type"] as? String == bFb["type"] as? String && aFb["parameter"] as? String == bFb["parameter"] as? String)
            }
            
            if (rtcpFeedback != nil) {
                reducedRtcpFeedback.append(rtcpFeedback!)
            }
        }

        return reducedRtcpFeedback
    }
    
    func getError() -> MSError {
        return latestError
    }

}

/* Helper class to get the modified codec as a result*/
struct MSMatchCodecResult {
    var modifiedCodec: MSJson?
    var isEqual: Bool
}
