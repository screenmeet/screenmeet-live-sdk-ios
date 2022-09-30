//
//  SMCallerState.swift
//  ScreenMeetSDK
//
//  Created by Ross on 21.08.2021.
//

import Foundation
import SocketIO

/// Represents participant state
class SMCallerState: SocketData {
    
    /// Is Audio enabled
    public var audioEnabled: Bool = false
    
    var outputEnabled: Bool = true
    
    /// Is Video enabled
    public var videoEnabled: Bool = false
    
    /// Is Screen enabled
    public var screenEnabled: Bool = false
    
    /// Is Image transfer session enabled
    public var imageTransferEnabled: Bool = false
    
    /// Is Screen Annotation enabled
    public var screenAnnotationEnabled: Bool = false

    var sourceType: String = "camera"
    
    var source = [String: Any]()
    
    /// Is talking
    public var talking: Bool = false
    
    init() {
        
    }
    
    init(_ socketData: [String: Any], _ currentState: SMCallerState?) {
        if let audioEnabled = socketData["audioenabled"] as? Bool { self.audioEnabled = audioEnabled }
        else { self.audioEnabled = currentState?.audioEnabled ?? false}
        
        if let outputEnabled = socketData["outputenabled"] as? Bool { self.outputEnabled = outputEnabled }
        else { self.outputEnabled = currentState?.outputEnabled ?? false}
        
        if let videoEnabled = socketData["videoenabled"] as? Bool { self.videoEnabled = videoEnabled }
        else { self.videoEnabled = currentState?.videoEnabled ?? false}
        
        if let screenEnabled = socketData["screenenabled"] as? Bool { self.screenEnabled = screenEnabled }
        else { self.screenEnabled = currentState?.screenEnabled ?? false}
        
        if let screenAnnotationEnabled = socketData["screenannotationenabled"] as? Bool { self.screenAnnotationEnabled = screenAnnotationEnabled }
        else { self.screenAnnotationEnabled = currentState?.screenAnnotationEnabled ?? false}
        
        if let sourceType = socketData["sourceType"] as? String { self.sourceType = sourceType }
        else { self.sourceType = currentState?.sourceType ?? "cam"}
        
        if let talking = socketData["talking"] as? Bool { self.talking = talking }
        else { self.talking = currentState?.talking ?? false}
        
        if let source = socketData["source"] as? [String: Any] { self.source = source }
        else { self.source = currentState?.source ?? [String: Any]()}
    }
    
    public func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["audioenabled"]  = audioEnabled
        data["outputenabled"] = outputEnabled
        data["videoenabled"] = videoEnabled
        data["screenenabled"] = screenEnabled
        data["sourceType"] = sourceType
        data["talking"] = talking
        data["width"] = source["width"]
        data["height"] = source["height"]
        return data
    }
}
