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
    
    @IBOutlet weak var connectButton: TransitionButton!
    
    @IBOutlet weak var waitingView: UIView!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gif = UIImage.gifImageWithName("mushrooms")
        gifImageView.image = gif
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        codeTextField.attributedPlaceholder = NSAttributedString(string: "Room code",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
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
        case .waitingEntrancePermission:
            print("Waiting for host to let us in")
        case .disconnected:
            if let code = codeTextField.text {
                connectButton.startAnimation()
                connectButton.isEnabled = false
                codeTextField.isHidden = false
                codeTextField.isEnabled = false
                waitingView.isHidden = true
                
                ScreenMeet.delegate = SMUserInterface.manager
                ScreenMeet.connect(code, "Frank") { [weak self] (error) in
                    guard error == nil else {
                        if let challenge = error!.challenge {
                            self?.showCaptchaScreen(challenge)
                        }
                        else if error!.code == .knockEntryPermissionRequiredError {
                            // Knock is on, host has to let you in, just show an error and wait for success completion in case we are let in
                            self?.waitingView.isHidden = false
                            self?.showError(error!)
                        }
                        else if error!.code == .knockWaitTimeForEntryExpiredError {
                            self?.connectButton.stopAnimation(animationStyle: .shake)
                            self?.connectButton.setTitleColor(.white, for: .normal)
                            self?.connectButton.isEnabled = true
                            self?.codeTextField.isHidden = false
                            self?.codeTextField.isEnabled = true
                            self?.waitingView.isHidden = true
                            self?.showError(error!)
                        }
                        else {
                            self?.connectButton.stopAnimation()
                            self?.connectButton.setTitleColor(.white, for: .normal)
                            self?.connectButton.isEnabled = true
                            self?.codeTextField.isHidden = false
                            self?.codeTextField.isEnabled = true
                            self?.waitingView.isHidden = true
                            self?.showError(error!)
                        }
                        return
                    }
                    
                    self?.connectButton.stopAnimation(animationStyle: .expand, revertAfterDelay: 1.0, completion: {
                        self?.waitingView.isHidden = true
                        
                        SMMainViewController.presentScreenMeetUI { [weak self] in
                            self?.codeTextField.isHidden = true
                            self?.codeTextField.isEnabled = true
                            self?.connectButton.isEnabled = true
                            self?.connectButton.setTitle("Present ScreenMeet UI", for: .normal)
                            self?.connectButton.setTitleColor(.white, for: .normal)
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func quitWaitingButtonTapped(_ sender: UIButton) {
        ScreenMeet.disconnect()
        
        connectButton.stopAnimation()
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.isEnabled = true
        codeTextField.isHidden = false
        codeTextField.isEnabled = true
        waitingView.isHidden = true
    }
    
    private func showError(_ error: SMError) {
        
        var message = error.message
        if (error.code == .httpError(.notFound)) {
            message = "Could not find the room with such id..."
        }
        
        errorLabel.text = message
        errorLabel.alpha = 0.0
        errorLabel.isHidden = false
        
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.errorLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
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
    
    @objc private func dismissKeyboard() {
        codeTextField.endEditing(true)
    }
}
