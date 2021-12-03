//
//  SMRemoteControlService.swift
//  ScreenMeetSDK
//
//  Created by Ross on 17.09.2021.
//

import UIKit
import WebKit

class SMRemoteControlService: NSObject {
    
    private var isPointerAnimationRunning = false
    private var started = false
    
    private var scrollThreshold: CGFloat = 6.0
    private var isDown = false
    
    private var currentTextField: UITextField? = nil
    private var currentTextView: UITextView? = nil
    
    private var startPoint: CGPoint = .zero
    private var endPoint: CGPoint = .zero
    private var movePoint: CGPoint = .zero
    
    /* The view the touch down is being performed upon*/
    private var startView: UIView? = nil
    
    /* The view the move touch isbeing performed upon*/
    private var moveView: UIView? = nil
    
    /* The view the touch up is being performed upon*/
    private var endView: UIView? = nil
    
    private var targetUITypes: [AnyClass] = [UITextView.self, UITextField.self, UIButton.self, UISwitch.self, WKWebView.self]

    func processEvent(_ event: SMRemoteControlEvent) {
        if let mouseEvent = event as? SMRemoteControlMouseEvent {
            if mouseEvent.type == .leftdown {
                evaluateStartTouch(mouseEvent)
            }
            if mouseEvent.type == .move {
                evaluateMove(mouseEvent)
            }
            if mouseEvent.type == .leftup {
                evaluateEndTouch(mouseEvent)
            }
        }
        
        if let keyboardEvent = event as? SMRemoteControlKeyboardEvent {
            if keyboardEvent.type == .keyup {
                evaluateKeyboard(keyboardEvent)
            }
        }
        
        ScreenMeet.session.delegate?.onRemoteControlEvent(event)
    }
    
