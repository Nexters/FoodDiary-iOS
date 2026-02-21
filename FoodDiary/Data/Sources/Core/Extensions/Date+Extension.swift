//
//  Date+Extension.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Foundation

extension Date {
    /// "yyyy-MM-dd" 형식의 API 날짜 문자열 (예: "2026-02-01")
    var apiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
