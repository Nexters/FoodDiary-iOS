//
//  HTTPClienting.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

import Foundation

public protocol HTTPClienting {
    func request<T: Decodable>(_ request: some Requestable, accessToken: String?) async throws -> T
    func requestVoid(_ request: some Requestable, accessToken: String?) async throws
}

public extension HTTPClienting {
    func request<T: Decodable>(_ request: some Requestable) async throws -> T {
        try await self.request(request, accessToken: nil)
    }

    func requestVoid(_ request: some Requestable) async throws {
        try await self.requestVoid(request, accessToken: nil)
    }
}
