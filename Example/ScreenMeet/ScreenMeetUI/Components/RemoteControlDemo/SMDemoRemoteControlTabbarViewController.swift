//
//  SMDemoTabbarViewController.swift
//  ScreenMeet
//
//  Created by Ross on 21.12.2021.
//

import UIKit
import ScreenMeetSDK

class SMDemoRemoteControlTabbarViewController: UITabBarController {

    private var remoteControlFeature: SMFeature?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteControlFeature = ScreenMeet.activeFeatures().first(where: { feature in
            feature.type == .remotecontrol
        })
        
        if remoteControlFeature != nil {
            setupStopNavigationButton()
        }

    }
    

    private func setupStopNavigationButton() {
        let stopButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 25))
        stopButton.setTitle("Stop", for: .normal)
        stopButton.backgroundColor = .red
        stopButton.layer.cornerRadius = 4.0
        stopButton.layer.masksToBounds = true
        stopButton.titleLabel?.textColor = .white
        stopButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 14)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: stopButton)]

    }
    
    @objc private func stopTapped() {
        if let remoteControlFeature = remoteControlFeature {
            ScreenMeet.stopFeature(remoteControlFeature)
            
            navigationController?.popViewController(animated: true)
        }
        
    }

}
