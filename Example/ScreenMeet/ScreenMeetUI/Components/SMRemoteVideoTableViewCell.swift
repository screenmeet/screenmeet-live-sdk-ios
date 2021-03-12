//
//  SMRemoteVideoTableViewCell.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 11.03.2021.
//

import UIKit
import ScreenMeetSDK

class SMRemoteVideoTableViewCell: UITableViewCell {
    
    private let smallVideoView: SMSmallVideoView = {
        let view = SMSmallVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(smallVideoView)
        
        NSLayoutConstraint.activate([
            smallVideoView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            smallVideoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            smallVideoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            smallVideoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            smallVideoView.widthAnchor.constraint(equalTo: smallVideoView.heightAnchor),
        ])
        
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with participant: SMParticipant) {
        smallVideoView.update(with: participant)
    }
}
