//
//  SMRequestModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 30.06.2021.
//

import Foundation

struct SMRequestModel {
    
    var entitlementType: SMEntitlementType
    
    var requestorId: String
    
    var grantorId: String
}

struct SMRequestModelWrapper: Decodable {
    
    var requests: [SMRequestModel]
    
    private struct CodingKeys: CodingKey {
        
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init(value: String) {
            self.stringValue = value
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var requests = [SMRequestModel]()
        
        for typeKey in container.allKeys {
            let typeContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: typeKey)
            
            for grantorKey in typeContainer.allKeys {
                let requestorsId: [String] = try typeContainer.decode([String].self, forKey: grantorKey)
                
                for requestorId in requestorsId {
                    if let entitlementType = SMEntitlementType(rawValue: typeKey.stringValue) {
                        requests.append(SMRequestModel(entitlementType: entitlementType, requestorId: requestorId, grantorId: grantorKey.stringValue))
                    }
                }
            }
        }
        
        self.requests = requests
    }
}
