//
//  ClassificationCacheManagable.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

/// 음식 분류 결과를 캐싱하기 위한 프로토콜
public protocol ClassificationCacheManagable: Sendable {
    func get(_ identifier: String) -> ClassificationCacheEntry?
    func set(_ entry: ClassificationCacheEntry)
}
