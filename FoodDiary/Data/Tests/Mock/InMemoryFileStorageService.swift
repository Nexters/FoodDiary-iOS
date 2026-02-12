//
//  InMemoryFileStorageService.swift
//  Data
//

@testable import Data
import Foundation

/// 테스트용 인메모리 파일 저장소
final class InMemoryFileStorageService: FileStorageServicing, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    var shouldSaveSucceed: Bool = true
    var shouldLoadSucceed: Bool = true
    var shouldDeleteSucceed: Bool = true

    func save(data: Data, fileName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard shouldSaveSucceed else { return false }
        storage[fileName] = data
        return true
    }

    func load(fileName: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        guard shouldLoadSucceed else { return nil }
        return storage[fileName]
    }

    func delete(fileName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard shouldDeleteSucceed else { return false }
        storage.removeValue(forKey: fileName)
        return true
    }

    // MARK: - Test Helpers

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    func storedFileNames() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(storage.keys)
    }
}
