//
//  SDPRule.swift
//  ScreenMeet
//
//  Created by Ross on 26.01.2021.
//

import UIKit

typealias SDPFormatFunc = ([String: Any]) -> String

struct SDPRule {
    var name: String
    var push: String
    var reg: String
    var names: [String]
    var types: [String]
    var format: String
    var formatFunc: SDPFormatFunc?
}
