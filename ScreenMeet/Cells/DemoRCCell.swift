//
//  DemoRCCell.swift
//  LiveiOSApp
//
//  Created by Rostyslav Stepanyak on 6/1/23.
//

import UIKit

protocol DemoRCCellDelegate {
    func buttonClicked(_ cell: DemoRCCell)
}

class DemoRCCell: UITableViewCell {
    var delegate: DemoRCCellDelegate?
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        delegate?.buttonClicked(self)
    }
}
