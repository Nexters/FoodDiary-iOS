//
//  MumukColor.swift
//  DesignSystem
//

import UIKit

/// 뭐먹었지 앱의 색상 토큰
public enum MumukColor {
    // MARK: - Primary Colors

    /// 기본 강조 색상 (주황색)
    public static let primary = UIColor(hex: "#FF6B35")

    // MARK: - Background Colors

    /// 기본 배경 색상
    public static let background = UIColor.systemBackground

    /// 보조 배경 색상 (카드, 셀 등)
    public static let surface = UIColor.secondarySystemBackground

    // MARK: - Text Colors

    /// 기본 텍스트 색상
    public static let textPrimary = UIColor.label

    /// 보조 텍스트 색상
    public static let textSecondary = UIColor.secondaryLabel

    // MARK: - State Colors

    /// 비활성화 상태 색상
    public static let disabled = UIColor.systemGray3

    /// 체크마크 미선택 배경
    public static let checkmarkUnselected = UIColor(white: 0.3, alpha: 0.6)
}
