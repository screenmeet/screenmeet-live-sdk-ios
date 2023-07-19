//
//  TabbarViewController.swift
//  ScreenMeet
//
//  Created by Rostyslav Stepanyak on 7/10/23.
//

import UIKit

class TabbarViewController: UITabBarController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    

    

}
