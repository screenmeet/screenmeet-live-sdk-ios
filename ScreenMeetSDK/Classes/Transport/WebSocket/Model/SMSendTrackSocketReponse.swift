//
//  SMSendTrackSocketReponse.swift
//  ScreenMeet
//
//  Created by Ross on 18.01.2021.
//

import UIKit

struct SMSendTrackSocketReponse: Codable {
    var success: Bool
    var result: SMSendTrackSocketReponseResult
}

struct SMSendTrackSocketReponseResult: Codable {
    var id: String
}
