//
//  FileStorageServicing.swift
//  Data
//

import Foundation

/// 파일 시스템 I/O 추상화 프로토콜
public protocol FileStorageServicing: Sendable {
    /// 지정된 파일명으로 데이터 저장
    /// - Parameters:
    ///   - data: 저장할 데이터
    ///   - fileName: 저장할 파일명
    /// - Returns: 저장 성공 여부
    func save(data: Data, fileName: String) -> Bool

    /// 지정된 파일명에서 데이터 로드
    /// - Parameter fileName: 로드할 파일명
    /// - Returns: 로드된 데이터 (파일이 없거나 실패 시 nil)
    func load(fileName: String) -> Data?

    /// 지정된 파일 삭제
    /// - Parameter fileName: 삭제할 파일명
    /// - Returns: 삭제 성공 여부
    func delete(fileName: String) -> Bool
}
