//
//  RemoteParticipantCell.swift
//  DemoiOS
//
//  Created by Ross on 14.10.2022.
//

import UIKit

class RemoteParticipantCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var micIcon: UIImageView!
    @IBOutlet weak var micBackgroundView: UIView!
    @IBOutlet weak var nameLabelbackgroundView: UIView!
    @IBOutlet weak var nameBackgroundLefMargin: NSLayoutConstraint!
    
    @IBOutlet weak var youAreSharingScreenOverlayView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var videoContainerView: UIView!
    
    
}
