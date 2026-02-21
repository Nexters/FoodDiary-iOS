//
//  FoodRecordRepositoryImpl.swift
//  Data
//

import Domain
import Foundation
import UIKit

/// FoodRecordRepository 구현체
public struct FoodRecordRepositoryImpl<
    Client: HTTPClienting & Sendable,
    Storage: AuthTokenStoring & Sendable
>: FoodRecordRepository {
    private let httpClient: Client
    private let tokenStorage: Storage
    private let deviceId: String
    private let calendar = Calendar.current

    #if DEBUG
        let testMode = true
    #else
        let testMode = true
    #endif

    public init(httpClient: Client, tokenStorage: Storage, deviceId: String) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
        self.deviceId = deviceId
    }

    // MARK: - 서버 API 호출

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let dateString = formatDate(request.date)
        let files = try convertImagesToFiles(request.images)

        let endpoint = PhotosEndpoint.batchUpload(
            date: dateString,
            deviceId: deviceId,
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
            // print("[FakePush] 1초 대기 시작 (uploadId: \(diaryId))")
            // try? await Task.sleep(for: .seconds(1))
            // print("[FakePush] 가짜 푸시 발행 (uploadId: \(diaryId), date: \(date))")
            // postFakeAnalysisNotification(uploadId: diaryId, date: date)
            // print("[FakePush] 가짜 푸시 발행 완료")
        }

        return diaryId
    }

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let startDateString = formatDate(dateRange.lowerBound)
        let endDateString = formatDate(dateRange.upperBound)

        let endpoint = DiaryEndpoint.byDateRange(
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

    public func fetchPhotoURLs(in dateRange: ClosedRange<Date>) async throws -> [Date: [URL]] {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let startDateString = formatDate(dateRange.lowerBound)
        let endDateString = formatDate(dateRange.upperBound)

        let endpoint = DiaryEndpoint.byDateRangeSummary(
            startDate: startDateString,
            endDate: endDateString,
            testMode: testMode
        )

        let response: DiariesByDateRangeSummaryResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: accessToken
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return response.reduce(into: [Date: [URL]]()) { result, entry in
            guard let date = formatter.date(from: entry.key) else { return }
            result[date] = entry.value.photos.compactMap { URL(string: $0) }
        }
    }

    // MARK: - Mock 구현 (서버 API 미구현)

    public func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        // TODO: 서버 API 연동
        throw NSError(
            domain: "FoodRecordRepositoryImpl", code: 501,
            userInfo: [NSLocalizedDescriptionKey: "서버 API 미구현"])
    }

    public func deleteRecord(id: String) async throws {
        // TODO: 서버 API 연동
        throw NSError(
            domain: "FoodRecordRepositoryImpl", code: 501,
            userInfo: [NSLocalizedDescriptionKey: "서버 API 미구현"])
    }
}

// MARK: - Private

extension FoodRecordRepositoryImpl {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    private func convertImagesToFiles(_ images: [UIImage]) throws -> [File] {
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

    private func convertToRecordsByDate(_ response: DiariesResponseDTO) -> [Date: [FoodRecord]]
    {
        var result: [Date: [FoodRecord]] = [:]

        for dto in response.diaries {
            guard let record = dto.toFoodRecord() else { continue }
            let startOfDay = calendar.startOfDay(for: record.date)
            result[startOfDay, default: []].append(record)
        }

        return result
    }

    private func postFakeAnalysisNotification(uploadId: String, date: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)

        NotificationCenter.default.post(
            name: AppNotification.Push.analysisResult,
            object: nil,
            userInfo: [
                AppNotification.Push.Key.uploadId: uploadId,
                AppNotification.Push.Key.date: dateString,
            ]
        )
    }
}
