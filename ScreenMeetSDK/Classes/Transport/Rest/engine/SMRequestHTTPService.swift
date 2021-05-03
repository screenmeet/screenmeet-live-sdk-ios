//
//  DDRequestHTTPTransport.swift
//  EquifyCRM
//
//  Created by Rostyslav Stepanyak on 25/06/18.
//  Copyright © 2017 DDragons LLC. All rights reserved.
//

import Foundation

class SMRequestHTTPService: NSObject, SMRequestService {
    var session: URLSession?
    var userAgent: String? = nil
    
    override init() {
        super.init()
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    internal func send<T>(request: SMRequest, completion: @escaping (T?, TransportError?, ErrorPayload?) -> Void) where T: SMResponse, T: Deserializable {
        
        guard let request = prepareHttpRequestFor(request: request) else {
            completion(nil, TransportError.SerializationFailed, nil)
            return
        }
        
        session?.dataTask(with: request) { [weak self]
            (responseData, urlResponse, requestError) in
            
            var error: TransportError? = nil
            var errorPayload: ErrorPayload? = nil
            var response: T? = nil
            let httpUrlResponse = urlResponse as? HTTPURLResponse
            
            // Request completed successfully if responseData is not nil and requestError is nil
            // It is also expected that urlResponse will always contain a proper HTTPURLResponse object
            if let responseData = responseData,
                requestError == nil,
                httpUrlResponse != nil {
                
                _ = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue)
                
                if (200..<300).contains(httpUrlResponse!.statusCode) {
                    response = T(data: responseData)
                    if response == nil {
                        error = TransportError.DeserializationFailed
                    }
                } else {
                    error = TransportError.ServerError(code: httpUrlResponse!.statusCode)
                    errorPayload = self?.dataToDict(responseData)
                }    
            } else {
                error = TransportError.RequestFailed(error: requestError)
                print("Request Error: " + error!.localizedDescription)
            }
                        
            DispatchQueue.main.async {
                completion(response, error, errorPayload)
            }
        }.resume()
    }
    
    func prepareHttpRequestFor(request: SMRequest) -> URLRequest? {
        guard let httpRequest = request as? HTTPRequest else { return nil }

        let url = URL(string: httpRequest.baseUrl)!.appendingPathComponent(httpRequest.relativePath)
        var request: URLRequest!
        
        switch httpRequest {
        case let getRequst as HTTPGetRequest:
            var components = URLComponents(string: url.absoluteString)!
        
            components.queryItems = getRequst.urlQueryItems
            
            request = URLRequest(url: components.url!)
            if let additionalHeaders = getRequst.additionalHeaders {
                for (headerField, value) in additionalHeaders {
                    request.addValue(value, forHTTPHeaderField: headerField)
                }
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
        case let postRequest as HTTPPostRequest:
            request = URLRequest(url: url)
            let postData = postRequest.dataForHttpBody
            
            if let additionalHeaders = postRequest.additionalHeaders {
                for (headerField, value) in additionalHeaders {
                    request.addValue(value, forHTTPHeaderField: headerField)
                }
            }
            
            request.httpBody = postData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(String(describing: postData?.count), forHTTPHeaderField: "Content-Length")
        default:
            return nil
        }
        
        request.httpMethod = httpRequest.httpMethod
        return request
    }
    
    private func dataToDict(_ data: Data) -> ErrorPayload? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return json
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        return nil
    }
}

extension SMRequestHTTPService: URLSessionDelegate {
    
}

protocol HTTPRequest {
    var relativePath: String { get }
    var baseUrl: String { get }
    var httpMethod: String { get }
}

protocol HTTPGetRequest: HTTPRequest {
    var urlQueryItems: [URLQueryItem]? { get }
    var additionalHeaders: [String: String]? { get }
}

protocol HTTPPostRequest: HTTPRequest {
    var dataForHttpBody: Data? { get }
    var additionalHeaders: [String: String]? { get }
}

protocol HTTPPutRequest: HTTPRequest {
    var dataForHttpBody: Data? { get }
    var additionalHeaders: [String: String]? { get }
}

protocol HTTPDeleteRequest: HTTPRequest {
    var urlQueryItems: [URLQueryItem]? { get }
    var additionalHeaders: [String: String]? { get }
}

extension HTTPRequest {
    var relativePath: String {
        return relativePath
    }
}

extension HTTPPostRequest {
    var httpMethod: String {
        return "POST"
    }
}

extension HTTPGetRequest {
    var httpMethod: String {
        return "GET"
    }
}

extension HTTPPutRequest {
    var httpMethod: String {
        return "PUT"
    }
}

extension HTTPDeleteRequest {
    var httpMethod: String {
        return "DELETE"
    }
}
