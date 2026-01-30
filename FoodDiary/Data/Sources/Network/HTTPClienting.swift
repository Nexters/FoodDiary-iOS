//
//  HTTPClienting.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

import Foundation

public protocol HTTPClienting<Target> {
    associatedtype Target: Requestable
    
    func request<T: Decodable>(_ request: Target, accessToken: String?) async throws -> T
}

public extension HTTPClienting {
    func request<T: Decodable>(_ request: Target) async throws -> T {
        try await self.request(request, accessToken: nil)
    }
}
