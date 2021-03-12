//
//  SMOptionViewController.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 09.03.2021.
//

import UIKit
import ScreenMeetSDK

class SMOptionViewController: UIViewController {
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SMParticipantsTableViewCell.self, forCellReuseIdentifier: "SMParticipantsTableViewCell")
        return tableView
    }()
    
    var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = label.font.withSize(18)
        label.text = "Call Participants"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView()
        view.backgroundColor = tableView.backgroundColor

        tableView.dataSource = self
        view.addSubview(tableView)
        view.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    func reloadContent() {
        tableView.reloadData()
    }
}

extension SMOptionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ScreenMeet.getParticipants().count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SMParticipantsTableViewCell", for: indexPath) as! SMParticipantsTableViewCell
        let participants = ScreenMeet.getParticipants()
        if indexPath.row == 0 {
            cell.setup(with: "Me", audioState: SMUserInterface.manager.isAudioEnabled, videoState: SMUserInterface.manager.isVideoEnabled)
        } else {
            cell.setup(with: participants[indexPath.row - 1])
        }
        return cell
    }
}
