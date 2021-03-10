//
//  SMStringifier.swift
//  ScreenMeet
//
//  Created by Ross on 15.01.2021.
//

import UIKit

class SMStringifier<T: Codable> {
    func stringify(_ object: T) -> String {
        do {
            let jsonData = try JSONEncoder().encode(object)
            let jsonString = String(data: jsonData, encoding: .utf8)!
           
            return jsonString
        } catch {
           return ""
        }
    }
}
