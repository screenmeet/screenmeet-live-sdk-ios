//
//  SMEntitlementModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 05.07.2021.
//

import Foundation

public struct SMFeature {
    public let type: SMEntitlementType
    public let requestorParticipant: SMParticipant
}

struct SMEntitlement {
    var type: SMEntitlementType
    var requestorId: String
    var grantorId: String
}

struct SMEntitlementsWrapper {
    var entitlements: [SMEntitlement]
}

extension SMEntitlementsWrapper: Decodable {
    
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
        
        var entitlements = [SMEntitlement]()
        
        for requestorKey in container.allKeys {
            let requestorContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: requestorKey)
            
            for grantorKey in requestorContainer.allKeys {
                let grantorContainer = try requestorContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: grantorKey)
                
                for entitlementKey in grantorContainer.allKeys {
                    let enabled: Bool = try grantorContainer.decode(Bool.self, forKey: entitlementKey)
                    
                    if enabled, let entitlementType = SMEntitlementType(rawValue: entitlementKey.stringValue) {
                        let entitlement = SMEntitlement(type: entitlementType, requestorId: requestorKey.stringValue, grantorId: grantorKey.stringValue)
                        entitlements.append(entitlement)
                    }
                }
            }
        }
        
        self.entitlements = entitlements
    }
}
