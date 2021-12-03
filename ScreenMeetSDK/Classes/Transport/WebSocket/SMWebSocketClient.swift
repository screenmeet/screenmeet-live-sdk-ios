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
                DispatchQueue.main.async { 
                    ScreenMeet.session.delegate?.onConnectionStateChanged(newValue)
                }
            }
        }
    }
    private var socketIO: SocketIOClient!
    
    //Just need to keep one strong reference to SocketManager instance, used only when instantiating a socket
    private var manager: SocketManager!
    
    private var channelMessageHandler: ChannelMessageHandler?
    private var childConnectCompletion: ChildConnectCompletion?
    private var userName: String?
    private let entranceWaitDuration = TimeInterval(600)
    
    func connect(_ url: String,
               _ nameSpace: String,
               _ reconnectWaitTimeout: Int,
               _ completion: @escaping SocketReadyCompletion) {
        
        state = .connecting
                
        /* .connectParams is important! Without it server wont be able to register namespace... <- To investigate*/
        manager = SocketManager(socketURL: URL(string: url)!,
                                config: [.log(false), .reconnects(true), .reconnectWait(1), .connectParams(["roomId": nameSpace])])
        
        socketIO = manager.socket(forNamespace: "/\(nameSpace)")
        
        socketIO.on("ready") { [unowned self] (data, ack) in
            /* Remove pending disconnection handler. The one that is triggered if app wait for recconnect for too long (reconnectWaitTimeout) */
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(disconnectOnWaitTimeout), object: nil)
            
            completion(nil)
            self.pingPongEvent()
            
            NSLog("SID: ", socketIO.sid)
            NSLog("[SM Signalling] Ready")
        }
        
        socketIO.on(clientEvent: .reconnect, callback: { [weak self] data, ack in
            NSLog("[SM Signalling] Reconnect")
            self?.state = .reconnecting
            
            self?.perform(#selector(self?.disconnectOnWaitTimeout), with: nil, afterDelay: TimeInterval(reconnectWaitTimeout))
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
        
        socketIO.on("renegotiate", callback: { [weak self] data, ack in
            if let userName = self?.userName, let childConnectCompletion = self?.childConnectCompletion {
                self?.childConnect(userName, childConnectCompletion)
            }
        })
        
        socketIO.on("removed", callback: { data, ack in
            NSLog("[SM Signalling]", "Removed")
        })
        
        socketIO.on("dropping", callback: { [weak self] data, ack in
            self?.disconnect(.hostRefuedToLetIn)
            
            self?.childConnectCompletion?(nil, nil, SMError(code: .droppedByServer, message: "Host refused to let you in"))
           
        })
        
        socketIO.on(clientEvent: .disconnect) { [unowned self] data, ack in
            NSLog("[SM Signalling] Disconnect")
            
            /* Call suddenly terminated by server. Normally we set state to disconnected with a certain reason and then call socketIO.disconnect(). This way inside socketIO.on(clientEvent: .disconnect) {} handler the state is always .disconnected. In case the state inside this handler is any other it means that the socket was suddenly killed by server (someone force closed the room or ended the meeting)*/
            if state == .connected || state == .reconnecting  || state == .waitingEntrancePermission{
                state = .disconnected(.callEndedByServer)
            }
        }
        
        socketIO.connect()
    }
    
    func setChannelMessageHandler(_ handler: @escaping ChannelMessageHandler) {
        self.channelMessageHandler = handler
    }
    
    func childConnect(_ userName: String, _ completion: @escaping ChildConnectCompletion) {
        /* Save latest user name and completion in case we'll need to renegotiate*/
        self.userName = userName
        self.childConnectCompletion = completion
        
        /* Cancel entrance waiting timeout in case we are aiting for entracne (knock feature)*/
        cancelEntranceWaitingTimout()
        
        let identityInfo = SMIdentityInfo()
        identityInfo.user = SMIdentityInfoUser(name: userName)
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
                        let error = self?.socketErrorToSMError(initPayload!.error)
                        completion(nil, nil, error)
                        
                        /* If knock is on, we should not disconnect immediately but wait till user is let in*/
                        if error?.code == .knockEntryPermissionRequiredError {
                            self?.state = .waitingEntrancePermission
                            self?.setupEntranceWaitingTimout()
                        }
                        else {
                            self?.disconnect(.networkError)
                        }
                        
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
    
    func logInfo(_ event: SocketData) {
        socketIO.emit("logevent", event)
    }
    
    func disconnect(_ reason: SMDisconnectionReason) {
        state = .disconnected(reason)
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
    
    private func socketErrorToSMError(_ socketError: SMInitializationPayloadErrorDescription?) -> SMError {
        if let socketError = socketError {
            
            if socketError.code == 40310 {
                return SMError(code: .knockEntryPermissionRequiredError, message: "Entered the waiting room. Permission from the host is required to enter this call...")
            }
            else {
                return SMError(code: .socketError, message: socketError.description)
            }
            
        }
        return SMError(code: .socketError, message: "Unknwon fatal error occurred while connecting to the session")
    }
    
    private func cancelEntranceWaitingTimout() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(entranceWaitExpired), object: nil)
    }
    
    private func setupEntranceWaitingTimout() {
        perform(#selector(entranceWaitExpired), with: nil, afterDelay: entranceWaitDuration)
    }
    
    @objc private func entranceWaitExpired() {
        disconnect(.knockWaitTimeExpired)
        
        childConnectCompletion?(nil, nil, SMError(code: .knockWaitTimeForEntryExpiredError, message: "Waiting time to enter this room has expired. Hanging up"))
    }
    
    @objc private func disconnectOnWaitTimeout() {
        disconnect(.reconnectWaitTimeExpired)
        
        childConnectCompletion?(nil, nil, SMError(code: .knockWaitTimeForEntryExpiredError, message: "Waiting time to reconnect this room has expired. Hanging up"))
    }
}
