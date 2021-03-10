//
//  SDPTransform.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit

typealias MSJson = [String: Any]
typealias MSJsonArray = [[String: Any]]

class SDPTransform: NSObject {
    static func parse(_ sdp: String) -> [String: Any] {
        let ValidLineRegex = "^([a-z])=(.*)"
        
        let lines = sdp.components(separatedBy: "\n")
        var media = MSJsonArray()
        var session = MSJson()
        
        for var line in lines {
            if !line.isEmpty && line.last == "\r" {
                line.removeLast()
            }

            if line.range(of: ValidLineRegex, options: .regularExpression) == nil {
                continue
            }
            
            let type = String(line.first!)
            
            let fromIndex = line.index(line.startIndex, offsetBy: 2)
            let content = String(line[fromIndex...])
            
            if type == "m" {
                var m = MSJson()
                m["rtp"] = MSJsonArray()
                m["fmtp"] = MSJsonArray()
                
                media.append(m)
            }
            
            if SDPGrammar.rules[type] == nil {
                continue
            }
            
            let rules = SDPGrammar.rules[type]!
            
            var linesParsed = 0
            for rule in rules {
                if content.range(of: rule.reg, options: .regularExpression) != nil {
                    if let lastRecord = media.last {
                        let parsedRecord = parseReg(rule, lastRecord, content)
                        
                        var exisitingRecord = media[media.count-1]
                        
                        for (k, v) in parsedRecord {
                            exisitingRecord.updateValue(v, forKey: k)
                        }
                        
                        media[media.count-1] = exisitingRecord
                    }
                    else {
                        let parsedSession = parseReg(rule, session, content)
                        session = parsedSession
                    }
                   
                    break
                }
                else {
                    //NSLog("Skipped line: " + content)
                }
            }
            
            linesParsed += 1
        }
        
        session["media"] = media
        
        return session
    }
    
    static func parseReg(_ rule: SDPRule, _ record: MSJson, _ content: String) -> MSJson {
        let needsBlank = !rule.name.isEmpty && !rule.names.isEmpty
        
        let matchedStrings = content.matches(rule.reg)
        
        var newRecord = record
        
        if newRecord[rule.push] == nil && !rule.push.isEmpty {
            newRecord[rule.push] = MSJsonArray()
        }
        
        
        if newRecord[rule.name] == nil && !rule.name.isEmpty {
            newRecord[rule.name] = MSJson()
        }
        
        
        var parsed: MSJson!
        if !rule.push.isEmpty {
            parsed = attachProperties(matchedStrings, MSJson(), rule.names, rule.name, rule.types)
        }
        else {
            if needsBlank {
                parsed = attachProperties(matchedStrings, newRecord[rule.name] as! MSJson, rule.names, rule.name, rule.types)
                newRecord[rule.name] = parsed
            }
            else {
                parsed = attachProperties(matchedStrings, newRecord, rule.names, rule.name, rule.types)
                newRecord = parsed
            }
        }
       
        
        if (!rule.push.isEmpty) {
            if var pushArray = (newRecord[rule.push] as? MSJsonArray) {
                pushArray.append(parsed)
                newRecord[rule.push] = pushArray
            }
            
        }
        
        return newRecord
    }
    
    static func attachProperties(_ matched: [String],
                          _ record: MSJson,
                          _ ruleNames: [String],
                          _ ruleName: String,
                          _ ruleTypes: [String]) -> MSJson {
        
        var newRecord = record
        if (!ruleName.isEmpty && ruleNames.isEmpty) {
            newRecord[ruleName] = toType(matched[1], ruleTypes[0]);
        }
        else {
            for (i, _) in ruleNames.enumerated() {
                if (i+1) < matched.count && !matched[i+1].isEmpty {
                    newRecord[ruleNames[i]] = toType(matched[i+1], ruleTypes[i])
                }
            }
        }
        
        return newRecord
    }
    
    static func toType(_ str: String, _ type: String) -> Any? {
        if type == "s" {
            return str
        }
        
        if type == "d" {
            return (str as NSString).integerValue
        }
        
        if type == "f" {
            return (str as NSString).doubleValue
        }
        
        return nil
    }
    
    static func parseParams(_ str: String) -> MSJson {
        var obj = MSJson()
        let lines = str.components(separatedBy: ";")
        
        for line in lines {
            let param = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if param.isEmpty {
                continue
            }
            
            let insertedParams = insertParam(obj, param)
            obj = insertedParams
        }
        
        return obj
    }
    
    static func insertParam(_ o: MSJson, _ str: String) -> MSJson {
        var obj = o
        
        let chunks = str.components(separatedBy: "=")
        
        let wellKnownParameters = ["profile-level-id": "s",
                                   "packetization-mode": "d",
                                   "profile-id": "s"]
        
        let key = chunks[0]
        let value = chunks[1]
        
        
        var type = ""
        if let knownValue = wellKnownParameters[key] {
            type = knownValue
        }
        else if Int(value) != nil{
            type = "d"
        }
        else if Float(value) != nil{
            type = "f"
        }
        else {
            type = "s"
        }
        
        obj[key] =  toType(value, type)
        return obj
    }
    
