//
//  SMLaserPointerService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 05.07.2021.
//

import Foundation

enum SMLaserPointerServiceError: Error {
    case laserPointerSessionAlreadyExists(requestorId: String)
}

final class SMLaserPointer {
    
    var id: String
    
    var color: UIColor {
        didSet {
            imageView.color = color
            imageView.size = .regular
        }
    }
    
    private var position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    
    private var imageView: ImageView = {
        let imageView = ImageView()
        imageView.clipsToBounds = true
        imageView.isHidden = true
        
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private class ImageView: UIImageView {
        
        var size: Size = .regular {
            didSet {
                let center = self.center
                frame.size = CGSize(width: size.rawValue, height: size.rawValue)
                self.center = center
                layer.cornerRadius = (frame.width / 2)
                
                switch size {
                case .regular:
                    backgroundColor = color.withAlphaComponent(0.7)
                case .tapped:
                    backgroundColor = color
                }
            }
        }
        
        var color: UIColor = .red
        
        enum Size: CGFloat {
            case regular = 20
            case tapped = 30
        }
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return false
        }
    }
    
    init(id: String, color: UIColor) {
        self.id = id
        self.color = color
        imageView.color = color
        imageView.size = .regular
        if let window = UIApplication.shared.windows.first {
            window.backgroundColor = .black
            if !imageView.isDescendant(of: window) {
                window.addSubview(imageView)
            }
            window.bringSubviewToFront(imageView)
        }
    }
    
    func reload() {
        UIApplication.shared.windows.first?.bringSubviewToFront(imageView)
        UIView.animate(withDuration: 0.1, animations: { [unowned self] in
            imageView.center = position
        })
    }
    
    func update(position: CGPoint) {
        self.position.x = max(0, min(position.x, UIScreen.main.bounds.width))
        self.position.y = max(0, min(position.y, UIScreen.main.bounds.height))
        imageView.isHidden = false
    }
    
    func updateTap() {
        UIView.animate(withDuration: 0.2, animations: { [unowned self] in
            imageView.size = .tapped
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                imageView.size = .regular
            })
        }
    }
    
    deinit {
        imageView.removeFromSuperview()
    }
}

final class SMLaserPointerService {
    
    private var timer: Timer? = nil
    
    private var laserPointers = [SMLaserPointer]()
    
    private var colors: Set<UIColor> = [.red, .blue, .green, .yellow, .purple, .brown, .cyan, .magenta, .orange]
    
    func startLaserPointerSession(for requestorId: String) throws {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [unowned self] _ in
                laserPointers.forEach { laserPointer in
                    laserPointer.reload()
                }
            }
        }
        
        if !laserPointers.contains(where: { $0.id == requestorId }) {
            let color = colors.randomElement() ?? .red
            colors.remove(color)
            laserPointers.append(SMLaserPointer(id: requestorId, color: color))
        } else {
            throw SMLaserPointerServiceError.laserPointerSessionAlreadyExists(requestorId: requestorId)
        }
    }
    
    func stopLaserPointerSession(for requestorId: String) {
        guard let index = laserPointers.firstIndex(where: { $0.id == requestorId }) else { return }
        let laserPointer = laserPointers.remove(at: index)
        colors.insert(laserPointer.color)
        
        if laserPointers.count == 0 {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func stopAllLaserPointerSessions() {
        colors = [.red, .blue, .green, .yellow, .purple, .brown, .cyan, .magenta, .orange]
        laserPointers.removeAll()
        timer?.invalidate()
        timer = nil
    }
    
    func updateLaserPointer(position: CGPoint, for requestorId: String) {
        laserPointers.first(where: { $0.id == requestorId })?.update(position: position)
    }
    
    func updateLaserPointerTap(for requestorId: String) {
        laserPointers.first(where: { $0.id == requestorId })?.updateTap()
    }
}
