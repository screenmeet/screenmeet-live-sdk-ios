//
//  SMChatChannel.swift
//  Pods-ScreenMeet
//
//  Created by Ross on 21.08.2021.
//

import Foundation

class SMChatChannel: SMChannel {
    private var messages = [SMTextMessage]()
    
    var name: SMChannelName = .chat
    
    func processEvent(_ message: SMChannelMessage) {
        let data = message.data
        
        guard let newMessages = data[1] as? [String: Any] else { return }
        
        for (key, messageDict) in newMessages {
           
            let message = messageDict as! [String: Any]
            let createdOn = message["ts"] as! Double
            let sender = message["from"] as! [String: Any]
            
            let m = SMTextMessage(id: key, createdOn: Date(timeIntervalSince1970: createdOn / 1000),
                                  updatedOn: nil,
                                  text: message["message"] as! String,
                                  senderId: sender["cid"] as! String,
                                  senderName: sender["name"] as! String)
            
            messages.append(m)
            
            DispatchQueue.main.async {
                ScreenMeet.session.chatDelegate?.onTextMessageReceived(m)
            }
        }
        
    }
    
    func buildState(from initialPayload: [String : Any]) {
        messages.removeAll()
        
        for (key, messageDict) in initialPayload {
            let createdOn = (messageDict as!  [String: Any])["_createdOn"] as! Double
            let updatedOn = (messageDict as!  [String: Any])["_updatedOn"] as! Double
            
            let message = (messageDict as! [String: Any])["value"] as! [String: Any]
            let sender = message["from"] as! [String: Any]
            
            let m = SMTextMessage(id: key, createdOn: Date(timeIntervalSince1970: createdOn / 1000),
                                  updatedOn: Date(timeIntervalSince1970: updatedOn / 1000),
                                  text: message["message"] as! String,
                                  senderId: sender["cid"] as! String,
                                  senderName: sender["name"] as! String)
            
            messages.append(m)
        }
    }
    
    func getMessages() -> [SMTextMessage] {
        return messages
    }
    
    func sendTextMessage(_ text: String) {
        transport.webSocketClient.command(for: .chat, message: "sendMessage", data: text) { data in
            
        }
    }
}
