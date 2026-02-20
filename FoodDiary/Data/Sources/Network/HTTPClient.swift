//
//  HTTPClient.swift
//  Core
//
//  Created by 강대훈 on 1/17/26.
//

import Foundation

public struct HTTPClient: HTTPClienting {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: HTTPLogger
    
    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        logger: HTTPLogger = HTTPLogger()
    ) {
        self.session = session
        self.decoder = decoder
        self.logger = logger
    }

    public func request<T: Decodable>(_ request: some Requestable, accessToken: String? = nil) async throws -> T {
        do {
            var urlRequest = try request.makeURLRequest()
            applyAccessToken(accessToken, to: &urlRequest)

            logger.logRequest(urlRequest)
            logger.logRequestBody(urlRequest.httpBody)

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.logError(NetworkError.invalidResponse, context: "Network error")
                throw NetworkError.invalidResponse
            }

            logger.logResponse(response, statusCode: httpResponse.statusCode)
            logger.logResponseBody(data)

            try checkResponse(data, httpResponse)

            do {
                let model = try decoder.decode(T.self, from: data)
                logger.logDecodedModel(model)
                return model
            } catch {
                logger.logError(error, context: "Decoding error")
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            logger.logError(error, context: "Network error")
            throw error
        } catch {
            logger.logError(error, context: "Request error")
            throw NetworkError.requestFailed
        }
    }
}

// MARK: - Private Method
private extension HTTPClient {
    func applyAccessToken(_ accessToken: String?, to request: inout URLRequest) {
        guard let accessToken else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    func checkResponse(_ data: Data, _ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        default:
            throw NetworkError.httpError(statusCode: response.statusCode, data: data)
        }
    }
}
