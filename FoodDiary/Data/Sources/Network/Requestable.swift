//
//  Requestable.swift
//  Core
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation

public protocol Requestable {
    var baseURL: String { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var queryParameters: Encodable? { get }
    var bodyParameters: HTTPBody { get }
    var headers: [String: String] { get }
}

extension Requestable {
    public func makeURLRequest() throws -> URLRequest {
        var urlComponent = try getURLComponents()
        
        if let queryItems = try getQueryParameters() {
            urlComponent.queryItems = queryItems
        }
        
        guard let url = urlComponent.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue

        let evaluatedBody = bodyParameters

        if let httpBody = try getBodyParameters(from: evaluatedBody) {
            request.httpBody = httpBody
        }

        getHeaders(request: &request, body: evaluatedBody)

        return request
    }
}

// MARK: - Private Method

extension Requestable {
    private func getQueryParameters() throws -> [URLQueryItem]? {
        guard let queryParameters else {
            return nil
        }
        
        guard let queryDictionary = try? queryParameters.toDictionary() else {
            throw NetworkError.invalidURL
        }
        
        var queryItemList: [URLQueryItem] = []
        
        queryDictionary.forEach { (key, value) in
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            queryItemList.append(queryItem)
        }
        
        if queryItemList.isEmpty {
            return nil
        }
        
        return queryItemList
    }
    
    private func getBodyParameters(from body: HTTPBody) throws -> Data? {
        switch body {
        case let .json(data):
            guard let bodyDictionary = try? data.toDictionary() else {
                throw NetworkError.encodingError
            }

            guard let encodedBody = try? JSONSerialization.data(withJSONObject: bodyDictionary) else {
                throw NetworkError.encodingError
            }

            return encodedBody
        case let .multipart(data):
            return data.body
        case .none:
            return nil
        }
    }
    
    private func getURLComponents() throws -> URLComponents {
        guard URL(string: baseURL) != nil else {
            throw NetworkError.invalidURL
        }
        
        guard let urlComponent = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }
        
        guard urlComponent.scheme != nil, urlComponent.host != nil else {
            throw NetworkError.invalidURL
        }
        
        return urlComponent
    }
    
    private func getHeaders(request: inout URLRequest, body: HTTPBody) {
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        switch body {
        case let .multipart(formData):
            request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .none:
            break
        }
    }
}
