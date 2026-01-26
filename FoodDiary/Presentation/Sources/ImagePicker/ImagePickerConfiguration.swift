//
//  ImagePickerConfiguration.swift
//  Presentation
//

import UIKit
import DesignSystem

/// 이미지 피커 설정
public struct ImagePickerConfiguration: Sendable {
    // MARK: - Color Properties

    /// 선택 테두리 및 버튼 배경 색상
    public let primaryColor: UIColor

    /// 버튼 텍스트 색상
    public let buttonTextColor: UIColor

    /// 버튼 비활성화 색상
    public let buttonDisabledColor: UIColor

    // MARK: - Picker Properties

    /// 최대 선택 가능 수 (nil이면 무제한)
    public let maxSelectionCount: Int?

    /// 확인 버튼 타이틀
    public let confirmButtonTitle: String

    /// 기본 설정
    public static let `default` = ImagePickerConfiguration(
        primaryColor: DesignSystemAsset.primary.color,
        buttonTextColor: .white,
        buttonDisabledColor: DesignSystemAsset.disabled.color,
        maxSelectionCount: nil,
        confirmButtonTitle: "추가하기"
    )

    public init(
        primaryColor: UIColor,
        buttonTextColor: UIColor,
        buttonDisabledColor: UIColor,
        maxSelectionCount: Int?,
        confirmButtonTitle: String
    ) {
        self.primaryColor = primaryColor
        self.buttonTextColor = buttonTextColor
        self.buttonDisabledColor = buttonDisabledColor
        self.maxSelectionCount = maxSelectionCount
        self.confirmButtonTitle = confirmButtonTitle
    }
}
