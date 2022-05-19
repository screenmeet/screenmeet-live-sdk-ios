//
//  SMImageHandler.swift
//  ScreenMeetSDK
//
//  Created by Ross on 10.05.2022.
//

import UIKit

typealias ImageReceived = (UIImage) -> Void

public class SMImageHandler: NSObject {
    var imageHandler: ImageReceived!
    
    public func transferImage(_ image: UIImage) {
        imageHandler(image)
    }
}
