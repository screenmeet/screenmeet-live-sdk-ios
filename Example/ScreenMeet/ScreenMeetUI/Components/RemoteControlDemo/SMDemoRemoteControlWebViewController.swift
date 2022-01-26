//
//  SMDemoRemoteControlWebViewController.swift
//  ScreenMeet
//
//  Created by Ross on 14.12.2021.
//

import UIKit
import WebKit

class SMDemoRemoteControlWebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.load(NSURLRequest(url: NSURL(string: "https://forms.gle/fzGxbKXMwrNkysSy8")! as URL) as URLRequest)
    }
}
