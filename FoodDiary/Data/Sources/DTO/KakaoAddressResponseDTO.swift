//
//  KakaoAddressResponseDTO.swift
//  Data
//

import Foundation

struct KakaoAddressResponseDTO: Decodable {
    let documents: [Document]

    struct Document: Decodable {
        let placeName: String
        let roadAddressName: String
        let addressName: String

        enum CodingKeys: String, CodingKey {
            case placeName = "place_name"
            case roadAddressName = "road_address_name"
            case addressName = "address_name"
        }
    }
}
