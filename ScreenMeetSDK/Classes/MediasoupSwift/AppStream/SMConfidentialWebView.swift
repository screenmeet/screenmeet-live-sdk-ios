//
//  SMConfidentialWebView.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 27.01.2021.
//

import Foundation
import WebKit

class SMConfidentialWebView {
    
    private weak var webView: WKWebView?
    
    fileprivate var nodes = [Node]()
    
    var isEmpty: Bool {
        webView == nil
    }
    
    fileprivate class Node {
        
        var id: UUID
        
        private var lastFramePossitions = [CGRect]()
        
        var frame: CGRect? {
            guard lastFramePossitions.count > 0 else { return nil }
            
            let minX = lastFramePossitions.map { $0.origin.x }.min()!
            let minY = lastFramePossitions.map { $0.origin.y }.min()!
            let maxX = lastFramePossitions.map { $0.origin.x + $0.width }.max()!
            let maxY = lastFramePossitions.map { $0.origin.y + $0.height }.max()!
            
            let width = (maxX - minX)
            let height = (maxY - minY)
            let x = minX
            let y = minY
            
            var confRect = CGRect(x: x, y: y, width: width, height: height)
            
            if !areRectsEqual(lhs: confRect, rhs: lastFramePossitions.last ?? .zero) {
                confRect.origin.x -= 5
                confRect.origin.y -= 5
                confRect.size.width += 10
                confRect.size.height += 10
            }
            
            return confRect
        }
        
        init(id: UUID) {
            self.id = id
        }
        
        func update(framePossition: CGRect) {
            if lastFramePossitions.count > 3 {
                lastFramePossitions.removeFirst()
            }
            
            if !lastFramePossitions.contains(framePossition) {
                lastFramePossitions.append(framePossition)
            }
        }
        
        private func areRectsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
            guard abs(lhs.origin.x - rhs.origin.x) <= 1 else { return false }
            guard abs(lhs.origin.y - rhs.origin.y) <= 1 else { return false }
            guard abs(lhs.size.width - rhs.size.width) <= 1 else { return false }
            guard abs(lhs.size.height - rhs.size.height) <= 1 else { return false }
            
            return true
        }
    }
    
    private struct NodeModel: Decodable {
        
        var id: UUID
        
        var left: CGFloat
        
        var top: CGFloat
        
        var width: CGFloat
        
        var height: CGFloat
    }
    
    init(_ webView: WKWebView) {
        self.webView = webView
    }
    
    static func ==(lhs: SMConfidentialWebView, rhs: WKWebView) -> Bool {
        return lhs.webView == rhs
    }
}

extension SMConfidentialWebView {
    
    private static let selectors: [String] = ["input[type='password']", "[data-cb-mask]"]
    
    private static let js: String = """
    function uuidv4() {
      return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
        (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
      );
    }

    function queryNodes() {
        const nodes = [];

        const passwordNodes = Array.from(document.querySelectorAll("\(selectors.joined(separator: ","))"));
        passwordNodes.forEach(function(node) {
            if (node.dataset.smuuid == null) {
                node.dataset.smuuid = uuidv4()
            }

            var bodyRect = document.body.getBoundingClientRect(),
                elemRect = node.getBoundingClientRect(),
                offsetTop = elemRect.top - bodyRect.top,
                offsetLeft = elemRect.left - bodyRect.left;
            nodes.push({
                "left": offsetLeft,
                "top": offsetTop,
                "width": elemRect.width,
                "height": elemRect.height,
                "id": node.dataset.smuuid
            });
        });

        return nodes;
    } queryNodes();
    """
    
    fileprivate func updateNodes(completion: @escaping () -> Void) {
        guard let webView = webView else {
            completion()
            return
        }
        
        webView.evaluateJavaScript(SMConfidentialWebView.js) { [weak self] (data, error) in
            if let error = error {
                print("ScreenMeetSDK: Evaluate Java Script Error: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let data = data as? [Any],
                  let serializedData = try? JSONSerialization.data(withJSONObject: data),
                  let webNodes = try? JSONDecoder().decode([NodeModel].self, from: serializedData) else {
                completion()
                return
            }
            
            let contentView = webView.scrollView.subviews.first(where: { $0.frame != .zero })
            let webViewRect = webView.globalRect ?? .zero
            let contentRect = contentView?.globalRect ?? .zero
            let contentTransformScale = contentView?.globalTransform?.m11
            let zoomScale = contentTransformScale ?? webView.scrollView.zoomScale
            
            var nodes = [Node]()
            
            webNodes.forEach { (webNode) in
                guard webNode.width > 0, webNode.height > 0 else { return }
                
                let x = (webNode.left * zoomScale) + contentRect.origin.x
                let y = (webNode.top * zoomScale) + contentRect.origin.y
                let width = webNode.width * zoomScale
                let height = webNode.height * zoomScale
                
                let frame = CGRect(x: x, y: y, width: width, height: height).intersection(webViewRect)
                
                if let node = self?.nodes.first(where: { $0.id == webNode.id }) {
                    node.update(framePossition: frame)
                    nodes.append(node)
                } else {
                    let node = Node(id: webNode.id)
                    node.update(framePossition: frame)
                    nodes.append(node)
                }
            }
            
            self?.nodes = nodes
            completion()
        }
    }
}

extension Array where Element == SMConfidentialWebView {
    
    var operation: SMCalculateFramesOperation {
        WebViewOperation(webViews: self)
    }
    
    class WebViewOperation: Operation, SMCalculateFramesOperation {
        
        var webViews: [SMConfidentialWebView]
        
        var frames = [CGRect]()
        
        init(webViews: [SMConfidentialWebView]) {
            self.webViews = webViews
        }
        
        override func main() {
            guard !isCancelled else { return }
            guard webViews.count > 0 else { return }
            
            var frames = [CGRect]()
            let endIndex = webViews.endIndex
            
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async { [unowned self] in
                for (index, webView) in webViews.enumerated() {
                    webView.updateNodes {
                        frames = webView.nodes.compactMap { $0.frame }
                        if index == endIndex - 1 {
                            group.leave()
                        }
                    }
                }
            }
            
            group.wait()
            
            self.frames = frames
        }
    }
}
