//
//  CleanUpExpiredPendingRecordsUseCaseTests.swift
//  Domain
//

@testable import Domain
import Foundation
import Testing

@Suite("CleanUpExpiredPendingRecordsUseCase Tests")
struct CleanUpExpiredPendingRecordsUseCaseTests {
    private let mockRepository = MockPendingFoodRecordRepository()
    private let now = Date()

    private func makeSUT(
        expirationInterval: TimeInterval = 300
    ) -> CleanUpExpiredPendingRecordsUseCase<MockPendingFoodRecordRepository> {
        CleanUpExpiredPendingRecordsUseCase(
            repository: mockRepository,
            expirationInterval: expirationInterval
        )
    }

    // MARK: - 서버 비교 기반 정리

    @Test("서버에 동일 mealType의 FoodRecord가 있으면 해당 pending을 삭제한다")
    func testRemovesPendingWhenServerRecordExists() async throws {
        let sut = makeSUT()

        let serverRecords = [
            makeFoodRecord(mealType: .lunch)
        ]
        let pendingRecords = [
            makePendingRecord(uploadId: "upload-1", mealType: .lunch, createdAt: now)
        ]

        let result = try await sut.execute(
            serverRecords: serverRecords,
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.isEmpty)
        #expect(mockRepository.deletedUploadIds == ["upload-1"])
    }

    @Test("서버에 없는 mealType의 pending은 유지한다")
    func testKeepsPendingWhenNoServerRecord() async throws {
        let sut = makeSUT()

        let serverRecords = [
            makeFoodRecord(mealType: .lunch)
        ]
        let pendingRecords = [
            makePendingRecord(uploadId: "upload-1", mealType: .dinner, createdAt: now)
        ]

        let result = try await sut.execute(
            serverRecords: serverRecords,
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.count == 1)
        #expect(result.first?.uploadId == "upload-1")
        #expect(mockRepository.deletedUploadIds.isEmpty)
    }

    // MARK: - 시간 기반 만료

    @Test("5분 경과한 pending을 삭제한다")
    func testRemovesExpiredPending() async throws {
        let sut = makeSUT(expirationInterval: 300)

        let expiredCreatedAt = now.addingTimeInterval(-301)
        let pendingRecords = [
            makePendingRecord(uploadId: "upload-1", mealType: .lunch, createdAt: expiredCreatedAt)
        ]

        let result = try await sut.execute(
            serverRecords: [],
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.isEmpty)
        #expect(mockRepository.deletedUploadIds == ["upload-1"])
    }

    @Test("5분 미만인 pending은 유지한다")
    func testKeepsNonExpiredPending() async throws {
        let sut = makeSUT(expirationInterval: 300)

        let recentCreatedAt = now.addingTimeInterval(-299)
        let pendingRecords = [
            makePendingRecord(uploadId: "upload-1", mealType: .lunch, createdAt: recentCreatedAt)
        ]

        let result = try await sut.execute(
            serverRecords: [],
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.count == 1)
        #expect(mockRepository.deletedUploadIds.isEmpty)
    }

    // MARK: - 혼합 케이스

    @Test("서버 완료, 만료, 유효한 pending이 혼합된 경우 각각 올바르게 처리한다")
    func testMixedCase() async throws {
        let sut = makeSUT(expirationInterval: 300)

        let serverRecords = [
            makeFoodRecord(mealType: .breakfast)
        ]
        let pendingRecords = [
            makePendingRecord(uploadId: "completed", mealType: .breakfast, createdAt: now),
            makePendingRecord(uploadId: "expired", mealType: .dinner, createdAt: now.addingTimeInterval(-400)),
            makePendingRecord(uploadId: "valid", mealType: .lunch, createdAt: now.addingTimeInterval(-100)),
        ]

        let result = try await sut.execute(
            serverRecords: serverRecords,
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.count == 1)
        #expect(result.first?.uploadId == "valid")
        #expect(Set(mockRepository.deletedUploadIds) == Set(["completed", "expired"]))
    }

    // MARK: - 엣지 케이스

    @Test("정리 대상이 없으면 delete를 호출하지 않는다")
    func testNoDeleteWhenNothingToCleanUp() async throws {
        let sut = makeSUT()

        let pendingRecords = [
            makePendingRecord(uploadId: "upload-1", mealType: .lunch, createdAt: now)
        ]

        let result = try await sut.execute(
            serverRecords: [],
            pendingRecords: pendingRecords,
            now: now
        )

        #expect(result.count == 1)
        #expect(mockRepository.deletedUploadIds.isEmpty)
    }

    @Test("pending이 비어있으면 빈 배열을 반환한다")
    func testEmptyPendingRecords() async throws {
        let sut = makeSUT()

        let result = try await sut.execute(
            serverRecords: [makeFoodRecord(mealType: .lunch)],
            pendingRecords: [],
            now: now
        )

        #expect(result.isEmpty)
        #expect(mockRepository.deletedUploadIds.isEmpty)
    }
}

// MARK: - Test Helpers

private func makeFoodRecord(mealType: MealType) -> FoodRecord {
    FoodRecord(
        id: UUID().uuidString,
        date: Date(),
        mealType: mealType,
        genre: .korean,
        photos: [],
        createdAt: Date()
    )
}

private func makePendingRecord(
    uploadId: String,
    mealType: MealType,
    createdAt: Date
) -> PendingFoodRecord {
    PendingFoodRecord(
        uploadId: uploadId,
        mealType: mealType,
        date: Date(),
        createdAt: createdAt
    )
}
