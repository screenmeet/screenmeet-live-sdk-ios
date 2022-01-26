//
//  SMDemoRemoteControlViewController.swift
//  ScreenMeet
//
//  Created by Ross on 20.09.2021.
//

import UIKit

enum DemoRows: Int {
    case TextField1 = 0
    case TextField2
    case TextField3
    case TextView1
    case TextView2
    case Button1
    case Button2
    case Segment1
    case Segment2
    case Filler1
    case Filler2
    case Filler3
    case Filler4
    case Filler5
    case Switch1
    
    case Count
}
class SMDemoRemoteControlNativeFormViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.navigationBar.isHidden = true
        tableView.tableFooterView = UIView()
    }
    
    @objc private func buttonClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "", message: "\(sender.titleLabel!.text!) clicked...", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func switchClicked(_ sender: UISwitch) {
        sender.isOn = !sender.isOn
    }
    
    @objc private func segmentClicked(_ segment: UISegmentedControl) {
        let alert = UIAlertController(title: "", message: "Segment clicked...", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

extension SMDemoRemoteControlNativeFormViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DemoRows.Count.rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?  = nil
        
        if indexPath.row == DemoRows.TextField1.rawValue ||  indexPath.row == DemoRows.TextField2.rawValue ||  indexPath.row == DemoRows.TextField3.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlTextFieldCell", for: indexPath)
        }
        
        if indexPath.row == DemoRows.TextView1.rawValue ||  indexPath.row == DemoRows.TextView2.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlTextViewCell", for: indexPath)
        }
        
        if indexPath.row == DemoRows.Button1.rawValue ||  indexPath.row == DemoRows.Button2.rawValue {
            let buttonCell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlButtonCell", for: indexPath) as! SMDemoRemoteControlButtonCell
            buttonCell.button.setTitle("Button in row \(indexPath.row+1)", for: .normal)
            buttonCell.button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
            cell = buttonCell
        }
        
        if indexPath.row == DemoRows.Switch1.rawValue {
            let switchCell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlSwitchCell", for: indexPath) as! SMDemoRemoteControlSwitchCell
            switchCell.switchControl.addTarget(self, action: #selector(switchClicked), for: .touchUpInside)
            cell = switchCell
        }
        
        if indexPath.row == DemoRows.Segment1.rawValue || indexPath.row == DemoRows.Segment2.rawValue {
            let segmenthCell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlSegmentCell", for: indexPath) as! SMDemoRemoteControlSegmentCell
            segmenthCell.segmentControl.addTarget(self, action: #selector(segmentClicked), for: .valueChanged)
            cell = segmenthCell
        }
        
        if indexPath.row == DemoRows.Filler1.rawValue || indexPath.row == DemoRows.Filler2.rawValue || indexPath.row == DemoRows.Filler3.rawValue || indexPath.row == DemoRows.Filler4.rawValue || indexPath.row == DemoRows.Filler5.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: "SMDemoRemoteControlFillerCell", for: indexPath) as! SMDemoRemoteControlFillerCell
        }
        
        return cell!
    }
    
}