    // Write
    static func write(_ session: inout MSJson) -> String {
        // RFC specified order.
        let outerOrder = [ "v", "o", "s", "i", "u", "e", "p", "c", "b", "t", "r", "z", "a" ]
        let innerOrder = [ "i", "c", "b", "a" ]

        // Ensure certain properties exist
        if (session["version"] == nil) { session["version"] = 0 }
        if (session["name"] == nil) { session["name"] = " " }
        if (session["media"] == nil) { session["media"] = MSJsonArray() }

        var mediaLines = (session["media"] as! MSJsonArray)
        for (index, mLine) in mediaLines.enumerated() {
            var line = mLine
            if (line["payloads"] == nil) {
                line["payloads"] = ""
                
                mediaLines[index] = line
            }
        }
        
        session["media"] = mediaLines
        var sdpstream = ""

        // Loop through outerOrder for matching properties on session.
        for type in outerOrder {
            let rules = SDPGrammar.rules[type]!
            for rule in rules {
                if !rule.name.isEmpty && session[rule.name] != nil  {
                    sdpstream = makeLine(sdpstream, type, rule, session)
                }
                else if !rule.push.isEmpty && session[rule.push] != nil && session[rule.push]! as? [Any] != nil {
                    for el in session[rule.push] as! MSJsonArray {
                        sdpstream = makeLine(sdpstream, type, rule, el);
                    }
                }
            }
        }
        
        // Then for each media line, follow the innerOrder.
        for mLine in session["media"] as! MSJsonArray {
            sdpstream = makeLine(sdpstream, "m", SDPGrammar.rules["m"]![0], mLine)

            for type in innerOrder {
                let rules = SDPGrammar.rules[type]!
                for rule in rules {
                    if !rule.name.isEmpty && mLine[rule.name] != nil  {
                        sdpstream = makeLine(sdpstream, type, rule, mLine)
                    }
                    else if !rule.push.isEmpty && mLine[rule.push] != nil {
                        for el in mLine[rule.push] as! MSJsonArray {
                            sdpstream = makeLine(sdpstream, type, rule, el);
                        }
                    }
                }
            }
        }

        return sdpstream
    }
    
    static func makeLine(_ sdpstream: String,
                         _ type: String,
                         _ rule: SDPRule,
                         _ location: MSJson) -> String {
        var newStream = sdpstream
        var format: String?
        if rule.format.isEmpty {
            format = rule.formatFunc?( rule.push.isEmpty ? location : (!rule.name.isEmpty ? (location[rule.name] as! MSJson) : location))
        }
        else {
            format = rule.format
        }

        var args = [Any]()
        let locationNameObj = location[rule.name]

        if (!rule.names.isEmpty) {
            for name in rule.names {
                if !rule.name.isEmpty, let obj = location[rule.name] as? MSJson, obj[name] != nil {
                    let arg = obj[name]
                    if let stringArg = arg as? String {
                        args.append(stringArg)
                    }
                    if let intArg = arg as? Int {
                        args.append(intArg)
                    }
                }
                
                // For mLine and push attributes.
                else if let name = location[name] {
                    if let stringName = name as? String {
                        args.append(stringName)
                    }
                    if let intName = name as? Int {
                        args.append(intName)
                    }
                }
                // NOTE: Otherwise ensure an empty value is inserted into args array.
                else {
                    args.append("")
                }
            }
        }
        else if locationNameObj != nil {
            args.append(locationNameObj!)
        }
        else {
            NSLog("[MS] SDPTransofrm writer issue")
        }

        var linestream = ""

        linestream.append(type)
        linestream.append("=")
        linestream.append(format!)
        
        linestream = replacePercentParametersWithValues(linestream, args)
        
        linestream.append("\r\n")
        newStream.append(linestream)
        
        return newStream
    }
    
    static func replacePercentParametersWithValues(_ formatStr: String, _ args: [Any]) -> String {
        
        let formatRegex = "%[sdv%]"
        
        var i = 0
        let len = args.count
        
        return formatStr.replace(formatRegex) { matches -> String in
            if (i >= len) {
                return matches[0] // missing argument
            }
            
            let arg = args[i]
            i+=1
            let x = matches[0]
            
            if x == "%%" {
                return "%"
            }
            
            if x == "%d" {
                if let intVal = arg as? Int {
                  return String(intVal)
                }
                if let strVal = arg as? String {
                  return String(strVal)
                }
            }
            
            if x == "%v" {
                return ""
            }
            
            if x == "%s" {
                if let intVal = arg as? Int {
                  return String(intVal)
                }
                if let strVal = arg as? String {
                  return String(strVal)
                }
            }
            
            return ""
            
            
        }
    }
}


