//
//  MainViewController.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 09.03.2021.
//

import UIKit
import AVFoundation
import ScreenMeetSDK

class MainViewController: UIViewController {
    
    @IBOutlet weak var gifImageView: UIImageView!
    
    @IBOutlet weak var codeTextField: UITextField!
    
    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gif = UIImage.gifImageWithName("stars")
        gifImageView.image = gif
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenMeetSessionEnd), name: Notification.Name("ScreenMeetSessionEnd"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func checkDevicePermissions(completion: @escaping ((Bool) -> Void)) {
        // Camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (isGranted) in
                completion(isGranted)
            })
        } else {
            completion(true)
        }
    }
    
    @objc func screenMeetSessionEnd() {
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
    }
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        switch ScreenMeet.getConnectionState() {
        case .connected:
            SMMainViewController.presentScreenMeetUI()
        case .connecting:
            print("Connecting...")
        case .disconnected:
            checkDevicePermissions { [weak self] (isGranted) in
                if isGranted, let code = self?.codeTextField.text {
                    self?.connectButton.setTitle("Connecting...", for: .normal)
                    self?.connectButton.isEnabled = false
                    self?.codeTextField.isHidden = false
                    self?.codeTextField.isEnabled = false
                    
                    ScreenMeet.delegate = SMUserInterface.manager
                    ScreenMeet.connect(code, .frontCamera) { (error) in
                        guard error == nil else {
                            self?.connectButton.setTitle("Connect", for: .normal)
                            self?.connectButton.isEnabled = true
                            self?.codeTextField.isHidden = false
                            self?.codeTextField.isEnabled = true
                            return
                        }
                        
                        SMMainViewController.presentScreenMeetUI {
                            self?.codeTextField.isHidden = true
                            self?.codeTextField.isEnabled = true
                            self?.connectButton.isEnabled = true
                            self?.connectButton.setTitle("Present ScreenMeet UI", for: .normal)
                        }
                    }
                }
            }
        }
    }
}
