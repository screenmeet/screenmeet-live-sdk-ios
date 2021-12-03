//
//  SlackInputBar.swift
//  Example
//
//  Created by Nathan Tannar on 2018-06-06.
//  Copyright © 2018 Nathan Tannar. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

final class SlackInputBar: InputBarAccessoryView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    init(_ presentingViewController: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? = nil,  _ takePictureController: FDTakeController) {
        super.init(frame: .zero)
        configure(presentingViewController, takePictureController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ presentingViewController: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? = nil, _ takePictureController: FDTakeController? = nil) {
        
        weak var viewController = presentingViewController
        weak var takeController = takePictureController
        
        
        let items = [
            makeButton(named: "ic_camera").onTextViewDidChange { button, textView in
                    button.isEnabled = textView.text.isEmpty
                }.onSelected {
                    $0.tintColor = .systemBlue
                    takeController?.present()
                    
            },
            makeButton(named: "ic_library", 2)
                .configure({ button in
                    //button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
                })
                .onSelected {
                    $0.tintColor = .systemBlue
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = viewController
                    imagePicker.sourceType = .photoLibrary
                    imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
                    
                    //let window = UIApplication.shared.windows.first(where: \.isKeyWindow)
                    
                   (viewController as? UIViewController)?.present(imagePicker, animated: true, completion: nil)
            },
            makeButton(named: "icon-record", 2)
                .configure({ button in
                    //button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
                })
                .onSelected {
                    $0.tintColor = .systemBlue
                    
                    
            },
            makeButton(named: "icon-hide-keyboard", 2)
                .configure({ button in
                    button.isHidden = true
                })
                .onKeyboardEditingEnds({ (item) in
                    item.isHidden = true
                })
                .onKeyboardEditingBegins({ (item) in
                    item.isHidden = false
                })
                .onSelected { [weak self] in
                    $0.tintColor = .systemBlue
                    self?.inputTextView.resignFirstResponder()
            },
            .flexibleSpace,
            sendButton
                .configure {
                    $0.image = #imageLiteral(resourceName: "ic_send").withRenderingMode(.alwaysTemplate)
                    $0.title = nil
                    $0.tintColor = tintColor
                    $0.setSize(CGSize(width: 32, height: 32), animated: false)
                }.onDisabled {
                    $0.tintColor = .lightGray
                }.onEnabled {
                    $0.tintColor = UIColor.blue
                }
        ]
        items.forEach { $0.tintColor = .lightGray }
        
        // We can change the container insets if we want
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        let maxSizeItem = InputBarButtonItem()
            .configure {
                $0.image = UIImage(named: "icons8-expand")?.withRenderingMode(.alwaysTemplate)
                $0.tintColor = .darkGray
                $0.setSize(CGSize(width: 20, height: 20), animated: false)
            }.onSelected {
                let oldValue = $0.inputBarAccessoryView?.shouldForceTextViewMaxHeight ?? false
                $0.image = oldValue ? UIImage(named: "icons8-expand")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "icons8-collapse")?.withRenderingMode(.alwaysTemplate)
                self.setShouldForceMaxTextViewHeight(to: !oldValue, animated: true)
        }
        rightStackView.alignment = .top
        setStackViewItems([maxSizeItem], forStack: .right, animated: false)
        setRightStackViewWidthConstant(to: 20, animated: false)
        
        // Finally set the items
        setStackViewItems(items, forStack: .bottom, animated: false)

        shouldAnimateTextDidChangeLayout = true
    }
    
    private func makeButton(named: String, _ topOffset: Int = 0) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(4)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 28, height: 28 - topOffset), animated: false)
            }.onSelected {
                $0.tintColor = .systemBlue
            }.onDeselected {
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside { _ in
                print("Item Tapped")
        }
    }
    
}

extension SlackInputBar: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        picker.dismiss(animated: true, completion: {
            if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
                self.inputPlugins.forEach { _ = $0.handleInput(of: pickedImage) }
            }
        })
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
