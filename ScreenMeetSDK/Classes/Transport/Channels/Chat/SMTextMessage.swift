//
//  SMTextMessage.swift
//  ScreenMeetSDK
//
//  Created by Ross on 21.08.2021.
//

import Foundation

public struct SMTextMessage {
    public let id: String
    public let createdOn: Date
    public let updatedOn: Date?
    public let text: String
    public let senderId: String
    public let senderName: String
}
