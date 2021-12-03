//
//  SMChatBubbleView.swift
//  ScreenMeet
//
//  Created by Ross on 20.08.2021.
//

import UIKit

protocol SMChatBubbleProtocol: AnyObject {
    func onClicked()
}

class SMChatBubbleView: UIView {

    weak var delegate: SMChatBubbleProtocol?
    
    var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "icon-chat"), for: .normal)
        return button
    }()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        translatesAutoresizingMaskIntoConstraints = false
       
        clipsToBounds = true
        addSubview(button)
        
        button.addTarget(self, action: #selector(onClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onClicked() {
        delegate?.onClicked()
    }
}
