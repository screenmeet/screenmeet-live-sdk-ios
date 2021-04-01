//
//  SMWebSocketClient.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit
import SocketIO

class SMWebSocketClient: NSObject {
    typealias SocketReadyCompletion = (SMError?) -> Void
    typealias ChildConnectCompletion = (SMInitializationPayload?, _ sharedData: [String: Any]?, SMError?) -> Void
    
    private var state: SMConnectionState = .disconnected(.callNotStarted) {
        willSet {
            if (newValue != state) {
                DispatchQueue.main.async { [weak self] in
                    ScreenMeet.session.delegate?.onConnectionStateChanged(newValue)
                }
            }
        }
    }
    private var socketIO: SocketIOClient!
    
    //Just need to keep one strong reference to SocketManager instance, used only when instantiating a socket
    private var manager: SocketManager!
    
    private var reconnectHandler: ReconnectHandler?
    private var channelMessageHandler: ChannelMessageHandler?
    
    func connect(_ url: String,
               _ nameSpace: String,
               _ completion: @escaping SocketReadyCompletion) {
        
        state = .connecting
        
        /* .connectParams is important! Without it server wont be able to register namespace... <- To investigate*/
        manager = SocketManager(socketURL: URL(string: url)!,
                                config: [.log(true), .reconnects(true), .reconnectWait(1), .connectParams(["roomId": nameSpace])])
        
        socketIO = manager.socket(forNamespace: "/\(nameSpace)")
        
        socketIO.on("ready") { [unowned self] (data, ack) in
            completion(nil)
            self.pingPongEvent()
            
            NSLog("SID: ", socketIO.sid)
            NSLog("[SM Signalling] Ready")
        }
        
        socketIO.on(clientEvent: .reconnect, callback: { [weak self] data, ack in
            NSLog("[SM Signalling] Reconnect")
            self?.state = .reconnecting
            self?.reconnectHandler?()
        })
        
        socketIO.on("pub", callback: { [weak self]  data, ack in
            guard let channel = data[0] as? String, let channelName = SMChannelName(rawValue: channel) else { return }
            
            let channelMessage = SMChannelMessage(actionType: .added, channelName: channelName, data: data)
            self?.channelMessageHandler?(channelMessage)
        })
        
        socketIO.on("removed", callback: { [weak self]  data, ack in
            guard let channel = data[0] as? String, let channelName = SMChannelName(rawValue: channel) else { return }
            
            let channelMessage = SMChannelMessage(actionType: .removed, channelName: channelName, data: data)
            self?.channelMessageHandler?(channelMessage)
        })
        
        socketIO.on("dm", callback: { [weak self]  data, ack in
            guard let channel = data[0] as? String, let channelName = SMChannelName(rawValue: channel) else { return }
            
            if let message = data[1] as? [String: Any] {
                let target = message["to"] as! String
                if target == self?.sid {
                    let channelMessage = SMChannelMessage(channelName: channelName, data: data)
                    self?.channelMessageHandler?(channelMessage)
                }
            }
        })
        
        socketIO.on("removed", callback: { data, ack in
         
        })
        socketIO.on("terminate", callback: { [unowned self] data, ack in
            state = .disconnected(.callEnded)
            NSLog("[SM Signalling] Disconnected")
        })
        
        socketIO.on(clientEvent: .disconnect) { [unowned self] data, ack in
            NSLog("[SM Signalling] Disconnect")
            /* We do not update the state (to .disconnected) becasue a reconnecting may be happening soon*/
        }
        
        socketIO.connect()
    }
    
    func setReconnectHandler(_ handler: @escaping ReconnectHandler) {
        self.reconnectHandler = handler
    }
    
    func setChannelMessageHandler(_ handler: @escaping ChannelMessageHandler) {
        self.channelMessageHandler = handler
    }
    
    func childConnect(_ completion: @escaping ChildConnectCompletion) {
        let identityInfo = SMIdentityInfo()
        let handshakeOptions = SMHandshakeOptions(overrideDupe: nil, reconnect: true)

        socketIO.emitWithAck("child-connect", identityInfo, handshakeOptions).timingOut(after: 0) { [weak self] response in
            
            SMSocketDataParser().parse(response) { (initPayload: SMInitializationPayload?, error) in
                if let error = error {
                    completion(nil, nil, SMError(code: .socketError,
                                                 message: "Could not parse child-connect reponse: " + error.message ))
                }
                else {
                    /* we cant put shared data inside initPayload as it's very unstructured and not
                     strictly typed, so we pass it in the callback separately*/
                    if initPayload!.success {
                        self?.state = .connected
                        
                        let data = response[0] as? [String: Any]
                        completion(initPayload!, data!["sharedData"] as? [String : Any], nil)
                    }
                    else {
                        completion(nil, nil, SMError(code: .socketError,
                                                     message: "Child connect failed. InitialPayload contains error..." + (initPayload!.error?.description ?? "N/A") ))
                        self?.diconnect()
                        self?.state = .disconnected(.networkError)
                    }
                }
            }
        }
    }
    
    func requestSet(for channelName: SMChannelName, data: SocketData, completion: AckCallback? = nil) {
        
        if let completion = completion {
            socketIO.emitWithAck("request-set", channelName.rawValue, data).timingOut(after: 10, callback: completion)
        }
        else{
            socketIO.emit("request-set", channelName.rawValue, data)
        }
    }
    
    func command(for channelName: SMChannelName,
                 message: String,
                 data: SocketData,
                 callback: @escaping AckCallback ) {
              
        socketIO.emitWithAck("command", channelName.rawValue, message, data).timingOut(after: 10, callback: callback)
    }
    
    func diconnect() {
        state = .disconnected(.leftCall)
        socketIO.disconnect()
    }
    
    func getConnectionState() -> SMConnectionState {
        return state
    }
    
    var sid: String? {
        let socketSID = socketIO.sid
        
        let parts = socketSID.split{$0 == "#"}.map(String.init)
        if parts.count > 1 {
            return parts[1]
        }
        
        return nil
    }
    
    private func pingPongEvent() {
        socketIO.on("_ping") { data, ack in
            ack.with("pong")
        }
    }
}
