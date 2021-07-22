//
//  MSLogger.swift
//  ScreenMeet
//
//  Created by Ross on 08.02.2021.
//

import UIKit
import WebRTC

class MSLogger: NSObject {
    static let shared = MSLogger()
    private var callbackLogger: RTCCallbackLogger!
    private override init() { }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func startPeerLog(_ peer: RTCPeerConnection) {
        let str = "Starting logs\n"
        let url = getDocumentsDirectory().appendingPathComponent("peerlogs.txt")
        
        let fileManger = FileManager.default
        if fileManger.fileExists(atPath: url.path){
            do{
                try fileManger.removeItem(at: url)
            }catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        do {
            try str.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
        
        if callbackLogger == nil {
            callbackLogger = RTCCallbackLogger()
            callbackLogger.start { str in
                NSLog("[MS Log] " + str)
            }
        }
        
        peer.startRtcEventLog(withFilePath: url.path, maxSizeInBytes: Int64.max)
    }
    
    func printPeerLog(_ peer: RTCPeerConnection) {
        peer.stopRtcEventLog()
        let url = getDocumentsDirectory().appendingPathComponent("peerlogs.txt")
        do {
            _ = try String(contentsOf: url, encoding: .utf16)
            //NSLog("Peer logs: ", text)
        }
        catch {
            NSLog(error.localizedDescription)
        }
    }
    
    /*
    func startLoggingWebRtc() {
        RTCInitializeSSL()
        RTCSetMinDebugLogLevel(.verbose)
        //RTCSetupInternalTracer()
        
        let str = "Starting logs\n"
        let url = getDocumentsDirectory().appendingPathComponent("rtclogs.txt")
        
        let fileManger = FileManager.default
        if fileManger.fileExists(atPath: url.path){
            do{
                try fileManger.removeItem(at: url)
            }catch let error {
                print("error occurred, here are the details:\n \(error)")
            }
        }
        
        do {
            try str.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
                
        RTCStartInternalCapture(url.path)
    }*/
    
    func printAllLogsFromDump() {
        stopLoggingWebRtc()
        let url = getDocumentsDirectory().appendingPathComponent("rtclogs.txt")
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            
            do{
                if let json = text.data(using: String.Encoding.utf8){
                    if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:AnyObject]{
                        //NSLog(jsonData.description)
                        
                        let events = jsonData["traceEvents"] as! [[String: Any]]
                        
                        _ = events.filter { (event) -> Bool in
                            (event["name"] as! String).lowercased().contains("remote")
                        }
                        
                        NSLog("Logs filtered")
                    }
                }
            }catch {
                print(error.localizedDescription)

            }
        }
        catch {
            NSLog("Could not print logs")
        }
    }
    
    func stopLoggingWebRtc() {
        RTCStopInternalCapture()
    }
}
