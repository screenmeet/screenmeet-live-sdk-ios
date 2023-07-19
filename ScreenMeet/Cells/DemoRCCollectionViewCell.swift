//
//  DemoRCCollectionViewCell.swift
//  LiveiOSApp
//
//  Created by Rostyslav Stepanyak on 6/7/23.
//

import UIKit

protocol DemoRCCellCollectionViewDelegate {
    func buttonClicked(_ cell: DemoRCCollectionViewCell)
}

class DemoRCCollectionViewCell: UICollectionViewCell {
    var delegate: DemoRCCellCollectionViewDelegate?
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected {
                self.backgroundColor = .gray
            } else {
                self.backgroundColor = .clear
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        delegate?.buttonClicked(self)
    }
}
