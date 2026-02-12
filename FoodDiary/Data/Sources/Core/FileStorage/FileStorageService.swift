//
//  FileStorageService.swift
//  Data
//

import Foundation

/// FileManager 기반 파일 저장소 구현
public struct FileStorageService: FileStorageServicing {
    private let directoryURL: URL

    public init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public func save(data: Data, fileName: String) -> Bool {
        let url = directoryURL.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public func load(fileName: String) -> Data? {
        let url = directoryURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    public func delete(fileName: String) -> Bool {
        let url = directoryURL.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch CocoaError.fileNoSuchFile { // 파일이 없는 경우도 성공으로 간주
            return true
        } catch {
            return false
        }
    }
}
