//
//  PendingFoodRecordStorage.swift
//  Data
//

import Domain
import Foundation

/// Pending 기록 로컬 저장소 (Actor + JSON 파일)
/// 
/// 엄청 많이 쌓이면 어떡하죠? 
///     -> Pending 기록은 서버 업로드 완료 후 AI 분석 대기 중인 기록이므로
///      분석이 완료되면 바로 삭제되니까 엄청 쌓이진 않을 거임
public actor PendingFoodRecordStorage: PendingFoodRecordRepository {
    private var records: [String: PendingFoodRecord] = [:]  // uploadId 기준
    private let fileURL: URL

    private var saveTask: Task<Void, Never>?
    private let debounceInterval: Duration

    public init(
        fileName: String = "pending_records.json",
        debounceInterval: Duration = .seconds(0.5)
    ) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDir.appendingPathComponent(fileName)

        self.fileURL = fileURL
        self.debounceInterval = debounceInterval
        self.records = Self.loadFromDisk(fileURL: fileURL)
    }

    // MARK: - PendingFoodRecordRepository

    public func fetchAll() throws -> [PendingFoodRecord] {
        Array(records.values)
    }

    public func save(_ record: PendingFoodRecord) throws {
        records[record.uploadId] = record
        scheduleSave()
    }

    public func delete(byUploadId uploadId: String) throws {
        records.removeValue(forKey: uploadId)
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
            saveToDisk(records: self.records, to: self.fileURL)
        }
    }

    private func saveToDisk(records: [String: PendingFoodRecord], to fileURL: URL) {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    private static func loadFromDisk(fileURL: URL) -> [String: PendingFoodRecord] {
        guard let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([String: PendingFoodRecord].self, from: data)
        else {
            return [:]
        }
        return decoded
    }
}
