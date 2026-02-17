//
//  MockFoodRecordRepository.swift
//  Data
//

import Domain
import Foundation

/// Mock 구현: 서버 API 대신 사용
public final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    private var mockRecords: [Date: [FoodRecord]] = [:]
    private let calendar = Calendar.current

    public init() {
        setupMockData()
    }

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        mockRecords.filter { dateRange.contains($0.key) }
    }

    public func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        return mockRecords[startOfDay] ?? []
    }

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        let imageCount = request.images.count
        print("[MockFoodRecordRepository] 📤 업로드 시작 - 이미지 \(imageCount)장")

        // 이미지 업로드 시뮬레이션
        for i in 1...imageCount {
            try await Task.sleep(for: .seconds(1))
            print("[MockFoodRecordRepository] 📤 이미지 업로드 중... (\(i)/\(imageCount))")
        }

        let uploadId = UUID().uuidString
        print("[MockFoodRecordRepository] ✅ 업로드 완료! uploadId: \(uploadId)")
        print("[MockFoodRecordRepository] 🤖 AI 분석은 서버에서 비동기로 진행됩니다. Remote Push로 결과 수신 예정.")

        simulatePushNotification(uploadId: uploadId, date: request.date)

        return uploadId
    }

    public func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        for (dateKey, records) in mockRecords {
            if let index = records.firstIndex(where: { $0.id == request.id }) {
                let existing = records[index]
                let combinedAddress: String? = if let address = request.address {
                    if let detail = request.detailAddress, !detail.isEmpty {
                        "\(address) \(detail)"
                    } else {
                        address
                    }
                } else {
                    existing.address
                }

                let updated = FoodRecord(
                    id: existing.id,
                    date: existing.date,
                    mealType: existing.mealType,
                    genre: request.genre,
                    imageURLs: request.existingImageURLs,
                    restaurantName: existing.restaurantName,
                    address: combinedAddress,
                    hashtags: request.hashtags,
                    createdAt: existing.createdAt
                )
                mockRecords[dateKey]?[index] = updated
                return updated
            }
        }
        throw NSError(domain: "MockFoodRecordRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "기록을 찾을 수 없습니다"])
    }

    public func deleteRecord(id: String) async throws {
        for (dateKey, records) in mockRecords {
            if let index = records.firstIndex(where: { $0.id == id }) {
                mockRecords[dateKey]?.remove(at: index)
                if mockRecords[dateKey]?.isEmpty == true {
                    mockRecords.removeValue(forKey: dateKey)
                }
                return
            }
        }
        throw NSError(domain: "MockFoodRecordRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "기록을 찾을 수 없습니다"])
    }

    // MARK: - Mock Data Setup

    private static let mockImageURL = URL(
        string:
            "https://scontent-icn2-1.cdninstagram.com/v/t51.29350-15/461504105_2580000165532574_7826255553974624552_n.jpg?stp=dst-jpg_e35_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6InRocmVhZHMuQ0FST1VTRUxfSVRFTS5pbWFnZV91cmxnZW4uMTQ0MHgxNDQwLnNkci5mMjkzNTAuZGVmYXVsdF9pbWFnZS5jMiJ9&_nc_ht=scontent-icn2-1.cdninstagram.com&_nc_cat=102&_nc_oc=Q6cZ2QF8w3O7ifi1Y1Vt8PsovLJXxldhHEZlzl3ASN01dV112tEUtvmsQvsmj1l3CIezXBU&_nc_ohc=lHxDPz1Ccz8Q7kNvwFX84oT&_nc_gid=_Z1qIYP7NELwB84RenKVNg&edm=AKr904kBAAAA&ccb=7-5&ig_cache_key=MzQ2OTA5NzA2NzczNjgxNTkxMQ%3D%3D.3-ccb7-5&oh=00_AfteQkqGT01MMvi0V1WSeHtguB_Jwkx0To0c5UVSu1JCDw&oe=6993A39A&_nc_sid=23467f"
    )!

    private static let mockImageURL2 = URL(
        string: "https://picsum.photos/seed/food1/800/800"
    )!

    private static let mockImageURL3 = URL(
        string: "https://picsum.photos/seed/food2/800/800"
    )!

    private func setupMockData() {
        let today = calendar.startOfDay(for: Date())

        // 어제 기록
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
            let yesterdayLunch = calendar.date(
                bySettingHour: 13, minute: 0, second: 0, of: yesterday)
        {
            mockRecords[yesterday] = [
                FoodRecord(
                    id: UUID().uuidString,
                    date: yesterday,
                    mealType: .lunch,
                    genre: .korean,
                    imageURLs: [Self.mockImageURL, Self.mockImageURL2, Self.mockImageURL3],
                    restaurantName: "할머니 손칼국수",
                    address: "서울시 종로구 인사동길 12",
                    hashtags: [
                        "칼국수", "만두", "김치", "맛집", "점심추천",
                        "혼밥", "종로맛집", "인사동", "한식", "국물요리",
                        "수제만두", "손칼국수", "겨울음식", "따뜻한", "가성비",
                        "직장인점심", "노포", "전통맛집", "단골", "소울푸드"
                    ],
                    createdAt: yesterdayLunch
                )
            ]
        }

        // 3일 전 기록
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today),
            let breakfastTime = calendar.date(
                bySettingHour: 8, minute: 30, second: 0, of: threeDaysAgo),
            let lateNightTime = calendar.date(
                bySettingHour: 23, minute: 30, second: 0, of: threeDaysAgo)
        {
            mockRecords[threeDaysAgo] = [
                FoodRecord(
                    id: UUID().uuidString,
                    date: threeDaysAgo,
                    mealType: .breakfast,
                    genre: .western,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "브런치 카페",
                    address: "서울시 마포구 연남동 123-45",
                    hashtags: ["브런치", "에그베네딕트", "아메리카노"],
                    createdAt: breakfastTime
                ),
                FoodRecord(
                    id: UUID().uuidString,
                    date: threeDaysAgo,
                    mealType: .lateNight,
                    genre: .korean,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "포장마차",
                    address: "서울시 마포구 홍대입구역",
                    hashtags: ["떡볶이", "순대", "오뎅"],
                    createdAt: lateNightTime
                ),
            ]
        }
    }

    private func simulatePushNotification(uploadId: String, date: Date) {
        Task {
            for _ in 1...2 {
                try await Task.sleep(for: .seconds(2))
                print("[MockFoodRecordRepository] ⏳ 분석 중... (uploadId: \(uploadId))")
            }

            // 분석 완료 후 mockRecords에 레코드 추가
            let newRecord = FoodRecord(
                id: uploadId,
                date: date,
                mealType: .lunch,
                genre: .korean,
                imageURLs: [Self.mockImageURL],
                restaurantName: "새로 추가된 식당",
                address: "서울시 강남구",
                hashtags: ["맛집", "점심"],
                createdAt: date
            )
            let dateKey = calendar.startOfDay(for: date)
            if mockRecords[dateKey] != nil {
                mockRecords[dateKey]?.append(newRecord)
            } else {
                mockRecords[dateKey] = [newRecord]
            }
            print("[MockFoodRecordRepository] ✅ mockRecords에 레코드 추가 완료")

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            print("[MockFoodRecordRepository] 📲 푸시 알림 시뮬레이션: uploadId=\(uploadId)")
            NotificationCenter.default.post(
                name: AppNotification.Push.analysisResult,
                object: nil,
                userInfo: [
                    AppNotification.Push.Key.uploadId: uploadId,
                    AppNotification.Push.Key.date: dateFormatter.string(from: date),
                ]
            )
        }
    }
}
