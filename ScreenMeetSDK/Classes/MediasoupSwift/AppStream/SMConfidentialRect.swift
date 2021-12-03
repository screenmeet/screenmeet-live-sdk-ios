//
//  SMConfidentialRect.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 13.05.2021.
//

import Foundation

class SMConfidentialRect {
    
    private var rect: CGRect?
    
    private var lastFramePossitions = [CGRect]()
    
    fileprivate var frame: CGRect? {
        guard let rect = rect else { return nil }
        
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
        rect == nil
    }
    
    private func areRectsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
        guard abs(lhs.origin.x - rhs.origin.x) <= 1 else { return false }
        guard abs(lhs.origin.y - rhs.origin.y) <= 1 else { return false }
        guard abs(lhs.size.width - rhs.size.width) <= 1 else { return false }
        guard abs(lhs.size.height - rhs.size.height) <= 1 else { return false }
        
        return true
    }
    
    init(_ rect: CGRect) {
        self.rect = rect
    }
    
    static func ==(lhs: SMConfidentialRect, rhs: CGRect) -> Bool {
        return lhs.rect == rhs
    }
}

extension Array where Element == SMConfidentialRect {
    
    var operation: SMCalculateFramesOperation {
        RectOperation(rects: self)
    }
    
    class RectOperation: Operation, SMCalculateFramesOperation {
        
        var rects: [SMConfidentialRect]
        
        var frames = [CGRect]()
        
        init(rects: [SMConfidentialRect]) {
            self.rects = rects
        }
        
        override func main() {
            guard !isCancelled else { return }
            
            var frames = [CGRect]()
            
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async { [unowned self] in
                frames.append(contentsOf: rects.compactMap { $0.frame })
                group.leave()
            }
            
            group.wait()
            
            self.frames = frames
        }
    }
}
