//
//  ClassificationCacheManager.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

import Foundation

/// 파일 기반 음식 분류 결과 캐시
public final class ClassificationCacheManager: @unchecked Sendable {
    private var cache: [String: ClassificationCacheEntry] = [:]
    private let lock = UnfairLock()
    private let fileURL: URL

    private var saveTask: Task<Void, Never>?
    private let debounceInterval: Duration

    public init(
        fileName: String = "classification_cache.json",
        debounceInterval: Duration = .seconds(0.5)
    ) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = cacheDir.appendingPathComponent(fileName)
        self.debounceInterval = debounceInterval

        self.cache = loadFromDisk()
    }

    public func get(_ identifier: String) -> ClassificationCacheEntry? {
        lock.withLock {
            cache[identifier]
        }
    }

    public func set(_ entry: ClassificationCacheEntry) {
        lock.withLock {
            cache[entry.assetIdentifier] = entry
        }
        scheduleSave()
    }

    // MARK: - Private

    /// Disk I/O 디바운스
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else {
                return
            }

            try? await Task.sleep(for: self.debounceInterval)
            guard !Task.isCancelled else {
                return
            }

            let snapshot = lock.withLock { self.cache }
            saveToDisk(snapshot)
        }
    }

    private func loadFromDisk() -> [String: ClassificationCacheEntry] {
        guard let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(
                [String: ClassificationCacheEntry].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    private func saveToDisk(_ data: [String: ClassificationCacheEntry]) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }
}
