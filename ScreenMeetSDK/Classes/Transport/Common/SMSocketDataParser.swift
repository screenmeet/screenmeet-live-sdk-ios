//
//  SMSocketDataParser.swift
//  ScreenMeet
//
//  Created by Ross on 15.01.2021.
//

import UIKit


class SMSocketDataParser: NSObject {
    func parse<T>(_ dataToParse: [Any], completion: @escaping (T?, SMError?) -> Void) where T: Decodable {
        if dataToParse.count > 0, let data = dataToParse[0] as? [String: Any] {
            do {
                let serializedData = try JSONSerialization.data(withJSONObject: data)
                let parsed = try JSONDecoder().decode(T.self, from: serializedData)
                completion(parsed, nil)
                
            } catch {
                completion(nil, SMError(code: .socketError, message: "Could not parse socket object: " + error.localizedDescription))
            }
        }
    }
    
    func parse<T>(_ dataToParse: [String: Any], completion: @escaping (T?, SMError?) -> Void) where T: Decodable {
        do {
            let serializedData = try JSONSerialization.data(withJSONObject: dataToParse)
            let parsed = try JSONDecoder().decode(T.self, from: serializedData)
            completion(parsed, nil)
            
        } catch {
            completion(nil, SMError(code: .socketError, message: "Could not parse socket object: " + error.localizedDescription))
        }
    }
    
    func parse<T>(_ stringDataToParse: String, completion: @escaping (T?, SMError?) -> Void) where T: Decodable {
        do {
            let serializedData = try JSONSerialization.data(withJSONObject: stringDataToParse.utf8)
            let parsed = try JSONDecoder().decode(T.self, from: serializedData)
            completion(parsed, nil)
            
        } catch {
            completion(nil, SMError(code: .socketError, message: "Could not parse socket object: " + error.localizedDescription))
        }
    }
}
