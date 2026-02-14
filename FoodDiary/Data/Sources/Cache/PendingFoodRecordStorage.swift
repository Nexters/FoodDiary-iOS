//
//  PendingFoodRecordStorage.swift
//  Data
//

import Domain
import Foundation
import UIKit

/// Pending 기록 로컬 저장소 (Actor + JSON 파일)
///
/// 엄청 많이 쌓이면 어떡하죠?
///     -> Pending 기록은 서버 업로드 완료 후 AI 분석 대기 중인 기록이므로
///      분석이 완료되면 바로 삭제되니까 엄청 쌓이진 않을 거임
public actor PendingFoodRecordStorage<Storage: FileStorageServicing>: PendingFoodRecordRepository {
    private var records: [String: PendingFoodRecord] = [:]  // uploadId 기준
    private let fileName: String
    private let fileStorage: Storage

    private var saveTask: Task<Void, Never>?
    private var backgroundObserverTask: Task<Void, Never>?
    private let debounceInterval: Duration

    public init(
        fileStorage: Storage,
        fileName: String = "pending_records.json",
        debounceInterval: Duration = .seconds(0.2)
    ) {
        self.fileStorage = fileStorage
        self.fileName = fileName
        self.debounceInterval = debounceInterval
        self.records = Self.loadFromDisk(fileStorage: fileStorage, fileName: fileName)

        backgroundObserverTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: UIScene.didEnterBackgroundNotification)
            {
                await self?.flushToDisk()
            }
        }
    }

    // MARK: - PendingFoodRecordRepository

    public func fetchAll() throws -> [PendingFoodRecord] {
        Array(records.values)
    }

    public func save(_ record: PendingFoodRecord) throws {
        records[record.uploadId] = record
        scheduleSave()
    }

    public func delete(byUploadIds uploadIds: [String]) throws {
        for uploadId in uploadIds {
            records.removeValue(forKey: uploadId)
        }
        scheduleSave()
    }

    // MARK: - Private

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task(priority: .utility) {
            try? await Task.sleep(for: self.debounceInterval)
            guard !Task.isCancelled else { return }
            self.saveToDisk(records: self.records)
        }
    }

    private func saveToDisk(records: [String: PendingFoodRecord]) {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        _ = fileStorage.save(data: encoded, fileName: fileName)
    }

    private func flushToDisk() {
        saveTask?.cancel()
        saveToDisk(records: records)
    }

    private static func loadFromDisk(
        fileStorage: Storage,
        fileName: String
    ) -> [String: PendingFoodRecord] {
        guard let data = fileStorage.load(fileName: fileName),
            let decoded = try? JSONDecoder().decode([String: PendingFoodRecord].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    deinit {
        saveTask?.cancel()
        backgroundObserverTask?.cancel()
    }
}
