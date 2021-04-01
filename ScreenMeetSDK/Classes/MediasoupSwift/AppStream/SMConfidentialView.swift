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
        
        lastFramePossitions.append(rect)

        let minX = lastFramePossitions.map { $0.origin.x }.min()!
        let minY = lastFramePossitions.map { $0.origin.y }.min()!
        let maxX = lastFramePossitions.map { $0.origin.x + $0.width }.max()!
        let maxY = lastFramePossitions.map { $0.origin.y + $0.height }.max()!
        
        let width = (maxX - minX)
        let height = (maxY - minY)
        let x = minX
        let y = minY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    var isEmpty: Bool {
        view == nil
    }
    
    init(_ view: UIView) {
        self.view = view
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
