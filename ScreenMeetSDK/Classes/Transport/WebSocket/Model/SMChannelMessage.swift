//
//  SMChannelMessage.swift
//  ScreenMeet
//
//  Created by Ross on 13.01.2021.
//

import UIKit

enum SMChannelMessageActionType {
    case added
    case removed
}

struct SMChannelMessage {
    var actionType: SMChannelMessageActionType = .added
    var channelName: SMChannelName
    var data: [Any]
}
