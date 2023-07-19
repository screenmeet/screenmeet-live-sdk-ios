//
//  DemoRCViewController.swift
//  LiveiOSApp
//
//  Created by Rostyslav Stepanyak on 6/1/23.
//

import UIKit


public typealias PresentingCallback = (UIViewController) -> Void

class DemoRCViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var presentingCallback: PresentingCallback? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.allowsSelection = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }
    
}

extension DemoRCViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        //let cell = tableView.cellForRow(at: indexPath)
        //cell?.isSelected = true
        NSLog("Row: \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //let cell = tableView.cellForRow(at: indexPath)
        //cell?.isSelected = false
        NSLog("Row: \(indexPath.row)")
    }
}

extension DemoRCViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoRCCell", for: indexPath) as! DemoRCCell
        cell.label.text = "Cell \(indexPath.row)"
        cell.delegate = self
        return cell
    }
    
}

extension DemoRCViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DemoRCCollectionViewCell", for: indexPath) as! DemoRCCollectionViewCell
        cell.label.text = "Cell \(indexPath.row)"
        cell.delegate = self
        return cell
    }
}

extension DemoRCViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension DemoRCViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 200)
    }
}


extension DemoRCViewController: DemoRCCellDelegate {
    func buttonClicked(_ cell: DemoRCCell) {
        let text = cell.label.text
        
        let alertController: UIAlertController = UIAlertController(title:nil, message:text, preferredStyle:.alert)
        alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { [weak self] action in
            self?.presentingCallback?(self!)
        }))
        
        presentingCallback?(alertController)
        present(alertController, animated:true, completion:nil)
    }
}

extension DemoRCViewController: DemoRCCellCollectionViewDelegate {
    func buttonClicked(_ cell: DemoRCCollectionViewCell) {
        let text = cell.label.text
        
        let alertController: UIAlertController = UIAlertController(title:nil, message:text, preferredStyle:.alert)
        alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { [weak self] action in
            self?.presentingCallback?(self!)
        }))
        
        present(alertController, animated:true, completion:nil)
        
        presentingCallback?(alertController)
    }
}
