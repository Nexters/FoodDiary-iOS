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
    var bodyParameters: Encodable? { get }
    var headers: [String: String] { get }
}

// TODO: 추후에 JWT가 생겼을 때 어떻게 Header에 포함시킬 것인지?

extension Requestable {
    public func makeURLrequest() throws -> URLRequest {
        guard var urlComponent = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = try getQueryParameters() {
            urlComponent.queryItems = queryItems
        }
        
        guard let url = urlComponent.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        if let httpBody = try getBodyParameters() {
            request.httpBody = httpBody
        }
        
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
    
    private func getBodyParameters() throws -> Data? {
        guard let bodyParameters else {
            return nil
        }
        
        guard let bodyDictionary = try? bodyParameters.toDictionary() else {
            throw NetworkError.encodingError
        }
        
        guard let encodedBody = try? JSONSerialization.data(withJSONObject: bodyDictionary) else {
            throw NetworkError.encodingError
        }
        
        return encodedBody
    }
}
