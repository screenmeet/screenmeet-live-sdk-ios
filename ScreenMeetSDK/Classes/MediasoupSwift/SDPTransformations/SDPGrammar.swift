//
//  SDPGrammar.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit

class SDPGrammar: NSObject {
    private static var _rules: [String: [SDPRule]]!
    
    static var rules: [String: [SDPRule]] {
        if _rules == nil {
            setupGrammarRules()
        }
        return _rules
    }
    
    private static func setupGrammarRules() {
        _rules = [String: [SDPRule]]()
        
        _rules["v"] = [SDPRule(name: "version",
                               push: "",
                               reg: "^(\\d*)$",
                               names: [String](),
                               types: ["d"],
                               format: "%d",
                               formatFunc: nil)]
        
        _rules["o"] = [SDPRule(name: "origin",
                               push: "",
                               reg: "^(\\S*) (\\d*) (\\d*) (\\S*) IP(\\d) (\\S*)",
                               names: ["username", "sessionId", "sessionVersion", "netType", "ipVer", "address"],
                               types: ["s", "s", "d", "s", "d", "s"],
                               format: "%s %s %d %s IP%d %s",
                               formatFunc: nil)]
        
        _rules["s"] = [SDPRule(name: "name",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["i"] = [SDPRule(name: "description",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["u"] = [SDPRule(name: "uri",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["e"] = [SDPRule(name: "email",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["p"] = [SDPRule(name: "phone",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["z"] = [SDPRule(name: "timezones",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        _rules["r"] = [SDPRule(name: "repeats",
                               push: "",
                               reg: "(.*)",
                               names: [String](),
                               types: ["s"],
                               format: "%s",
                               formatFunc: nil)]
        
        // t=0 0
        _rules["t"] = [SDPRule(name: "timing",
                               push: "",
                               reg: "^(\\d*) (\\d*)",
                               names: ["start", "stop"],
                               types: ["d", "d"],
                               format: "%d %d",
                               formatFunc: nil)]
        
        // c=IN IP4 10.47.197.26
        _rules["c"] = [SDPRule(name: "connection",
                               push: "",
                               reg: "^IN IP(\\d) ([^\\\\S]*)(?:(\\d*))?",
                               names: ["version", "ip" , "ttl"],
                               types: ["d", "s", "d"],
                               format: "",
                               formatFunc: { o -> String in
                                    return o["ttl"] != nil ? "IN IP%d %s/%d" : "IN IP%d %s"
                               })]
        
        // b=AS:4000
        _rules["b"] = [SDPRule(name: "bandwidth",
                               push: "",
                               reg: "^(TIAS|AS|CT|RR|RS):(\\d*)",
                               names: ["type", "limit"],
                               types: ["s", "d"],
                               format: "%s:%d",
                               formatFunc: nil)]
        
        // m=video 51744 RTP/AVP 126 97 98 34 31
        _rules["m"] = [SDPRule(name: "",
                               push: "",
                               reg: "^(\\w*) (\\d*)(?:/(\\d*))? ([\\w\\/]*)(?: (.*))?",
                               names: ["type", "port", "numPorts", "protocol", "payloads"],
                               types: ["s", "d", "d", "s", "s"],
                               format: "",
                               formatFunc: { o -> String in
                                    return o["numPorts"] != nil ? "%s %d/%d %s %s" : "%s %d%v %s %s"
                               })]
        
        // a=rtpmap:110 opus/48000/2
        _rules["a"] = [SDPRule(name: "",
                               push: "rtp",
                               reg: "^rtpmap:(\\d*) ([\\w\\-\\.]*)(?:\\s*\\/(\\d*)(?:\\s*\\/(\\S*))?)?",
                               names: ["payload", "codec", "rate", "encoding"],
                               types: ["d", "s", "d", "s" ],
                               format: "",
                               formatFunc: { o -> String in
                                
                                if (o["codec"] as? String == "opus") {
                                    //NSLog("Opus")
                                }
                                    return o["encoding"] != nil ? "rtpmap:%d %s/%s/%s" : o["rate"] != nil ? "rtpmap:%d %s/%s" : "rtpmap:%d %s"
                               }),
                       
                       // a=fmtp:108 profile-level-id=24;object=23;bitrate=64000
                       // a=fmtp:111 minptime=10; useinbandfec=1
                       SDPRule(name: "",
                               push: "fmtp",
                               reg: "^fmtp:(\\d*) (.*)",
                               names: ["payload", "config"],
                               types: ["d", "s"],
                               format: "fmtp:%d %s",
                               formatFunc: nil),
        
                        // a=control:streamid=0
                        SDPRule(name: "control",
                                push: "",
                                reg: "^control:(.*)",
                                names: [],
                                types: [ "s"],
                                format: "control:%s",
                                formatFunc: nil),
                        
                        // a=rtcp:65179 IN IP4 193.84.77.194
                        SDPRule(name: "",
                                push: "rtcp",
                                reg: "^rtcp:(\\d*)(?: (\\S*) IP(\\d) (\\S*))?",
                                names: ["port", "netType", "ipVer", "address"],
                                types: ["d", "s", "d", "s" ],
                                format: "",
                                formatFunc: { o -> String in
                                    return o["address"] != nil ? "rtcp:%d %s IP%d %s" : "rtcp:%d"
                                }),
                        
                        // a=rtcp-fb:98 trr-int 100
                        SDPRule(name: "",
                                push: "rtcpFbTrrInt",
                                reg: "^rtcp-fb:(\\*|\\d*) trr-int (\\d*)",
                                names: ["payload", "value"],
                                types: [ "s", "d"],
                                format:  "rtcp-fb:%s trr-int %d",
                                formatFunc: nil),
                        
                        // a=rtcp-fb:98 nack rpsi
                        SDPRule(name: "",
                                push: "rtcpFb",
                                reg: "^rtcp-fb:(\\*|\\d*) ([\\w\\-_]*)(?: ([\\w\\-_]*))?",
                                names: ["payload", "type", "subtype"],
                                types: [ "s", "s", "s"],
                                format:  "",
                                formatFunc: { o -> String in
                                    return o["subtype"] != nil ? "rtcp-fb:%s %s %s" : "rtcp-fb:%s %s"
                                }),
                        
                        // a=extmap:2 urn:ietf:params:rtp-hdrext:toffset
                        // a=extmap:1/recvonly URI-gps-string
                        // a=extmap:3 urn:ietf:params:rtp-hdrext:encrypt urn:ietf:params:rtp-hdrext:smpte-tc 25@600/24
                        SDPRule(name: "",
                                push: "ext",
                                reg: "^extmap:(\\d+)(?://(\\w+))?(?: (urn:ietf:params:rtp-hdrext:encrypt))? (\\S*)(?: (\\S*))?",
                                names: ["value", "direction", "encrypt-uri", "uri", "config"],
                                types: [ "d", "s", "s", "s", "s"],
                                format:  "",
                                formatFunc: { o -> String in
                                    
                                    "extmap:%d" +
                                        (o["direction"] != nil ? "/%s" : "%v") +
                                        (o["encrypt-uri"] != nil ? " %s" : "%v") +
                                        " %s" +
                                        (o["config"] != nil ? " %s" : "")
                                }),
                        
                        // a=extmap-allow-mixed
                        SDPRule(name: "extmapAllowMixed",
                                push: "",
                                reg: "^(extmap-allow-mixed)",
                                names: ["payload", "type", "subtype"],
                                types: ["s"],
                                format:  "%s",
                                formatFunc: nil),
                        
                        // a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:PS1uQCVeeCFCanVmcjkpPywjNWhcYD0mXXtxaVBR|2^20|1:32
                        SDPRule(name: "",
                                push: "crypto",
                                reg: "^crypto:(\\d*) ([\\w_]*) (\\S*)(?: (\\S*))?",
                                names: ["id", "suite", "config", "sessionConfig"],
                                types: ["d", "s", "s", "s" ],
                                format: "",
                                formatFunc: { o -> String in
                                    return o["subtype"] != nil ? "crypto:%d %s %s %s" : "crypto:%d %s %s"
                                }),
                        
                        // a=setup:actpass
                        SDPRule(name: "setup",
                                push: "",
                                reg: "^setup:(\\w*)",
                                names: [],
                                types: ["s"],
                                format:  "setup:%s",
                                formatFunc: nil),
                        
                        // a=mid:1
                        SDPRule(name: "mid",
                                push: "",
                                reg: "^mid:([^\\s]*)",
                                names: [],
                                types: ["s"],
                                format: "mid:%s",
                                formatFunc: nil),
                        
                        // a=msid:0c8b064d-d807-43b4-b434-f92a889d8587 98178685-d409-46e0-8e16-7ef0db0db64a
                        SDPRule(name: "msid",
                                push: "",
                                reg: "^msid:(.*)",
                                names: [],
                                types: ["s"],
                                format: "msid:%s",
                                formatFunc: nil),
                        
                        // a=ptime:20
                        SDPRule(name: "ptime",
                                push: "",
                                reg: "^ptime:(\\d*)",
                                names: [],
                                types: ["d"],
                                format:  "ptime:%d",
                                formatFunc: nil),
                        
                        // a=maxptime:60
                        SDPRule(name: "maxptime",
                                push: "",
                                reg: "^maxptime:(\\d*)",
                                names: [],
                                types: ["d"],
                                format:  "maxptime:%d",
                                formatFunc: nil),
                        
                        // a=sendrecv
                        SDPRule(name: "direction",
                                push: "",
                                reg:  "^(sendrecv|recvonly|sendonly|inactive)",
                                names: [],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil),
                        
                        // a=ice-lite
                        SDPRule(name: "icelite",
                                push: "",
                                reg: "^(ice-lite)",
                                names: [],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil),
                        
                        // a=ice-ufrag:F7gI
                        SDPRule(name: "iceUfrag",
                                push: "",
                                reg: "^ice-ufrag:(\\S*)",
                                names: [],
                                types: ["s"],
                                format:"ice-ufrag:%s",
                                formatFunc: nil),
                        
                        // a=ice-pwd:x9cml/YzichV2+XlhiMu8g
                        SDPRule(name: "icePwd",
                                push: "",
                                reg: "^ice-pwd:(\\S*)",
                                names: [],
                                types: ["s"],
                                format:"ice-pwd:%s",
                                formatFunc: nil),
                        
                        // a=fingerprint:SHA-1 00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33
                        SDPRule(name: "fingerprint",
                                push: "",
                                reg: "^fingerprint:(\\S*) (\\S*)",
                                names: ["type", "hash"],
                                types: ["s", "s"],
                                format: "fingerprint:%s %s",
                                formatFunc: nil),
                        
                        // a=candidate:0 1 UDP 2113667327 203.0.113.1 54400 typ host
                        // a=candidate:1162875081 1 udp 2113937151 192.168.34.75 60017 typ host generation 0 network-id 3 network-cost 10
                        // a=candidate:3289912957 2 udp 1845501695 193.84.77.194 60017 typ srflx raddr 192.168.34.75 rport 60017 generation 0 network-id 3 network-cost 10
                        // a=candidate:229815620 1 tcp 1518280447 192.168.150.19 60017 typ host tcptype active generation 0 network-id 3 network-cost 10
                        // a=candidate:3289912957 2 tcp 1845501695 193.84.77.194 60017 typ srflx raddr 192.168.34.75 rport 60017 tcptype passive generation 0 network-id 3 network-cost 10
                        SDPRule(name: "",
                                push: "candidates",
                                reg: "^candidate:(\\S*) (\\d*) (\\S*) (\\d*) (\\S*) (\\d*) typ (\\S*)(?: raddr (\\S*) rport (\\d*))?(?: tcptype (\\S*))?(?: generation (\\d*))?(?: network-id (\\d*))?(?: network-cost (\\d*))?",
                                names: ["foundation", "component", "transport", "priority", "ip", "port", "type", "raddr", "rport", "tcptype", "generation", "network-id", "network-cost"],
                                types: ["s", "d", "s", "d", "s", "d", "s", "s",    "d", "s", "d", "d", "d", "d" ],
                                format: "",
                                formatFunc: { o -> String in
                                    var str = "candidate:%s %d %s %d %s %d typ %s"

                                    str = str + (o["raddr"] != nil  ? " raddr %s rport %d" : "%v%v")

                                    // NOTE: candidate has three optional chunks, so %void middles one if it's
                                    // missing.
                                    str = str + (o["tcptype"] != nil ? " tcptype %s" : "%v")

                                    if (o["generation"] != nil) {
                                        str = str + " generation %d"
                                    }

                                    str = str + (o["network-id"] != nil ? " network-id %d" : "%v")
                                    str = str + (o["network-cost"] != nil ? " network-cost %d" : "%v")

                                    return str
                                }),
                        
                        // a=end-of-candidates
                        SDPRule(name: "endOfCandidates",
                                push: "",
                                reg: "^(end-of-candidates)",
                                names: [],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil),
                        
                        // a=remote-candidates:1 203.0.113.1 54400 2 203.0.113.1 54401
                        SDPRule(name: "remoteCandidates",
                                push: "",
                                reg: "^remote-candidates:(.*)",
                                names: [],
                                types: ["s"],
                                format: "remote-candidates:%s",
                                formatFunc: nil),
                        
                        // a=ice-options:google-ice
                        SDPRule(name: "iceOptions",
                                push: "",
                                reg: "^ice-options:(\\S*)",
                                names: [],
                                types: ["s"],
                                format: "ice-options:%s",
                                formatFunc: nil),
                        
                        // a=ssrc:2566107569 cname:t9YU8M1UxTF8Y1A1
                        SDPRule(name: "",
                                push: "ssrcs",
                                reg: "^ssrc:(\\d*) ([\\w_-]*)(?::(.*))?",
                                names: ["id", "attribute", "value"],
                                types: ["d", "s", "s"],
                                format: "",
                                formatFunc: { o -> String in
                                    var str = "ssrc:%d"

                                    if (o["attribute"] != nil) {
                                        str = str + " %s"

                                        if (o["value"] != nil) {
                                            str = str + ":%s"
                                        }
                                    }

                                    return str
                                }),
                        
                        // a=ssrc-group:FEC 1 2
                        // a=ssrc-group:FEC-FR 3004364195 1080772241
                        SDPRule(name: "",
                                push: "ssrcGroups",
                                reg: "^ssrc-group:([\u{21}\u{23}\u{24}\u{25}\u{26}\u{27}\u{2A}\u{2B}\u{2D}\u{2E}\\w]*) (.*)",
                                names: ["semantics", "ssrcs"],
                                types: ["s", "s"],
                                format: "ssrc-group:%s %s",
                                formatFunc: nil),
                        
                        // a=msid-semantic: WMS Jvlam5X3SX1OP6pn20zWogvaKJz5Hjf9OnlV
                        SDPRule(name: "msidSemantic",
                                push: "",
                                reg: "^msid-semantic:\\s?(\\w*) (\\S*)",
                                names: ["semantic", "token"],
                                types: ["s", "s"],
                                format: "msid-semantic: %s %s",
                                formatFunc: nil),
                        
                        // a=group:BUNDLE audio video
                        SDPRule(name: "",
                                push: "groups",
                                reg: "^group:(\\w*) (.*)",
                                names: ["type", "mids" ],
                                types: ["s", "s"],
                                format: "group:%s %s",
                                formatFunc: nil),
                        
                        // a=rtcp-mux
                        SDPRule(name: "rtcpMux",
                                push: "",
                                reg: "^(rtcp-mux)",
                                names: [],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil),
                        
                        // a=rtcp-rsize
                        SDPRule(name: "rtcpRsize",
                                push: "",
                                reg: "^(rtcp-rsize)",
                                names: [],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil),
                        
                        // a=sctpmap:5000 webrtc-datachannel 1024
                        SDPRule(name: "sctpmap",
                                push: "",
                                reg: "^sctpmap:(\\d+) (\\S*)(?: (\\d*))?",
                                names: ["sctpmapNumber", "app", "maxMessageSize"],
                                types: ["d", "s", "d"],
                                format: "",
                                formatFunc: { o -> String in
                                    return o["maxMessageSize"] != nil ? "sctpmap:%s %s %s" : "sctpmap:%s %s"
                                }),
                        
                        // a=x-google-flag:conference
                        SDPRule(name: "xGoogleFlag",
                                push: "",
                                reg: "x-google-flag:([^\\s]*)",
                                names: [],
                                types: ["s"],
                                format: "x-google-flag:%s",
                                formatFunc: nil),
                        
                        // a=rid:1 send max-width=1280;max-height=720;max-fps=30;depend=0
                        SDPRule(name: "",
                                push: "rids",
                                reg: "^rid:([\\d\\w]+) (\\w+)(?: (.*))?",
                                names: ["id", "direction", "params"],
                                types: ["s", "s", "s"],
                                format: "",
                                formatFunc: { o -> String in
                                    return o["params"] != nil ? "rid:%s %s %s" : "rid:%s %s"
                                }),
                        
                        // a=imageattr:97 send [x=800,y=640,sar=1.1,q=0.6] [x=480,y=320] recv [x=330,y=250]
                        // a=imageattr:* send [x=800,y=640] recv *
                        // a=imageattr:100 recv [x=320,y=240]
                        SDPRule(name: "",
                                push: "imageattrs",
                                reg: "^imageattr:(\\d+|\\*)" +
                                    "[\\s\\t]+(send|recv)[\\s\\t]+(\\*|\\[\\S+\\](?:[\\s\\t]+\\[\\S+\\])*)" +
                                    "(?:[\\s\\t]+(recv|send)[\\s\\t]+(\\*|\\[\\S+\\](?:[\\s\\t]+\\[\\S+\\])*))?",
                                names: ["pt", "dir1", "attrs1", "dir2", "attrs2"],
                                types: ["s", "s", "s", "s", "s"],
                                format: "",
                                formatFunc: { o -> String in
                                    return "imageattr:%s %s %s" + (o["dir2"] != nil ? " %s %s" : "")
                                }),
                        
                        // a=simulcast:send 1,2,3;~4,~5 recv 6;~7,~8
                        // a=simulcast:recv 1;4,5 send 6;7
                        SDPRule(name: "simulcast",
                                push: "",
                                reg: "^simulcast:" +
                                     // send 1,2,3;~4,~5
                                    "(send|recv) ([a-zA-Z0-9\\-_~;,]+)" +
                                    // space + recv 6;~7,~8
                                    "(?:\\s?(send|recv) ([a-zA-Z0-9\\-_~;,]+))?" +
                                    // end
                                    "$",
                                names: ["dir1", "list1", "dir2", "list2"],
                                types: ["s", "s", "s", "s"],
                                format: "",
                                formatFunc: { o -> String in
                                    return "simulcast:%s %s" + (o["dir2"] != nil ? " %s %s" : "")
                                }),
                        
                        // Old simulcast draft 03 (implemented by Firefox).
                        //   https://tools.ietf.org/html/draft-ietf-mmusic-sdp-simulcast-03
                        // a=simulcast: recv pt=97;98 send pt=97
                        // a=simulcast: send rid=5;6;7 paused=6,7
                        SDPRule(name: "simulcast_03",
                                push: "",
                                reg: "^simulcast: (.+)$",
                                names: ["value"],
                                types: ["s"],
                                format: "simulcast: %s",
                                formatFunc: nil),
                        
                        // a=framerate:25
                        // a=framerate:29.97
                        SDPRule(name: "framerate",
                                push: "",
                                reg: "^framerate:(\\d+(?:$|\\.\\d+))",
                                names: [],
                                types: ["f"],
                                format: "framerate:%s",
                                formatFunc: nil),
                        
                        // a=source-filter: incl IN IP4 239.5.2.31 10.1.15.5
                        SDPRule(name: "sourceFilter",
                                push: "",
                                reg: "^source-filter:[\\s\\t]+(excl|incl) (\\S*) (IP4|IP6|\\*) (\\S*) (.*)",
                                names: ["filterMode", "netType", "addressTypes", "destAddress", "srcList"],
                                types: ["s", "s", "s", "s", "s"],
                                format: "source-filter: %s %s %s %s %s",
                                formatFunc: nil),
                        
                        // a=ts-refclk:ptp=IEEE1588-2008:00-50-C2-FF-FE-90-04-37:0
                        SDPRule(name: "tsRefclk",
                                push: "",
                                reg: "^ts-refclk:(.*)",
                                names: [],
                                types: ["s"],
                                format: "ts-refclk:%s",
                                formatFunc: nil),
                        
                        // a=mediaclk:direct=0
                        SDPRule(name: "mediaclk",
                                push: "",
                                reg: "^mediaclk:(.*)",
                                names: [],
                                types: ["s"],
                                format: "mediaclk:%s",
                                formatFunc: nil),
                        
                        // Any a= that we don't understand is kepts verbatim on media.invalid.
                        SDPRule(name: "",
                                push: "invalid",
                                reg: "(.*)",
                                names: ["value" ],
                                types: ["s"],
                                format: "%s",
                                formatFunc: nil)
            ]

    }

}

