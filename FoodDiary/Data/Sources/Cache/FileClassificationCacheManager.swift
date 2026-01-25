//
//  FileClassificationCache.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

import Foundation

/// 파일 기반 음식 분류 결과 캐시
public final class FileClassificationCacheManager: ClassificationCacheManagable, @unchecked Sendable {
    private var cache: [String: ClassificationCacheEntry] = [:]
    private let lock = UnfairLock()
    private let fileURL: URL

    public init(fileName: String = "classification_cache.json") {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = cacheDir.appendingPathComponent(fileName)
        self.cache = loadFromDisk()
    }

    public func get(_ identifier: String) -> ClassificationCacheEntry? {
        lock.lock()
        defer { lock.unlock() }
        return cache[identifier]
    }

    public func set(_ entry: ClassificationCacheEntry) {
        lock.lock()
        cache[entry.identifier] = entry
        let snapshot = cache
        lock.unlock()

        saveToDisk(snapshot)
    }

    private func loadFromDisk() -> [String: ClassificationCacheEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: ClassificationCacheEntry].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveToDisk(_ data: [String: ClassificationCacheEntry]) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }
}
