//
//  FileStorageServiceTests.swift
//  DataTests
//

import Foundation
import Testing

@testable import Data

struct FileStorageServiceTests {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    let sut: FileStorageService

    init() {
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        sut = FileStorageService(directoryURL: tempDir)
    }

    @Test("데이터 저장 후 로드하면 동일한 데이터를 반환한다")
    func saveAndLoad_returnsOriginalData() {
        let testData = "test content".data(using: .utf8)!

        let saveResult = sut.save(data: testData, fileName: "test.json")
        let loadedData = sut.load(fileName: "test.json")

        #expect(saveResult == true)
        #expect(loadedData == testData)

        _ = sut.delete(fileName: "test.json")
    }

    @Test("존재하지 않는 파일 로드 시 nil을 반환한다")
    func load_nonExistentFile_returnsNil() {
        let result = sut.load(fileName: "non_existent.json")

        #expect(result == nil)
    }

    @Test("파일 삭제 후 load가 nil을 반환한다")
    func delete_existingFile_removesFile() {
        let testData = "test".data(using: .utf8)!
        _ = sut.save(data: testData, fileName: "delete_test.json")

        let deleteResult = sut.delete(fileName: "delete_test.json")
        let loadedData = sut.load(fileName: "delete_test.json")

        #expect(deleteResult == true)
        #expect(loadedData == nil)
    }

    @Test("존재하지 않는 파일 삭제도 성공으로 처리한다")
    func delete_nonExistentFile_returnsTrue() {
        let result = sut.delete(fileName: "non_existent.json")

        #expect(result == true)
    }
}
