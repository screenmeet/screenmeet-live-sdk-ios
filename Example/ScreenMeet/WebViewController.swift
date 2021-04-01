//
//  WebViewController.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 11.03.2021.
//

import UIKit
import WebKit
import ScreenMeetSDK

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "https://stackoverflow.com/users/login?ssrc=head&returnurl=https%3a%2f%2fstackoverflow.com%2f") {
            webView.load(URLRequest(url: url))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenMeet.getAppStreamService().setConfidential(webView: webView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ScreenMeet.getAppStreamService().unsetConfidential(webView: webView)
    }
    
    @IBAction func back(sender: Any) {
        if (self.webView.canGoBack) {
            self.webView.goBack()
        }
    }

    @IBAction func forward(sender: Any) {
        if (self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
}
