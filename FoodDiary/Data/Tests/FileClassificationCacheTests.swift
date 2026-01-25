//
//  FileClassificationCacheTests.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

@testable import Data
import Foundation
import Testing

@Suite("FileClassificationCache Tests")
struct FileClassificationCacheTests {
    private let testFileName = "test_classification_cache.json"

    private func createCache() -> FileClassificationCache {
        // 테스트 전 기존 파일 삭제
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cacheDir.appendingPathComponent(testFileName)
        try? FileManager.default.removeItem(at: fileURL)

        return FileClassificationCache(fileName: testFileName)
    }

    private func cleanUp() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cacheDir.appendingPathComponent(testFileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - get/set 테스트

    @Test("캐시에 없는 identifier는 nil 반환")
    func testGetReturnsNilForMissingEntry() {
        let cache = createCache()
        defer { cleanUp() }

        let result = cache.get("non-existent-id")

        #expect(result == nil)
    }

    @Test("set한 값을 get으로 조회")
    func testSetAndGet() {
        let cache = createCache()
        defer { cleanUp() }

        let entry = ClassificationCacheEntry(identifier: "test-id", foodProbability: 0.85)
        cache.set(entry)

        let result = cache.get("test-id")

        #expect(result != nil)
        #expect(result?.identifier == "test-id")
        #expect(result?.foodProbability == 0.85)
    }

    @Test("여러 항목 저장 및 조회")
    func testMultipleEntries() {
        let cache = createCache()
        defer { cleanUp() }

        let entry1 = ClassificationCacheEntry(identifier: "id-1", foodProbability: 0.9)
        let entry2 = ClassificationCacheEntry(identifier: "id-2", foodProbability: 0.3)
        let entry3 = ClassificationCacheEntry(identifier: "id-3", foodProbability: 0.7)

        cache.set(entry1)
        cache.set(entry2)
        cache.set(entry3)

        #expect(cache.get("id-1")?.foodProbability == 0.9)
        #expect(cache.get("id-2")?.foodProbability == 0.3)
        #expect(cache.get("id-3")?.foodProbability == 0.7)
    }

    @Test("같은 identifier로 set하면 덮어쓰기")
    func testOverwrite() {
        let cache = createCache()
        defer { cleanUp() }

        let entry1 = ClassificationCacheEntry(identifier: "test-id", foodProbability: 0.5)
        let entry2 = ClassificationCacheEntry(identifier: "test-id", foodProbability: 0.9)

        cache.set(entry1)
        cache.set(entry2)

        let result = cache.get("test-id")
        #expect(result?.foodProbability == 0.9)
    }

    // MARK: - 디스크 영속성 테스트

    @Test("캐시가 디스크에 저장되고 새 인스턴스에서 복원")
    func testPersistence() {
        defer { cleanUp() }

        // 첫 번째 인스턴스에서 저장
        let cache1 = createCache()
        let entry = ClassificationCacheEntry(identifier: "persist-id", foodProbability: 0.75)
        cache1.set(entry)

        // 새 인스턴스 생성 (디스크에서 로드)
        let cache2 = FileClassificationCache(fileName: testFileName)

        let result = cache2.get("persist-id")
        #expect(result != nil)
        #expect(result?.foodProbability == 0.75)
    }
}
