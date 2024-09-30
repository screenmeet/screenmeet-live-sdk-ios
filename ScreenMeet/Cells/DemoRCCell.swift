//
//  DemoRCCell.swift
//  LiveiOSApp
//
//  Created by Rostyslav Stepanyak on 6/1/23.
//

import UIKit
import ScreenMeetLive

protocol DemoRCCellDelegate {
    func buttonClicked(_ cell: DemoRCCell)
}

class DemoRCCell: UITableViewCell {
    var delegate: DemoRCCellDelegate?
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tap.cancelsTouchesInView = false
        button.addGestureRecognizer(tap)
    }
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        delegate?.buttonClicked(self)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
       
        /* Handle your click here as usual*/
        // doSomeAction()
    
        
        
        /* Few additional points: */
         
        /* 1. The states of the UIGestureRecognize should be correct and you can use them*/
        if sender.state == .ended { }
        else if sender.state == .began {}
        
        /* 2. A way to get the coordinate of the touch:
         
            Due to apple security reasons ScreenMeetSDK can't create proper UITouch objects during remote control.
            So sender.location(ofTouch: touch , in: view) will not work.
            All the UITouch objects delivered in UIGestureRecognizerEvents during remote control are just empty objects.
            In a regular, manual click they will work as expecte but for remote control
            we set the touch coordinate into the name of the recognizer
         */
        
        let isRemoteControlPermissions = ScreenMeet.grantedFeatureRequests().first { $0.privilege == SMFeature.remoteControl.rawValue }
        let isRemoteControlOn = isRemoteControlPermissions != nil

        if isRemoteControlOn, let coordinates = sender.name?.components(separatedBy: ",") {
            let x = CGFloat((coordinates[0] as NSString).floatValue)
            let y = CGFloat((coordinates[1] as NSString).floatValue)
            let pointInTargetView = CGPoint(x: x, y: y) // this is a point of touch in the target view (in a view you added the recognizer to)
            NSLog("Point in target view: (\(pointInTargetView.x), \(pointInTargetView.y))")
            
            /* Now you can convert this point to know the location of the touch in other views. Like in you super view for example in case you are using it to trigger a sliding panel*/
            
            button.superview?.convert(pointInTargetView, from: button)
        }
        else {
            /* hanlde everything as usual if remote control is off*/
        }
    }
}
