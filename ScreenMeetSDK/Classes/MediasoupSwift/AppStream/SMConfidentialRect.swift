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
        rect == nil
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
