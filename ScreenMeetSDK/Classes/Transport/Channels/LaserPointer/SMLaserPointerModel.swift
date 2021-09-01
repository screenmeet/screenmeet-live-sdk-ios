//
//  SMLaserPointerModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 30.06.2021.
//

import Foundation

struct SMLaserPointerModel: Decodable {
    
    var data: Data
    
    var from: String
    
    var to: String
    
    struct Data: Decodable {
        
        var coords: Coords?
        
        var click: Bool?
        
        struct Coords: Decodable {
            
            var x: CGFloat
            
            var y: CGFloat
        }
    }
}
