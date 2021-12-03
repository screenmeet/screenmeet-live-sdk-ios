//
//  SMCallerState.swift
//  ScreenMeetSDK
//
//  Created by Ross on 21.08.2021.
//

import Foundation
import SocketIO

/// Represents participant state
struct SMCallerState: SocketData {
    
    /// Is Audio enabled
    public var audioEnabled: Bool = false
    
    var outputEnabled: Bool = false
    
    /// Is Video enabled
    public var videoEnabled: Bool = false
    
    /// Is Screen enabled
    public var screenEnabled: Bool = false
    
    /// Is Screen Annotation enabled
    public var screenAnnotationEnabled: Bool = false

    var sourceType: String = "cam"
    
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
    }
    
    public func socketRepresentation() -> SocketData {
        var data = [String: Any]()
        data["audioenabled"]  = audioEnabled
        data["outputenabled"] = outputEnabled
        data["videoenabled"] = videoEnabled
        data["screenenabled"] = screenEnabled
        data["sourceType"] = sourceType
        data["talking"] = talking
        return data
    }
}
