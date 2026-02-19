//
//  FoodRecordRepositoryImpl.swift
//  Data
//

import Domain
import Foundation
import UIKit

/// FoodRecordRepository 구현체
public final class FoodRecordRepositoryImpl: FoodRecordRepository, @unchecked Sendable {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring
    private let calendar = Calendar.current

    public init(httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    // MARK: - 서버 API 호출

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let dateString = formatDate(request.date)
        let files = try convertImagesToFiles(request.images)

        #if DEBUG
        let testMode = true
        #else
        let testMode = false
        #endif

        let endpoint = PhotosEndpoint.batchUpload(
            date: dateString,
            photos: files,
            testMode: testMode
        )

        let response: BatchUploadResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: accessToken
        )

        guard let firstResult = response.results.first else {
            throw FoodRecordError.emptyResponse
        }

        let diaryId = String(firstResult.diaryId)

        // 서버 푸시가 아직 구현되지 않았으므로 로컬에서 가짜 푸시 발행
        // pending save 완료 후 서버 반영 시간을 확보하기 위해 delay 적용
        let date = request.date
        Task {
            print("[FakePush] 1초 대기 시작 (uploadId: \(diaryId))")
            try? await Task.sleep(for: .seconds(1))
            print("[FakePush] 가짜 푸시 발행 (uploadId: \(diaryId), date: \(date))")
            postFakeAnalysisNotification(uploadId: diaryId, date: date)
            print("[FakePush] 가짜 푸시 발행 완료")
        }

        return diaryId
    }

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let startDateString = formatDate(dateRange.lowerBound)
        let endDateString = formatDate(dateRange.upperBound)

        #if DEBUG
        let testMode = true
        #else
        let testMode = false
        #endif

        let endpoint = DiariesEndpoint.fetchByDateRange(
            startDate: startDateString,
            endDate: endDateString,
            testMode: testMode
        )

        let response: DiariesResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: accessToken
        )

        return convertToRecordsByDate(response)
    }

    public func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        let records = try await fetchRecords(in: startOfDay...startOfDay)
        return records[startOfDay] ?? []
    }

    // MARK: - Mock 구현 (서버 API 미구현)

    public func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        // TODO: 서버 API 연동
        throw NSError(domain: "FoodRecordRepositoryImpl", code: 501, userInfo: [NSLocalizedDescriptionKey: "서버 API 미구현"])
    }

    public func deleteRecord(id: String) async throws {
        // TODO: 서버 API 연동
        throw NSError(domain: "FoodRecordRepositoryImpl", code: 501, userInfo: [NSLocalizedDescriptionKey: "서버 API 미구현"])
    }
}

// MARK: - Private

private extension FoodRecordRepositoryImpl {
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    func convertImagesToFiles(_ images: [UIImage]) throws -> [File] {
        try images.enumerated().map { index, image in
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                throw FoodRecordError.imageConversionFailed
            }
            return File(
                fileName: "photo_\(index).jpg",
                mimeType: "image/jpeg",
                data: jpegData
            )
        }
    }

    func convertToRecordsByDate(_ response: DiariesResponseDTO) -> [Date: [FoodRecord]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = .current

        var result: [Date: [FoodRecord]] = [:]

        for (dateString, dateResponse) in response {
            guard let date = dateFormatter.date(from: dateString) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let records = dateResponse.diaries.compactMap { $0.toFoodRecord() }
            if !records.isEmpty {
                result[startOfDay] = records
            }
        }

        return result
    }

    func postFakeAnalysisNotification(uploadId: String, date: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)

        NotificationCenter.default.post(
            name: AppNotification.Push.analysisResult,
            object: nil,
            userInfo: [
                AppNotification.Push.Key.uploadId: uploadId,
                AppNotification.Push.Key.date: dateString
            ]
        )
    }
}
