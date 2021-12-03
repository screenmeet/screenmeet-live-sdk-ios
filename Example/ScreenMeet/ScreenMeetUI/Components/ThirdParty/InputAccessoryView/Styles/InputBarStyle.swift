//
//  InputBarStyle.swift
//  Example
//
//  Created by Nathan Tannar on 8/18/17.
//  Copyright © 2017-2020 Nathan Tannar. All rights reserved.
//

import Foundation
import UIKit

enum InputBarStyle: String, CaseIterable {
    
    case imessage = "iMessage"
    case slack = "Slack"
    case facebook = "Facebook"
    case noTextView = "No InputTextView"
    case `default` = "Default"
    
    func generate(presentingViewController: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), _ takePictureController: FDTakeController) -> InputBarAccessoryView {
        switch self {
        case .imessage: return iMessageInputBar()
        case .slack: return SlackInputBar(presentingViewController, takePictureController)
        case .facebook: return FacebookInputBar()
        case .noTextView: return NoTextViewInputBar()
        case .default: return InputBarAccessoryView()
        }
    }
}
