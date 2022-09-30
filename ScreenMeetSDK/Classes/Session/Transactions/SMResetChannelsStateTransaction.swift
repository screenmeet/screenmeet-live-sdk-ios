//
//  SMResetChannelsStateTransaction.swift
//  ScreenMeetSDK
//
//  Created by Ross on 07.07.2022.
//

import UIKit


class SMResetChannelsStateTransaction: SMTransaction {
    
    func run() {
        let participantsChannel = transport.channelsManager.channel(for: .participants) as! SMParticipantsChannel
        participantsChannel.removeAllParticipants()
        
        let callerStateChannel = transport.channelsManager.channel(for: .callerState) as! SMCallerStateChannel
        callerStateChannel.resetCallerState()
        
        let laserPointerChannel = transport.channelsManager.channel(for: .laserPointer) as! SMLaserPointerChannel
        laserPointerChannel.stopAllLaserPointerSessions()
        
        let remoteControlChannel = transport.channelsManager.channel(for: .remoteControl) as! SMRemoteControlChannel
        remoteControlChannel.stopAllRemoteControlSessions()
        
        let permissionsChannel = transport.channelsManager.channel(for: .permissions) as! SMPermissionsChannel
        permissionsChannel.removeAllPermissions()
    }
}
