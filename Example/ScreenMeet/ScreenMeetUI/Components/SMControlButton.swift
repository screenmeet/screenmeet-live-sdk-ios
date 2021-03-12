//
//  SMControlButton.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 24.02.2021.
//

import UIKit

class SMControlButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
    }
    
    func setup() {
        tintColor = .white
        imageView?.backgroundColor = .clear
        imageView?.contentMode = .scaleAspectFit
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        clipsToBounds = true
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
}
