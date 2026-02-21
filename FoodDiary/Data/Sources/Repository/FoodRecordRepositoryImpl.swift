//
//  FoodRecordRepositoryImpl.swift
//  Data
//

import Domain
import Foundation
import Photos
import UIKit

/// FoodRecordRepository 구현체
public struct FoodRecordRepositoryImpl<
    Client: HTTPClienting & Sendable,
    Storage: AuthTokenStoring & Sendable
>: FoodRecordRepository {
    private let httpClient: Client
    private let tokenStorage: Storage
    private let deviceId: String
    private let imageConverter: PHAssetConverter
    private let calendar = Calendar.current

    #if DEBUG
        let testMode = false
    #else
        let testMode = false
    #endif

    public init(httpClient: Client, tokenStorage: Storage, deviceId: String, imageConverter: PHAssetConverter) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
        self.deviceId = deviceId
        self.imageConverter = imageConverter
    }

    // MARK: - 서버 API 호출

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let dateString = formatDate(request.date)
        let files = try await convertAssetsToFiles(request.assets)

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
            // postFakeAnalysisNotification(date: date)
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

    // MARK: - 수정/삭제 API

    public func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        guard let diaryId = Int(request.id) else {
            throw FoodRecordError.emptyResponse
        }

        // 1. 새 이미지가 있으면 사진 업로드 → 새 photo_id 획득
        var newPhotoIds: [Int] = []
        if !request.newAssets.isEmpty {
            let files = try await convertAssetsToFiles(request.newAssets)
            let uploadEndpoint = DiaryEndpoint.addPhotos(diaryId: diaryId, photos: files)
            let uploadResponse: AddDiaryPhotosResponseDTO = try await httpClient.request(
                uploadEndpoint,
                accessToken: accessToken
            )
            newPhotoIds = uploadResponse.photoIds
        }

        // 2. 기존 유지할 photo_ids + 새 photo_ids 합침
        let allPhotoIds = request.existingPhotoIds + newPhotoIds

        // 3. PATCH /diaries/{diary_id} 호출
        let updateBody = DiaryUpdateRequestDTO(
            category: request.genre.rawValue,
            restaurantName: request.restaurantName,
            restaurantUrl: request.restaurantURL,
            roadAddress: request.address,
            tags: request.hashtags,
            note: request.note,
            coverPhotoId: request.coverPhotoId ?? allPhotoIds.first,
            photoIds: allPhotoIds
        )

        let updateEndpoint = DiaryEndpoint.update(diaryId: diaryId, body: updateBody)
        let response: DiaryResponseDTO = try await httpClient.request(
            updateEndpoint,
            accessToken: accessToken
        )

        // 4. 응답 → FoodRecord 변환
        guard let record = response.toFoodRecord() else {
            throw FoodRecordError.emptyResponse
        }

        return record
    }

    public func deleteRecord(id: String) async throws {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        guard let diaryId = Int(id) else {
            throw FoodRecordError.emptyResponse
        }

        let endpoint = DiaryEndpoint.delete(diaryId: diaryId)
        try await httpClient.requestVoid(endpoint, accessToken: accessToken)
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

    private func convertAssetsToFiles(_ assets: [any ImageAssetable]) async throws -> [File] {
        try await withThrowingTaskGroup(of: (Int, File).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask {
                    guard let phAsset = asset as? PHAsset else {
                        throw FoodRecordError.imageConversionFailed
                    }
                    let data = try await imageConverter.convertToJPEGData(
                        from: phAsset,
                        targetSize: CGSize(width: 1200, height: 1200)
                    )
                    return (index, File(
                        fileName: "photo_\(index).jpg",
                        mimeType: "image/jpeg",
                        data: data
                    ))
                }
            }

            var results: [(Int, File)] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
        }
    }

    private func convertToRecordsByDate(_ response: DiariesResponseDTO) -> [Date: [FoodRecord]] {
        var result: [Date: [FoodRecord]] = [:]

        for dto in response.diaries {
            guard let record = dto.toFoodRecord() else { continue }
            let startOfDay = calendar.startOfDay(for: record.date)
            result[startOfDay, default: []].append(record)
        }

        return result
    }

    private func postFakeAnalysisNotification(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)

        NotificationCenter.default.post(
            name: AppNotification.Push.analysisResult,
            object: nil,
            userInfo: [
                AppNotification.Push.Key.type: "analysis_complete",
                AppNotification.Push.Key.diaryDate: dateString,
            ]
        )
    }
}
