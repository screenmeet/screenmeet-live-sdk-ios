//
//  UIView+TopmostView.swift
//  ScreenMeetSDK
//
//  Created by Ross on 17.09.2021.
//

import UIKit

struct TopMostData {
    var view: UIView!
    var point: CGPoint!
}

extension UIView {
    func findTopMostViewForPoint(_ point: CGPoint, _ targetUITypes: [AnyClass]) -> TopMostData {
        for i in stride(from: self.subviews.count, to: 0, by: -1) {
            let subview = self.subviews[i-1]
                        
            if !subview.isHidden && subview.frame.contains(point) {
                for type in targetUITypes {
                    if subview.isKind(of: type) {
                       return TopMostData(view: subview, point: point)
                    }
                }
                
                let convertedPoint = self.convert(point, to: subview)
                return subview.findTopMostViewForPoint(convertedPoint, targetUITypes)
            }
        }
        
        return TopMostData(view: self, point: point)
    }
    
    func findTopMostScrollViewForPoint(_ point: CGPoint) -> UIView {
        for i in stride(from: self.subviews.count, to: 0, by: -1) {
            let subview = self.subviews[i-1]
            
            if !subview.isHidden && subview.frame.contains(point) {
                if subview.isKind(of: UIScrollView.self){
                   return subview
                }
                let convertedPoint = self.convert(point, to: subview)
                return subview.findTopMostScrollViewForPoint(convertedPoint)
            }
        }
        
        return self
    }
    
    func findTopMostFocused() -> UIView? {
        for subView: UIView in self.subviews as [UIView] {
            if subView.isFirstResponder {
                return subView
            }
            else {
                if let sub = subView.findTopMostFocused() {
                   return sub
                }
            }
        }
        return nil
    }
}

extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}

