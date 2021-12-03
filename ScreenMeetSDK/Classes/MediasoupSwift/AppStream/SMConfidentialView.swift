//
//  SMConfidentialView.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 27.01.2021.
//

import Foundation

class SMConfidentialView {
    
    private weak var view: UIView?
    
    private var lastFramePossitions = [CGRect]()
    
    fileprivate var frame: CGRect? {
        guard let rect = view?.globalRect else { return nil }
        
        if lastFramePossitions.count > 3 {
            lastFramePossitions.removeFirst()
        }
        
        if !lastFramePossitions.contains(rect) {
            lastFramePossitions.append(rect)
        }

        let minX = lastFramePossitions.map { $0.origin.x }.min()!
        let minY = lastFramePossitions.map { $0.origin.y }.min()!
        let maxX = lastFramePossitions.map { $0.origin.x + $0.width }.max()!
        let maxY = lastFramePossitions.map { $0.origin.y + $0.height }.max()!
        
        let width = (maxX - minX)
        let height = (maxY - minY)
        let x = minX
        let y = minY
        
        var confRect = CGRect(x: x, y: y, width: width, height: height)
        
        if !areRectsEqual(lhs: confRect, rhs: rect) {
            confRect.origin.x -= 5
            confRect.origin.y -= 5
            confRect.size.width += 10
            confRect.size.height += 10
        }
        
        return confRect
    }
    
    var isEmpty: Bool {
        view == nil
    }
    
    init(_ view: UIView) {
        self.view = view
    }
    
    private func areRectsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
        guard abs(lhs.origin.x - rhs.origin.x) <= 1 else { return false }
        guard abs(lhs.origin.y - rhs.origin.y) <= 1 else { return false }
        guard abs(lhs.size.width - rhs.size.width) <= 1 else { return false }
        guard abs(lhs.size.height - rhs.size.height) <= 1 else { return false }
        
        return true
    }
    
    static func ==(lhs: SMConfidentialView, rhs: UIView) -> Bool {
        return lhs.view == rhs
    }
}

extension Array where Element == SMConfidentialView {
    
    var operation: SMCalculateFramesOperation {
        ViewOperation(views: self)
    }
    
    class ViewOperation: Operation, SMCalculateFramesOperation {
        
        var views: [SMConfidentialView]
        
        var frames = [CGRect]()
        
        init(views: [SMConfidentialView]) {
            self.views = views
        }
        
        override func main() {
            guard !isCancelled else { return }
            
            var frames = [CGRect]()
            
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async { [unowned self] in
                frames.append(contentsOf: views.compactMap { $0.frame })
                group.leave()
            }
            
            group.wait()
            
            self.frames = frames
        }
    }
}
