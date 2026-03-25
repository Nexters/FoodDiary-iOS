//
//  PhotoURLCache.swift
//  Data
//

import Foundation

actor PhotoURLCache {
    private var entries: [(key: String, value: [Date: [URL]])] = []
    private let capacity = 12

    func get(for dateRange: ClosedRange<Date>) -> [Date: [URL]]? {
        let k = cacheKey(for: dateRange)
        guard let index = entries.firstIndex(where: { $0.key == k }) else { return nil }
        let entry = entries.remove(at: index)
        entries.insert(entry, at: 0)
        return entry.value
    }

    func set(_ value: [Date: [URL]], for dateRange: ClosedRange<Date>) {
        let k = cacheKey(for: dateRange)
        entries.removeAll { $0.key == k }
        entries.insert((key: k, value: value), at: 0)
        if entries.count > capacity {
            entries.removeLast()
        }
    }

    func remove(for dateRange: ClosedRange<Date>) {
        let k = cacheKey(for: dateRange)
        entries.removeAll { $0.key == k }
    }

    private func cacheKey(for dateRange: ClosedRange<Date>) -> String {
        "\(Int(dateRange.lowerBound.timeIntervalSince1970))-\(Int(dateRange.upperBound.timeIntervalSince1970))"
    }
}
