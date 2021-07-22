//
//  SMLaserPointerService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 31.03.2021.
//

import Foundation

final class SMLaserPointerService {
    
    private var laserPointerCoorX = UIScreen.main.bounds.width / 2
    
    private var laserPointerCoorY = UIScreen.main.bounds.height / 2
    
    private static let laserPointerSize: CGFloat = 20
    
    private static let laserPointerTapSize: CGFloat = 30
    
    private var laserPointerImage = LaserPointerImageView(frame: CGRect(x: 0, y: 0, width: SMLaserPointerService.laserPointerSize, height: SMLaserPointerService.laserPointerSize))
    
    private var laserPointerTimer: Timer? = nil
    
    func startLaserPointerSession() {
        if laserPointerTimer == nil {
            self.laserPointerImage.setRounded()
            laserPointerTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [unowned self] _ in
                if let window = UIApplication.shared.keyWindow {
                    window.backgroundColor = .black
                    self.laserPointerImage.center = CGPoint(x: self.laserPointerCoorX, y: self.laserPointerCoorY)
                    if !laserPointerImage.isDescendant(of: window) {
                        window.addSubview(self.laserPointerImage)
                    }
                    window.bringSubviewToFront(self.laserPointerImage)
                }
            }
        } else {
            print("Laser pointer session already started")
        }
    }
    
    func updateLaserPointerCoors(_ point: CGPoint) {
        if point.x < 0 {
            self.laserPointerCoorX = 0
        } else if point.x > UIScreen.main.bounds.width {
            self.laserPointerCoorX = UIScreen.main.bounds.width
        } else {
            self.laserPointerCoorX = point.x
        }
        
        if point.y < 0 {
            self.laserPointerCoorY = 0
        } else if point.y > UIScreen.main.bounds.height {
            self.laserPointerCoorY = UIScreen.main.bounds.height
        } else {
            self.laserPointerCoorY = point.y
        }
    }

    func updateLaserPointerCoorsWithTap() {
        UIView.animate(withDuration: 0.3, animations: {
            self.laserPointerImage.frame.size.width = SMLaserPointerService.laserPointerTapSize
            self.laserPointerImage.frame.size.height = SMLaserPointerService.laserPointerTapSize
            self.laserPointerImage.frame.origin.x = self.laserPointerCoorX - SMLaserPointerService.laserPointerTapSize / 2
            self.laserPointerImage.frame.origin.y = self.laserPointerCoorY - SMLaserPointerService.laserPointerTapSize / 2
            self.laserPointerImage.layer.backgroundColor = UIColor.red.withAlphaComponent(1).cgColor
            self.laserPointerImage.layoutIfNeeded()
        }) {_ in
            UIView.animate(withDuration: 0.3, animations: {
                self.laserPointerImage.frame.size.width = SMLaserPointerService.laserPointerSize
                self.laserPointerImage.frame.size.height = SMLaserPointerService.laserPointerSize
                self.laserPointerImage.frame.origin.x = self.laserPointerCoorX - SMLaserPointerService.laserPointerSize / 2
                self.laserPointerImage.frame.origin.y = self.laserPointerCoorY - SMLaserPointerService.laserPointerSize / 2
                self.laserPointerImage.layer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
                self.laserPointerImage.layoutIfNeeded()
            })
        }
    }

    func stopLaserPointerSession() {
        if laserPointerTimer == nil {
            print("Laser pointer session already stoped")
        } else {
            self.laserPointerImage.removeFromSuperview()
            laserPointerTimer?.invalidate()
            laserPointerTimer = nil
        }
    }
}

fileprivate final class LaserPointerImageView: UIImageView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
    
    func setRounded() {
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
        self.clipsToBounds = true
        self.layer.cornerRadius = (self.frame.width / 2)
        self.layer.masksToBounds = true
    }
}
