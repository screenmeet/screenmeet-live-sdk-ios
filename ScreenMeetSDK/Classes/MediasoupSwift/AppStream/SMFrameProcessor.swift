//
//  SMFrameProcessor.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 22.01.2021.
//

import Foundation

class SMFrameProcessor {
    
    var confidentialViews = [SMConfidentialView]()
    
    var confidentialWebViews = [SMConfidentialWebView]()
    
    var confidentialRects = [SMConfidentialRect]()
    
    private lazy var calculateFramesQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Calculate Frames Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private let ciContext: CIContext = CIContext(options: nil)
    
    private var overlayImage = UIImage(color: .red)
    
    private func overlay(rect: CGRect, over image: CIImage) -> CIImage {
        guard let overlayCIImage = CIImage(image: overlayImage) else { return image }
        guard let cropFilter = CIFilter(name: "CICrop") else { return image }
        
        cropFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: rect), forKey: "inputRectangle")
        
        guard let overCompositingFilter = CIFilter(name: "CISourceOverCompositing") else { return image }
        
        overCompositingFilter.setValue(cropFilter.outputImage, forKey: kCIInputImageKey)
        overCompositingFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        guard let outputImage = overCompositingFilter.outputImage else { return image }
        
        return outputImage
    }
    
    func processFrame(pixelBuffer: CVPixelBuffer, completion: @escaping (CVPixelBuffer) -> Void) {
        var confidentialFrames = [CGRect]()
        var dependencyCount = 0
        let calculateFramesOperations = [confidentialWebViews.operation, confidentialViews.operation, confidentialRects.operation]
        
        calculateFramesOperations.forEach { [unowned self] calculateFramesOperation in
            calculateFramesOperation.completionBlock = {
                confidentialFrames.append(contentsOf: calculateFramesOperation.frames)
                dependencyCount += 1
                
                if dependencyCount == calculateFramesOperations.count {
                    guard confidentialFrames.count > 0 else {
                        completion(pixelBuffer)
                        return
                    }
                    
                    let ciImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
                    var outputImage: CIImage = ciImage
                    
                    let wScale = ciImage.extent.width / UIScreen.main.bounds.size.width
                    let hScale = ciImage.extent.height / UIScreen.main.bounds.size.height
                    
                    confidentialFrames.forEach { rect in
                        let width = rect.width * wScale
                        let height = rect.height * hScale
                        let x = rect.origin.x * wScale
                        let y = ciImage.extent.height - height - (rect.origin.y * hScale)
                        
                        let rect = CGRect(x: x, y: y, width: width, height: height)
                        
                        outputImage = overlay(rect: rect, over: outputImage)
                    }
                    
                    ciContext.render(outputImage, to: pixelBuffer)
                    
                    completion(pixelBuffer)
                }
            }
        }
        
        calculateFramesQueue.addOperations(calculateFramesOperations, waitUntilFinished: false)
    }
}

protocol SMCalculateFramesOperation: Operation {
    
    var frames: [CGRect] { get }
}

extension UIView {
    
    var globalRect: CGRect? {
        guard let origin = self.layer.presentation()?.frame.origin,
            let globalPoint = self.superview?.layer.presentation()?.convert(origin, to: nil) else { return nil }
        return CGRect(origin: globalPoint, size: self.frame.size)
    }
    
    var globalTransform: CATransform3D? {
        guard let presentation = self.layer.presentation() else { return nil }
        return presentation.transform
    }
}

extension UIImage {
    
    convenience init(color: UIColor) {
        let rect = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.init(cgImage: image!.cgImage!)
    }
}
