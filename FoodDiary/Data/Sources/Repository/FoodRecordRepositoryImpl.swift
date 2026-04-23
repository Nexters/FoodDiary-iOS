//
//  FoodRecordRepositoryImpl.swift
//  Data
//

import Domain
import Foundation
import Photos
import UIKit

/// FoodRecordRepository 구현체
public struct FoodRecordRepositoryImpl: FoodRecordRepository {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring
    private let deviceId: String
    private let imageConverter: PHAssetConverter
    private let calendar = Calendar.current
    private let photoURLCache = PhotoURLCache()

    #if DEBUG
        let testMode: Bool = true
    #else
        let testMode = false
    #endif

    public init(
        httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring, deviceId: String,
        imageConverter: PHAssetConverter
    ) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
        self.deviceId = deviceId
        self.imageConverter = imageConverter
    }

    // MARK: - 서버 API 호출

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> [UploadResult] {
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

        guard !response.diaries.isEmpty else {
            throw FoodRecordError.emptyResponse
        }

        return response.diaries.map { diary in
            UploadResult(
                uploadId: String(diary.diaryId),
                mealType: MealType.from(serverValue: diary.timeType)
            )
        }
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

    public func fetchPhotoURLs(in dateRange: ClosedRange<Date>) -> AsyncThrowingStream<[Date: [URL]], Error> {
        AsyncThrowingStream { continuation in
            Task {
                // 1. 캐시 HIT 시 즉시 방출
                if let cached = await photoURLCache.get(for: dateRange) {
                    continuation.yield(cached)
                }

                // 2. 항상 서버 검증
                do {
                    guard let accessToken = tokenStorage.get() else {
                        throw FoodRecordError.noAccessToken
                    }

                    let endpoint = DiaryEndpoint.byDateRangeSummary(
                        startDate: formatDate(dateRange.lowerBound),
                        endDate: formatDate(dateRange.upperBound),
                        testMode: testMode
                    )

                    let response: DiariesByDateRangeSummaryResponseDTO = try await httpClient.request(
                        endpoint,
                        accessToken: accessToken
                    )

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"

                    let fresh = response.reduce(into: [Date: [URL]]()) { result, entry in
                        guard let date = formatter.date(from: entry.key) else { return }
                        result[date] = entry.value.photos.compactMap { URL(string: $0.url) }
                    }

                    let current = await photoURLCache.get(for: dateRange)
                    if current != fresh {
                        await photoURLCache.set(fresh, for: dateRange)
                        continuation.yield(fresh)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
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
        try await httpClient.request(endpoint, accessToken: accessToken)
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
                    return (
                        index,
                        File(
                            fileName: "photo_\(index).jpg",
                            mimeType: "image/jpeg",
                            data: data
                        )
                    )
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
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
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
