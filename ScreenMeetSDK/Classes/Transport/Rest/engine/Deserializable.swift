//
//  Deserializable.swift
//  EquifyCRM
//
//  Created by Rostyslav Stepanyak on 25/06/18.
//  Copyright © 2017 DDragons LLC. All rights reserved.
//

import Foundation

protocol Deserializable {
    init?(data: Data)
}
