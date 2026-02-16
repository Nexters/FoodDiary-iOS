//
//  KakaoAddressRepository.swift
//  Data
//

import Domain
import Foundation

public struct KakaoAddressRepository: AddressSearchRepository {
    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult] {
        let endpoint = KakaoAddressEndpoint.searchKeyword(query: keyword, page: page)
        let response: KakaoAddressResponseDTO = try await httpClient.request(endpoint)

        return response.documents.map { doc in
            AddressSearchResult(
                placeName: doc.placeName,
                roadAddress: doc.roadAddressName,
                jibunAddress: doc.addressName
            )
        }
    }
}
