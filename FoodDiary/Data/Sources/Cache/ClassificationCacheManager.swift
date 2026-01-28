//
//  ClassificationCacheManager.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

import Foundation

/// 파일 기반 음식 분류 결과 캐시
public actor ClassificationCacheManager {
    private var cache: [String: ClassificationCacheEntry] = [:]
    private let fileURL: URL

    private var saveTask: Task<Void, Never>?
    private let debounceInterval: Duration

    public init(
        fileName: String = "classification_cache.json",
        debounceInterval: Duration = .seconds(0.5)
    ) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cacheDir.appendingPathComponent(fileName)

        self.fileURL = fileURL
        self.debounceInterval = debounceInterval
        self.cache = Self.loadFromDisk(fileURL: fileURL)
    }

    public func get(_ identifier: String) -> ClassificationCacheEntry? {
        cache[identifier]
    }

    public func set(_ entry: ClassificationCacheEntry) {
        cache[entry.assetIdentifier] = entry
        scheduleSave()
    }

    // MARK: - Private

    /// Disk I/O 디바운스
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: self.debounceInterval)
            guard !Task.isCancelled else { return }

            await self.saveToDisk(cache: self.cache, to: self.fileURL)
        }
    }

    private func saveToDisk(cache: [String: ClassificationCacheEntry], to fileURL: URL) {
        guard let encoded = try? JSONEncoder().encode(cache) else { return }
        try? encoded.write(to: fileURL, options: .atomic)
    }

    private static func loadFromDisk(fileURL: URL) -> [String: ClassificationCacheEntry] {
        guard let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(
                [String: ClassificationCacheEntry].self, from: data)
        else {
            return [:]
        }
        return decoded
    }
}
