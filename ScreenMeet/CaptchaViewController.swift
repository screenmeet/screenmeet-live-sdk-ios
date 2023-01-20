//
//  CaptchaViewController.swift
//  ScreenMeet
//
//  Created by Ross on 11.04.2021.
//

import UIKit
import WebKit

typealias CaptchaCompletion = (String) -> Void

class CaptchaViewController: UIViewController {
    private let CAPTCHA_LENGTH = 4
    
    var svg: String = ""
    var verifyCompletion: CaptchaCompletion?

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var captchaTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSvg()
    }

    @IBAction func verifyButtonClicked() {
        verifyCompletion?(captchaTextField.text!)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func captchaTextFieldTextChanged() {
        validateVerifyButton()
    }
    
    private func setupSvg() {
        let html = "<!DOCTYPE html><html style=\"overflow: hidden\"><head><meta name=\"viewport\" content=\"width=device-width, shrink-to-fit=NO\"></head><body><div style=\"width: 100%; margin: 0px auto;\">" + svg + "</div></body></html>"
        //webView.contentScaleFactor = 2.0
        webView.contentMode = .scaleAspectFill
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func validateVerifyButton() {
        let numberCharacters = NSCharacterSet.decimalDigits.inverted
        
        if captchaTextField.text!.count == CAPTCHA_LENGTH && captchaTextField.text!.rangeOfCharacter(from: numberCharacters) == nil {
            verifyButton.isEnabled = true
            verifyButton.backgroundColor = UIColor(red: 0.0, green: 117.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        }
        else {
            verifyButton.isEnabled = false
            verifyButton.backgroundColor = UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        }
    }

}