    private func evaluateStartTouch(_ event: SMRemoteControlMouseEvent) {
        if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
            
            isDown = true
            
            let point = convertPointFromPossiblePresentingViewController(event, rootViewController)
            startView = rootViewController.view.findTopMostViewForPoint(point, targetUITypes)
            startPoint = point
        }
    }
    
    private func evaluateEndTouch(_ event: SMRemoteControlMouseEvent) {
        if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
            isDown = false
            
            let point = convertPointFromPossiblePresentingViewController(event, rootViewController)
        
            endView = rootViewController.view.findTopMostViewForPoint(point, targetUITypes)
            endPoint = point
                    
            if let startView = startView, let endView = endView {
                if startView == endView {
                    if isViewOfTargetType(endView) {
                        actuate(endView)
                        showPulsingCircle(point)
                    }
                    else {
                        // do nothing for now
                    }
                }
            }
        }
    }
    
    private func evaluateMove(_ event: SMRemoteControlMouseEvent) {
        if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
            let point = convertPointFromPossiblePresentingViewController(event, rootViewController)
        
            moveView = rootViewController.view.findTopMostViewForPoint(point, targetUITypes)
            movePoint = point
            
            if isDown {
                let horizontalDistance = abs(movePoint.x - startPoint.x)
                let verticalDistance = movePoint.y - startPoint.y
                if abs(horizontalDistance) > scrollThreshold || abs(verticalDistance) > scrollThreshold{
                    if let scrollView = rootViewController.view.findTopMostScrollViewForPoint(point) as? UIScrollView {
                        
                        if horizontalDistance < 0 {
                            var distance = abs(horizontalDistance)
                            
                            if scrollView.contentOffset.x <= scrollView.contentSize.width - scrollView.bounds.size.width {
                                if scrollView.contentOffset.x + scrollView.bounds.size.width + distance > scrollView.contentSize.width {
                                    distance = scrollView.contentSize.width - (scrollView.contentOffset.x + scrollView.bounds.size.width)-1
                                }
                                scrollView.contentOffset.x = scrollView.contentOffset.x + distance
                            }
                        }
                        else {
                            if scrollView.contentOffset.x > 0 {
                                var distance = horizontalDistance
                                
                                if distance > scrollView.contentOffset.x {
                                    distance = scrollView.contentOffset.x
                                }
                                scrollView.contentOffset.x = scrollView.contentOffset.x - distance
                            }
                        }
                        
                        if verticalDistance < 0 {
                            var distance = abs(verticalDistance)
                            
                            if scrollView.contentOffset.y <= scrollView.contentSize.height - scrollView.bounds.size.height {
                                if scrollView.contentOffset.y + scrollView.bounds.size.height + distance > scrollView.contentSize.height {
                                    distance = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.size.height)-1
                                }
                                scrollView.contentOffset.y = scrollView.contentOffset.y + distance
                            }
                        }
                        else {
                            if scrollView.contentOffset.y > 0 {
                                var distance = verticalDistance
                                
                                if distance > scrollView.contentOffset.y {
                                    distance = scrollView.contentOffset.y
                                }
                                scrollView.contentOffset.y = scrollView.contentOffset.y - distance
                            }
                        }
                        
                        startPoint = movePoint
                    }
                }
            }
        }
    }
    
    private func convertPointFromPossiblePresentingViewController(_ event: SMRemoteControlMouseEvent, _ rootViewController: UIViewController) -> CGPoint {
        var point = CGPoint(x: event.x, y: event.y)
        
        if let w = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            if rootViewController.presentingViewController != nil {
                point = w.convert(point, to: rootViewController.view)
            }
        }

        return point
    }
    
    private func isViewOfTargetType(_ view:  UIView) -> Bool {
        for type in targetUITypes  {
            if view.isKind(of: type) {
                return true
            }
        }
        
        return false
    }
    
    private func actuate(_ view: UIView) {
        if view.isKind(of: UITextField.self) {
            view.becomeFirstResponder()
            
            currentTextView = nil
            currentTextField = view as? UITextField
            
        }
        else if view.isKind(of: UITextView.self) {
            view.becomeFirstResponder()
            
            currentTextView = view as? UITextView
            currentTextField = nil
        }
        else if view.isKind(of: UIButton.self) {
            (view as! UIButton).sendActions(for: .touchUpInside)
        }
        
        else if view.isKind(of: UISwitch.self) {
            (view as! UISwitch).sendActions(for: .touchUpInside)
        }
        else if view.isKind(of: WKWebView.self) {
            let webView = (view as! WKWebView)
            
            if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
                let p = rootViewController.view.convert(endPoint, to: webView)
                let clientX = p.x
                let clientY = p.y
                
                webView.evaluateJavaScript("var evt = new MouseEvent(\"click\", { button: 1, view: window, bubbles: true, cancelable: true, clientX: \(clientX), clientY: \(clientY)}); document.elementFromPoint(\(clientX), \(clientY)).dispatchEvent(evt);") { result, error in
                    //print(result)
                }
                
                webView.evaluateJavaScript("document.elementFromPoint(\(clientX), \(clientY)).focus()") { result, error in
                    //print(result)
                }
                
                webView.evaluateJavaScript("document.elementFromPoint(\(clientX), \(clientY)).click()") { result, error in
                    //print(result)
                }
                
            }
        }
    }
    
    private func evaluateKeyboard(_ event: SMRemoteControlKeyboardEvent) {
        
        if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
            let topmostFocused = rootViewController.view.findTopMostFocused()
            
            if let textView = topmostFocused as? UITextView {
                currentTextView = textView
            }
            if let textField = topmostFocused as? UITextField {
                currentTextField = textField
            }
        }
       
        if let textView = currentTextView {
            textView.text = modifyTextUsingEvent(textView.text, event)
        }
        if let textField = currentTextField {
            textField.text = modifyTextUsingEvent(textField.text!, event)
        }
        
        if let webView = endView as? WKWebView {
            if event.key.count == 1 {
                    webView.evaluateJavaScript("""
                        function isTextBox(element) {
                            var tagName = element.tagName.toLowerCase();
                            if (tagName === 'textarea') return true;
                            if (tagName !== 'input') return false;
                            var type = element.getAttribute('type').toLowerCase(),
                            inputTypes = ['text', 'password', 'number', 'email', 'tel', 'url', 'search', 'date', 'datetime', 'datetime-local', 'time', 'month', 'week']
                            return inputTypes.indexOf(type) >= 0;
                        }
                        if (isTextBox(document.activeElement)) {
                             document.activeElement.value = document.activeElement.value + "\(event.key)";
                             document.activeElement.dispatchEvent(new Event('change'));
                             document.activeElement.dispatchEvent(new Event('input', { bubbles: true }));
                             document.activeElement.dispatchEvent(new Event('keypress', { bubbles: true }));
                             document.activeElement.dispatchEvent(new KeyboardEvent('keydown', {'key':'Shift'} ));
                        }
                    """) { result, error in
                        
                    }
            }
            else if event.key.lowercased() == "backspace" {
                webView.evaluateJavaScript("""
                    function isTextBox(element) {
                        var tagName = element.tagName.toLowerCase();
                        if (tagName === 'textarea') return true;
                        if (tagName !== 'input') return false;
                        var type = element.getAttribute('type').toLowerCase(),
                        inputTypes = ['text', 'password', 'number', 'email', 'tel', 'url', 'search', 'date', 'datetime', 'datetime-local', 'time', 'month', 'week']
                        return inputTypes.indexOf(type) >= 0;
                    }
                    if (isTextBox(document.activeElement)) {
                         document.activeElement.placeholder = '';
                         document.activeElement.value = document.activeElement.value.substring(0, document.activeElement.value.length - 1);
                         document.activeElement.dispatchEvent(new Event('change'));
                         document.activeElement.dispatchEvent(new Event('input', { bubbles: true }));
                         document.activeElement.dispatchEvent(new Event('keypress', { bubbles: true }));
                         document.activeElement.dispatchEvent(new KeyboardEvent('keydown', {'key':'Shift'} ));
                    }
                """) { result, error in
                    
                }
            }
        }
    }
    
    private func modifyTextUsingEvent(_ text: String, _ event: SMRemoteControlKeyboardEvent ) -> String {
        if event.key.count == 1 {
            return text.appending(event.key)
        }
        else if event.key.lowercased() == "backspace" {
            return String(text.dropLast())
        }
        
        return text
    }
    
    private func showPulsingCircle(_ point: CGPoint) {
        if isPointerAnimationRunning {
            return
        }
        
        if let rootViewController = ScreenMeet.session.delegate?.rootViewController {
            DispatchQueue.main.async { [weak self] in
                
                self?.isPointerAnimationRunning = true
                let imageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
                imageView.layer.cornerRadius = 8
                imageView.backgroundColor = UIColor(red: 255.0/255.0, green: 116.0/255.0, blue: 52.0/255.0, alpha: 1.0)
                imageView.frame.origin.x = point.x - 8
                imageView.frame.origin.y = point.y - 8
                
                rootViewController.view.addSubview(imageView)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    imageView.removeFromSuperview()
                    self?.isPointerAnimationRunning = false
                }
                
            }
            
        }
        
    }
}
