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
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gif = UIImage.gifImageWithName("stars")
        gifImageView.image = gif
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
        
        ScreenMeet.config.endpoint = URL(string: "https://edge.screenmeet.com")!
        NotificationCenter.default.addObserver(self, selector: #selector(screenMeetSessionEnd), name: Notification.Name("ScreenMeetSessionEnd"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenMeetUIDidAppear), name: Notification.Name("ScreenMeetUIDidAppear"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenMeetUIWillDisappear), name: Notification.Name("ScreenMeetUIWillDisappear"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ScreenMeet.getAppStreamService().setConfidential(view: connectButton)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ScreenMeet.getAppStreamService().unsetConfidential(view: connectButton)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func screenMeetSessionEnd() {
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
    }
    
    @objc func screenMeetUIDidAppear() {
        ScreenMeet.getAppStreamService().unsetConfidential(view: connectButton)
    }
    
    @objc func screenMeetUIWillDisappear() {
        ScreenMeet.getAppStreamService().setConfidential(view: connectButton)
    }
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        switch ScreenMeet.getConnectionState() {
        case .connected:
            SMMainViewController.presentScreenMeetUI()
        case .connecting:
            print("Connecting...")
        case .reconnecting:
            print("Reconnecting...")
        case .disconnected:
            if let code = codeTextField.text {
                connectButton.setTitle("Connecting...", for: .normal)
                connectButton.isEnabled = false
                codeTextField.isHidden = false
                codeTextField.isEnabled = false
                
                ScreenMeet.delegate = SMUserInterface.manager
                ScreenMeet.connect(code, "Frank") { [weak self] (error) in
                    guard error == nil else {
                        if let challenge = error!.challenge {
                            self?.showCaptchaScreen(challenge)
                        }
                        else {
                            self?.connectButton.setTitle("Connect", for: .normal)
                            self?.connectButton.isEnabled = true
                            self?.codeTextField.isHidden = false
                            self?.codeTextField.isEnabled = true
                            self?.showError(error!)
                        }
                        return
                    }
                    
                    SMMainViewController.presentScreenMeetUI { [weak self] in
                        self?.codeTextField.isHidden = true
                        self?.codeTextField.isEnabled = true
                        self?.connectButton.isEnabled = true
                        self?.connectButton.setTitle("Present ScreenMeet UI", for: .normal)
                    }
                }
            }
        }
    }
    
    private func showError(_ error: SMError) {
        errorLabel.text = error.message
        errorLabel.alpha = 0.0
        errorLabel.isHidden = false
        
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.errorLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            UIView.animate(withDuration: 0.4) {
                self?.errorLabel.alpha = 0.0
            }
        }
    }
    
    private func showCaptchaScreen(_ challenge: SMChallenge) {
        if let captchaViewController = storyboard?.instantiateViewController(identifier: "CaptchaViewController") as? CaptchaViewController {
            
            captchaViewController.isModalInPresentation = true
            captchaViewController.svg = challenge.getSvg()
            captchaViewController.verifyCompletion = { captcha in
                challenge.solve(captcha)
            }
            
            present(captchaViewController, animated: true, completion: nil)
        }
    }
}
