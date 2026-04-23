//
//  HTTPClienting.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

import Foundation

public protocol HTTPClienting: Sendable {
    func request<T: Decodable>(_ request: some Requestable, accessToken: String?) async throws -> T
    func request(_ request: some Requestable, accessToken: String?) async throws
}

public extension HTTPClienting {
    func request<T: Decodable>(_ request: some Requestable) async throws -> T {
        try await self.request(request, accessToken: nil)
    }

    func request(_ request: some Requestable) async throws {
        try await self.request(request, accessToken: nil)
    }
}
