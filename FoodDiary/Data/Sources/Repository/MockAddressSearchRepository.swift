//
//  MockAddressSearchRepository.swift
//  Data
//

import Domain
import Foundation

/// 서버 API 확정 전까지 사용할 임시 AddressSearchRepository 구현체
public struct MockAddressSearchRepository: AddressSearchRepository {
    public init() {}

    private let mockData: [AddressSearchResult] = [
        AddressSearchResult(placeName: "스시코우지", roadAddress: "서울 강남구 압구정로46길 50", jibunAddress: "서울 강남구 신사동 664-32"),
        AddressSearchResult(placeName: "몽탄", roadAddress: "서울 용산구 백범로99길 50", jibunAddress: "서울 용산구 원효로2가 1-81"),
        AddressSearchResult(placeName: "정식당", roadAddress: "서울 강남구 선릉로158길 11", jibunAddress: "서울 강남구 청담동 80-4"),
        AddressSearchResult(placeName: "밍글스", roadAddress: "서울 강남구 도산대로67길 19", jibunAddress: "서울 강남구 청담동 89-8"),
        AddressSearchResult(placeName: "라연", roadAddress: "서울 중구 장충단로 60", jibunAddress: "서울 중구 장충동2가 199"),
        AddressSearchResult(placeName: "모수", roadAddress: "서울 강남구 압구정로46길 48", jibunAddress: "서울 강남구 신사동 664-31"),
        AddressSearchResult(placeName: "류니끄", roadAddress: "서울 강남구 도산대로45길 7", jibunAddress: "서울 강남구 신사동 550-16"),
        AddressSearchResult(placeName: "투끼", roadAddress: "서울 마포구 와우산로 112", jibunAddress: "서울 마포구 서교동 395-166"),
        AddressSearchResult(placeName: "광화문 미진", roadAddress: "서울 종로구 종로 19", jibunAddress: "서울 종로구 종로1가 24"),
        AddressSearchResult(placeName: "을지로 노가리 골목", roadAddress: "서울 중구 을지로 14", jibunAddress: "서울 중구 을지로2가 199-27"),
        AddressSearchResult(placeName: "봉피양", roadAddress: "서울 강남구 테헤란로 110", jibunAddress: "서울 강남구 역삼동 648-9"),
        AddressSearchResult(placeName: "오모리찌개", roadAddress: "서울 강남구 논현로 175", jibunAddress: "서울 강남구 신사동 587-30"),
        AddressSearchResult(placeName: "한우오마카세 소올", roadAddress: "서울 강남구 학동로 305", jibunAddress: "서울 강남구 논현동 168-7"),
        AddressSearchResult(placeName: "도스타코스", roadAddress: "서울 강남구 강남대로102길 34", jibunAddress: "서울 강남구 역삼동 824-11"),
        AddressSearchResult(placeName: "카페 온다", roadAddress: "서울 강남구 선릉로 831", jibunAddress: "서울 강남구 청담동 46-20"),
        AddressSearchResult(placeName: "스시 사이토", roadAddress: "서울 강남구 도산대로 318", jibunAddress: "서울 강남구 청담동 84-18"),
        AddressSearchResult(placeName: "진진", roadAddress: "서울 강남구 봉은사로 220", jibunAddress: "서울 강남구 논현동 63-20"),
    ]

    public func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult] {
        // TODO: 서버 API 확정 후 실제 구현체로 교체
        let filtered = mockData.filter {
            $0.placeName.contains(keyword) || $0.roadAddress.contains(keyword)
        }
        return filtered
    }

    public func fetchSuggestions(restaurantName: String) async throws -> [AddressSearchResult] {
        // TODO: 서버 API 확정 후 실제 구현체로 교체
        // 서버에서 AI 분석 기반으로 확률 높은 후보군을 반환하는 API
        guard !restaurantName.isEmpty else { return [] }
        return [
            AddressSearchResult(
                placeName: "\(restaurantName) 본점",
                roadAddress: "서울특별시 성동구 광나루로 4가길 12-7 1층",
                jibunAddress: "서울특별시 성동구 성수동1가 668-120"
            ),
            AddressSearchResult(
                placeName: "\(restaurantName) 2호점",
                roadAddress: "서울특별시 성동구 광나루로 4가길 12-7 2층",
                jibunAddress: "서울특별시 성동구 성수동1가 668-120"
            ),
            AddressSearchResult(
                placeName: "\(restaurantName) 3호점",
                roadAddress: "서울특별시 성동구 광나루로 4가길 12-7 3층",
                jibunAddress: "서울특별시 성동구 성수동1가 668-120"
            ),
        ]
    }
}
